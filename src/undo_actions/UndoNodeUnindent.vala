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

public class UndoNodeUnindent : UndoItem {

  private Node _node;
  private int  _num_children;

  /* Default constructor */
  public UndoNodeUnindent( Node node ) {
    base( _( "unindent item" ) );
    _node         = node;
    _num_children = (int)node.children.length;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    table.indent_node( _node );
    var children = (int)_node.children.length;
    for( int i=_num_children; i<children; i++ ) {
      var child = _node.children.index( _num_children );
      _node.remove_child( child );
      _node.parent.add_child( child, -1 );
    }
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    table.unindent_node( _node );
  }

}
