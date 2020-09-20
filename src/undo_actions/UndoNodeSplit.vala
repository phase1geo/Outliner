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

public class UndoNodeSplit : UndoItem {

  private Node               _parent;
  private Node               _node;
  private int                _index;
  private int                _cursor;
  private Array<UndoTagInfo> _tags;

  /* Default constructor */
  public UndoNodeSplit( Node node ) {
    base( _( "split item" ) );
    _node   = node;
    _parent = node.parent;
    _index  = node.index();
    _cursor = _parent.children.index( _index - 1 ).name.text.text.length;
    _tags   = node.name.text.get_tags_in_range( 0, node.name.text.text.length );
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    var prev_node    = _parent.children.index( _index - 1 );
    var name         = prev_node.name;
    var text         = _node.name.text.text;
    var num_children = _node.children.length;
    name.text.insert_text( _cursor, text );
    name.text.apply_tags( _tags, _cursor );
    for( int i=0; i<num_children; i++ ) {
      var child = _node.children.index( 0 );
      _node.remove_child( child );
      prev_node.add_child( child );
    }
    table.delete_node( _node );
    table.selected = prev_node;
    table.queue_draw();
    table.changed();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    var prev_node    = _parent.children.index( _index - 1 );
    var endpos       = prev_node.name.text.text.char_count( prev_node.name.text.text.length );
    var num_children = prev_node.children.length;
    prev_node.name.text.remove_text( _cursor, (endpos - _cursor) );
    table.insert_node( _parent, _node, _index );
    for( int i=0; i<num_children; i++ ) {
      var child = prev_node.children.index( 0 );
      prev_node.remove_child( child );
      _node.add_child( child );
    }
    table.selected = _node;
    table.queue_draw();
    table.changed();
  }

}
