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

public class UndoTextInsert : UndoItem {

  private CanvasText _ct;
  private string     _text;
  private int        _start;
  private int        _orig_cursor;
  private int        _new_cursor;

  /* Default constructor */
  public UndoTextInsert( CanvasText ct, string text, int start, int orig_cursor ) {
    base( _( "text insertion" ) );
    _ct          = ct;
    _text        = text;
    _start       = start;
    _orig_cursor = orig_cursor;
    _new_cursor  = _ct.cursor;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    _ct.text.remove_text( _start, _text.length );
    _ct.cursor = _orig_cursor;
    table.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    _ct.text.insert_text( _start, _text );
    _ct.cursor = _new_cursor;
    table.queue_draw();
  }

}
