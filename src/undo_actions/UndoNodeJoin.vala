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
  private Node _from_parent;
  private int  _from_index;
  private int  _to_children;
  private int  _to_text_len;
  private Node _to;

  /* Default constructor */
  public UndoNodeJoin( Node from, Node to ) {
    base( _( "join rows" ) );
    _from        = from;
    _from_parent = from.parent;
    _from_index  = from.index();
    _to          = to;
    _to_text_len = _to.name.text.text.length;
    _to_children = (int)_to.children.length;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    var chars       = _to.name.text.text.length - _to_text_len;
    var to_children = _to.children.length;
    for( int i=_to_children; i<to_children; i++ ) {
      var child = _to.children.index( _to_children );
      _to.remove_child( child );
      _from.add_child( child );
    }
    _from_parent.add_child( _from, _from_index );
    _to.name.text.remove_text( _to_text_len, chars );
    table.selected = _from;
    table.queue_draw();
    table.changed();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    var from_children = _from.children.length;
    _to.name.text.set_text( _to.name.text.text + " " );
    _to.name.text.insert_formatted_text( _to.name.text.text.length, _from.name.text );
    for( int i=0; i<from_children; i++ ) {
      var child = _from.children.index( 0 );
      _from.remove_child( child );
      _to.add_child( child );
    }
    _from_parent.remove_child( _from );
    table.selected = _to;
    table.queue_draw();
    table.changed();
  }

}
