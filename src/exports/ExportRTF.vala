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

using GLib;
using Gtk;

public class ExportRTF : Export {

  /* Constructor */
  public ExportRTF() {
    base( "rtf", _( "RTF" ), {".rtf"}, true, false, false );
  }

  /* Add settings for Org Mode */
  public override void add_settings( Grid grid ) {
    add_setting_bool( "use-ul", grid, _( "Use unordered lists" ), _( "Export using unordered lists" ), true );
  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {
    var value = get_bool( "use-ul" );
    node->set_prop( "use-ul", value.to_string() );
  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {
    var q = node->get_prop( "use-ul" );
    if( q != null ) {
      var value = bool.parse( q );
      set_bool( "use-ul", value );
    }
  }

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, OutlineTable table ) {
    var file = File.new_for_path( fname );
    try {
      var os = file.create( FileCreateFlags.PRIVATE );
      export_main( os, table );
    } catch( Error e ) {
      return( false );
    }
    return( true );
  }

  private void export_main( FileOutputStream os, OutlineTable table ) {
    try {
      os.write( "{\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard ".data );
      for( int i=0; i<table.root.children.length; i++ ) {
        export_node( os, table.root.children.index( i ) );
      }
      os.write( "}".data );
    } catch( Error e ) {}
  }

  public string from_text( FormattedText text ) {
    ExportUtils.ExportStartFunc start_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :  return( "\\b" );
        case FormatTag.ITALICS    :  return( "\\i" );
        case FormatTag.UNDERLINE  :  return( "\\ul" );
        case FormatTag.STRIKETHRU :  return( "\\strike" );
        case FormatTag.HEADER     :
          if( start == 0 ) {
            switch( extra ) {
              case "1" :  return( "\\b\\fs40" );
              case "2" :  return( "\\b\\fs34" );
              case "3" :  return( "\\b\\fs29" );
              case "4" :  return( "\\b\\fs25" );
              case "5" :  return( "\\b\\fs23" );
              case "6" :  return( "\\b\\fs21" );
              default  :  return( "\\b\\fs21" );
            }
          }
          break;
        case FormatTag.COLOR      :  return( "\\cf4" );
        case FormatTag.HILITE     :  return( "\\highlight7" );
        case FormatTag.URL        :  return( "\\cs1\\ul\\cf2" );
        default                   :  return( "" );
      }
      return( "" );
    };
    ExportUtils.ExportEndFunc end_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :
        case FormatTag.ITALICS    :
        case FormatTag.UNDERLINE  :
        case FormatTag.STRIKETHRU :
        case FormatTag.HEADER     :
        case FormatTag.COLOR      :
        case FormatTag.HILITE     :
        case FormatTag.URL        :
          return( ";}" );
        default                   :
          return( "" );
      }
    };
    ExportUtils.ExportEncodeFunc encode_func = (str) => {
      return( str );
      // return( str.replace( @"\", @"\\" ).replace( "{", @"\{" ).replace( "}", @"\}" );
    };
    return( ExportUtils.export( text, start_func, end_func, encode_func ) );
  }

  /* Traverses the node tree exporting XML nodes in OPML format */
  private void export_node( FileOutputStream os, Node node ) {
    if( node.children.length > 0 ) {
      for( int i=0; i<node.children.length; i++ ) {
        export_node( os, node.children.index( i ) );
      }
    }
  }

  /*
  private Xml.Node* export_node( FileOutputStream os, Node node ) {
    string    ul_syms[3] = {"disc", "circle", "square"};
    string    ol_syms[5] = {"I", "A", "1", "a", "i"};
    Xml.Node* li         = new Xml.Node( null, "li" );
    li->add_child( make_div( "text", node.name.text ) );
    if( node.note.text.text != "" ) {
      li->add_child( make_div( "note", node.note.text ) );
    }
    if( node.children.length > 0 ) {
      var       use_ul = get_bool( "use-ul" );
      Xml.Node* list   = new Xml.Node( null, (use_ul ? "ul" : "ol") );
      if( use_ul ) {
        int sym_index = node.depth % 3;
        list->set_prop( "style", "list-style-type:%s".printf( ul_syms[sym_index] ) );
      } else {
        int sym_index = (node.depth >= 5) ? (((node.depth - 5) % 2) + 3) : (node.depth % 5);
        list->set_prop( "type", ol_syms[sym_index] );
      }
      li->add_child( list );
      for( int i=0; i<node.children.length; i++ ) {
        list->add_child( export_node( os, node.children.index( i ) ) );
      }
    }
    return( li );
  }
  */

}
