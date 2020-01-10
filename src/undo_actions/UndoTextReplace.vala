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

public class UndoTextReplace : UndoTextItem {

  public string orig_text   { private set; get; }
  public string new_text    { private set; get; }
  public int    start       { private set; get; }
  public int    orig_cursor { private set; get; }

  /* Default constructor */
  public UndoTextReplace( CanvasText ct, string orig_text, string new_text, int start, int orig_cursor ) {
    base( _( "text replacement", ct, UndoTextOp.REPLACE ) );
    this.orig_text   = orig_text;
    this.new_text    = new_text;
    this.start       = start;
    this.orig_cursor = orig_cursor;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    ct.text.replace_text( _start, _new_text.length, _orig_text );
    ct.cursor = _orig_cursor;
    table.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    ct.text.replace_text( _start, _orig_text.length, _new_text );
    ct.cursor = cursor;
    table.queue_draw();
  }

  public override bool merge( UndoTextItem item ) {
    if( item.op == UndoTextOp.INSERT ) {
      var insert_item = item as UndoTextInsert;
      // TBD
    }
  }

}
