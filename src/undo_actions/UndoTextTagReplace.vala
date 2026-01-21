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

public class UndoTextTagReplace : UndoTextItem {

  public int                start { private set; get; }
  public int                end   { private set; get; }
  public FormatTag          tag   { private set; get; }
  public string?            extra { private set; get; }
  public Array<UndoTagInfo> removed_tags { private set; get; }

  //-------------------------------------------------------------
  // Default constructor
  public UndoTextTagReplace( int start, int end, FormatTag tag, string? extra, Array<UndoTagInfo> removed_tags, int cursor ) {
    base( _( "format tag replace" ), UndoTextOp.TAGREPLACE, cursor, cursor );
    this.start = start;
    this.end   = end;
    this.tag   = tag;
    this.extra = extra;
    this.removed_tags = removed_tags;
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo_text( OutlineTable table, CanvasText ct ) {
    ct.text.remove_tag( tag, start, end );
    for( int i=0; i<removed_tags.length; i++ ) {
      var tag = removed_tags.index( i );
      ct.text.add_tag( tag.tag, tag.start, tag.end, tag.extra );
    }
    ct.set_cursor_only( start_cursor );
    table.queue_draw();
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo_text( OutlineTable table, CanvasText ct ) {
    ct.text.remove_tag( tag, start, end );
    ct.text.add_tag( tag, start, end, extra );
    ct.set_cursor_only( end_cursor );
    table.queue_draw();
  }

  //-------------------------------------------------------------
  // Merges the given item with the current one
  public override bool merge( CanvasText ct, UndoTextItem item ) {
    return( false );
  }

}
