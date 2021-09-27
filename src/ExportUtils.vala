/*
* Copyright (c) 2020 (https://github.com/phase1geo/Outliner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

public class ExportUtils {

  public delegate string ExportStartFunc( FormatTag tag, int start, string? extra );
  public delegate string ExportEndFunc( FormatTag tag, int start, string? extra );
  public delegate string ExportEncodeFunc( string str );

  /* Used by the export function */
  public class PosTag {
    public FormatTag tag   { private set; get; }
    public int       pos   { private set; get; }
    public bool      begin { private set; get; }
    public string?   extra { private set; get; }
    public PosTag.start( FormatTag tag, int pos, string? extra ) {
      this.tag   = tag;
      this.pos   = pos;
      this.begin = true;
      this.extra = extra;
    }
    public PosTag.end( FormatTag tag, int pos, string? extra ) {
      this.tag   = tag;
      this.pos   = pos;
      this.begin = false;
      this.extra = extra;
    }
    public string to_string() {
      return( "(%s %s, %d, %s)".printf( tag.to_string(), (begin ? "start" : "end"), pos, extra ) );
    }
  }

  public class TagTreeItem {
    public UndoTagInfo?       info;
    public TagTreeItem?       parent;
    public Array<TagTreeItem> children;
    public TagTreeItem( UndoTagInfo? info, TagTreeItem? parent = null ) {
      this.info     = info;
      this.parent   = parent;
      this.children = new Array<TagTreeItem>();
    }
    private bool is_within( UndoTagInfo item ) {
      return( (info.start <= item.start) && (item.end <= info.end) );
    }
    private bool reparent( UndoTagInfo item ) {
      return( (item.start <= info.start) && (info.end <= item.end) );
    }
    private bool less_than( UndoTagInfo item ) {
      return( item.end < info.start );
    }
    public void insert( UndoTagInfo item ) {
      for( int i=0; i<children.length; i++ ) {
        var child = children.index( i );
        if( child.is_within( item ) ) {
          child.insert( item );
          return;
        } else if( child.reparent( item ) ) {
          var tti = new TagTreeItem( item, this );
          children.data[i] = tti;
          tti.children.append_val( child );
          child.parent = tti;
          while( ((i + 1) < children.length) && tti.is_within( children.index( i + 1 ).info ) ) {
            tti.children.append_val( children.index( i + 1 ) );
            children.index( i + 1 ).parent = tti;
            children.remove_index( i + 1 );
          }
          return;
        } else if( child.less_than( item ) ) {
          children.insert_val( i, new TagTreeItem( item, this ) );
          return;
        }
      }
      children.append_val( new TagTreeItem( item, this ) );
    }
    public void get_array( ref Array<PosTag> tags ) {
      for( int i=0; i<children.length; i++ ) {
        var child = children.index( i );
        var info  = child.info;
        tags.append_val( new PosTag.start( (FormatTag)info.tag, info.start, info.extra ) );
        child.get_array( ref tags );
        tags.append_val( new PosTag.end( (FormatTag)info.tag, info.end, info.extra ) );
      }
    }
  }

  private static bool tags_match( PosTag? first, PosTag? second ) {
    return( (first == null) || (second == null) || (first.tag != second.tag) || (first.pos != second.pos) || (first.extra != second.extra) );
  }

  /* Exports the given FormattedText using markup or markdown */
  public static string export( FormattedText text, ExportStartFunc start_func, ExportEndFunc end_func, ExportEncodeFunc encode_func ) {

    /* Create the tree version and create an ordered list of tags */
    var tags     = text.get_tags_in_range( 0, text.text.length );
    var root     = new TagTreeItem( null, null );
    var pos_tags = new Array<PosTag>();
    for( int i=0; i<tags.length; i++ ) {
      root.insert( tags.index( i ) );
    }
    root.get_array( ref pos_tags );

    /* Output the text */
    var str   = "";
    var start = 0;
    for( int i=0; i<pos_tags.length; i++ ) {
      var pos_tag = pos_tags.index( i );
      str += encode_func( text.text.slice( start, pos_tag.pos ) );
      if( pos_tag.begin ) {
        if( tags_match( ((i == 0) ? null : pos_tags.index( i - 1 )), pos_tag ) ) {
          str += start_func( pos_tag.tag, pos_tag.pos, pos_tag.extra );
        }
      } else if( tags_match( pos_tag, (((i + 1) == pos_tags.length) ? null : pos_tags.index( i + 1 )) ) ) {
        str += end_func( pos_tag.tag, pos_tag.pos, pos_tag.extra );
      }
      start = pos_tag.pos;
    }

    str += encode_func( text.text.slice( start, text.text.length ) );

    return( str );

  }

}
