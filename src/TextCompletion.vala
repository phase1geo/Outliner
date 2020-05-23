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

using Gtk;

public class TextCompletion {

  private OutlineTable _ot;
  private ListBox      _list;
  private bool         _shown = false;

  public bool shown {
    get {
      return( _shown );
    }
  }

  /* Default constructor */
  public TextCompletion( OutlineTable ot ) {
    _ot = ot;
    _list = new ListBox();
    _list.selection_mode = SelectionMode.BROWSE;
  }

  /* Displays the auto-completion text with the given list */
  public void show( CanvasText ct, Array<string> list ) {

    /* If there is nothing to show, hide the contents */
    if( list.length == 0 ) {
      hide();
      return;
    }

    /* Get the position of the cursor so that we know where to place the box */
    int x, ytop, ybot;
    ct.get_cursor_pos( out x, out ytop, out ybot );

    /* Set the position of the widget */
    _list.margin_start = x;
    _list.margin_top   = ytop + ((ybot - ytop) / 2);

    var overlay = (Overlay)_ot.get_parent();
    overlay.add_overlay( _list );

    _shown = true;

  }

  /* Hides the auto-completion box */
  public void hide() {

    /* If the completion items are not shown, just return */
    if( !_shown ) return;

    _shown = false;

  }

  /* Moves the selection down by one row */
  public void down() {
    if( !_shown ) return;
  }

  /* Moves the selection up by one row */
  public void up() {
    if( !_shown ) return;
  }

  /* Substitutes the currently selected entry */
  public void select() {
    // TBD
  }

}
