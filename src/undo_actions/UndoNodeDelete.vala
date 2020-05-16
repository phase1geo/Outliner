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

public class UndoNodeDelete : UndoItem {

  private Node  _node;
  private Node? _parent;
  private int   _index;
  private Node? _insert_node;

  /* Default constructor */
  public UndoNodeDelete( Node node, Node? insert_node ) {
    base( _( "delete item" ) );
    _node        = node;
    _parent      = node.parent;
    _index       = node.index();
    _insert_node = insert_node;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    if( _insert_node != null ) {
      table.delete_node( _insert_node );
    }
    table.insert_node( _parent, _node, _index );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    table.delete_node( _node );
    if( _insert_node != null ) {
      table.insert_node( table.root, _insert_node, 0 );
    }
  }

}
