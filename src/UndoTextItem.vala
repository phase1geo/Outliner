/*
* Copyright (c) 2018 (https://github.com/phase1geo/Outliner)
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

public enum UndoTextOp {
  INSERT = 0,
  DELETE,
  REPLACE
}

/*
 Represents a single text undo item in the text undo buffer.
*/
public class UndoTextItem : UndoItem {

  protected UndoTextOp op     { private set; get; }
  protected int        cursor { private set; get; }

  /* Default constructor */
  public UndoTextItem( string name, UndoTextOp op, int cursor ) {
    base( name );
    this.op     = op;
    this.cursor = cursor;
  }

  /*
   Merges the given item into this item, if possible and returns true to indicate
   that the merge occurred.
  */
  public virtual bool merge( CanvasText ct, UndoTextItem item ) {
    return( false );
  }

  /* Performs an undo of the text item */
  public virtual void undo_text( OutlineTable table, CanvasText ct ) {}

  /* Performs a redo of the text item */
  public virtual void redo_text( OutlineTable table, CanvasText ct ) {}

}
