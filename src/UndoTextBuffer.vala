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

public class UndoTextBuffer : UndoBuffer {

  private enum UndoTextOp {
    INSERT = 0,
    DELETE,
    REPLACE
  }

  private class UndoTextItem : UndoItem {
    public UndoTextItem( UndoTextOp op, int cursor ) {
      _op     = op;
      _cursor = cursor;
    }
  }

  private CanvasText _ct;

  /* Default constructor */
  public UndoTextBuffer( OutlineTable table, CanvasText ct ) {
    base( table );
    _ct = ct;
  }

  /*
   Checks to see if the given item is mergeable with the last item in the buffer.
   If it is mergeable, merge it and return true; otherwise, return false.
  */
  private bool merge_with_last( UndoTextItem item ) {
    if( (_undo_buffer.length > 0) && (_redo_buffer.length == 0) ) {
      return( _undo_buffer.index( _undo_buffer.length - 1 ).merge( item ) );
    }
    return( false );
  }

  /* Call after text has been inserted */
  public void add_insert( int start, string text, int orig_cursor ) {
    var item = new UndoTextInsert( _ct, text, start, cursor );
    if( !merge_with_last( item ) ) {
      add_item( item );
    }
  }

  /* Call after text has been deleted */
  public void add_delete( int start, string orig_text, int orig_cursor ) {
    var item = new UndoTextDelete( _ct, orig_text, start, orig_cursor );
    if( !merge_with_last( item ) ) {
      add_item( item );
    }
  }

  /* Call after text has been replaced */
  public void add_replace( int start, string orig_text, string text, int orig_cursor ) {
    var item = new UndoTextReplace( _ct, orig_text, text, start, orig_cursor );
    if( !merge_with_last( item ) ) {
      add_item( item );
    }
  }

}
