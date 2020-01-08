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

public class UndoNodeMove : UndoItem {

  private Node _node;
  private Node? _orig_parent;
  private int   _orig_index;
  private Node? _parent;
  private int   _index;

  /* Default constructor */
  public UndoNodeMove( Node node, Node? orig_parent, int orig_index ) {
    base( _( "move item" ) );
    _node        = node;
    _parent      = node.parent;
    _index       = node.index();
    _orig_parent = orig_parent;
    _orig_index  = orig_index;
  }

  private void move( OutlineTable table, Node? parent, int index ) {
    parent.add_child( _node, index );
    table.selected = _node;
    table.queue_draw();
    table.changed();
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    move( table, _orig_parent, _orig_index );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    move( table, _parent, _index );
  }

}
