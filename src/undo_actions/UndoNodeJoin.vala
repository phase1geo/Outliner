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

public class UndoNodeJoin : UndoItem {

  private Node _from;
  private int  _to_children;
  private Node _to;

  /* Default constructor */
  public UndoNodeJoin( Node from, Node to ) {
    base( _( "join rows" ) );
    _from        = from;
    _to          = to;
    _to_children = (int)_to.children.length;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    var index = _to.index() + 1;
    _to.parent.add_child( _from, index );
    for( int i=_to_children; i<_to.children.length; i++ ) {
      var child = _to.children.index( _to_children );
      _to.remove_child( child );
      _from.add_child( child );
    }
    _to.name.text.remove_text( (_to.name.text.text.length - _from.name.text.text.length), _from.name.text.text.length );
    table.selected = _from;
    table.queue_draw();
    table.changed();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    _to.name.text.insert_formatted_text( _to.name.text.text.length, _from.name.text );
    for( int i=0; i<_from.children.length; i++ ) {
      var child = _from.children.index( 0 );
      _from.remove_child( child );
      _to.add_child( child );
    }
    _from.parent.remove_child( _to );
    table.selected = _to;
    table.queue_draw();
    table.changed();
  }

}
