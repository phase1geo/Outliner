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

public class UndoNodeAddParent : UndoItem {

  private Node _parent;
  private Node _node;
  private Node _child;

  //-------------------------------------------------------------
  // Default constructor
  public UndoNodeAddParent( Node node ) {
    base( _( "add parent" ) );
    _parent = node.parent;
    _node   = node;
    _child  = node.children.index( 0 );
  }

  public override void undo( OutlineTable table ) {
    int index = _node.index();
    _node.remove_child( _child );
    _parent.remove_child( _node );
    _parent.add_child( _child, index );
    table.selected = _child;
    table.see( _child );
    table.queue_draw();
    table.changed();
  }

  public override void redo( OutlineTable table ) {
    int index = _child.index();
    _parent.add_child( _node, index );
    _parent.remove_child( _child );
    _node.add_child( _child, 0 );
    table.selected = _node;
    table.see( _node );
    table.queue_draw();
    table.changed();
  }

}
