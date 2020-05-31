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

public class FocusStack {

  private Array<Node> _stack;
  private int         _index;

  public FocusStack() {
    _stack = new Array<Node>();
    _index = -1;
  }

  /* Returns true if we are in focus mode */
  public bool in_focus() {
    return( _stack.length > 0 );
  }

  /* Clears the focus stack */
  public void clear() {
    _stack.remove_range( 0, _stack.length );
    _index = -1;
  }

  /* Pushes a new node into the focus stack */
  public void push( Node node ) {
    if( (_index + 1) < _stack.length ) {
      _stack.remove_range( (_index + 1), (_stack.length - (_index + 1)) );
    }
    _stack.append_val( node );
    _index++;
  }

  /* Moves backward in the stack by one */
  public Node? back() {
    return( (_index == 0) ? null : _stack.index( --_index ) );
  }

  /* Moves forward in the stack by one */
  public Node? forward() {
    return( ((_index + 1) == _stack.length) ? null : _stack.index( ++_index ) );
  }

}
