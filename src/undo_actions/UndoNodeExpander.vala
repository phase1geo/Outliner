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

public class UndoNodeExpander : UndoItem {

  private Array<Node> _nodes;

  /* Default constructor */
  public UndoNodeExpander( Array<Node> nodes ) {
    base( _( "expander change" ) );
    _nodes = nodes;
  }

  public void toggle( OutlineTable table ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).expanded = !_nodes.index( i ).expanded;
    }
    table.queue_draw();
    table.changed();
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    toggle( table );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    toggle( table );
  }

}
