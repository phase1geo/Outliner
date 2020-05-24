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

  private OutlineTable   _ot;
  private CanvasText     _ct;
  private ListBox        _list;
  private bool           _shown     = false;
  private int            _size      = 0;
  private int            _start_pos = 0;
  private int            _end_pos   = 0;

  public bool shown {
    get {
      return( _shown );
    }
  }

  /* Default constructor */
  public TextCompletion( OutlineTable ot ) {
    _ot      = ot;
    _list = new ListBox();
    _list.selection_mode = SelectionMode.BROWSE;
    _list.halign         = Align.START;
    _list.valign         = Align.START;
    _list.row_activated.connect( activate_row );
  }

  /* Displays the auto-completion text with the given list */
  public void show( CanvasText ct, Array<string> list, int start, int end ) {

    /* If there is nothing to show, hide the contents */
    if( list.length == 0 ) {
      hide();
      return;
    }

    /* Remember the text positions that will be replaced */
    _ct        = ct;
    _start_pos = start;
    _end_pos   = end;

    /* Populate the list */
    _list.foreach( (w) => {
      _list.remove( w );
    });
    for( int i=0; i<list.length; i++ ) {
      var lbl = new Label( list.index( i ) );
      lbl.xalign       = 0;
      lbl.margin       = 5;
      lbl.margin_start = 10;
      lbl.margin_end   = 10;
      _list.add( lbl );
    }
    _size = (int)list.length;

    /* Get the position of the cursor so that we know where to place the box */
    int x, ytop, ybot;
    ct.get_cursor_pos( out x, out ytop, out ybot );

    /* Set the position of the widget */
    _list.margin_start = x;
    _list.margin_top   = ybot + 5;

    /* Select the first row */
    _list.select_row( _list.get_row_at_index( 0 ) );

    /* Make sure that everything is seen */
    _list.show_all();

    /* If the list isn't being shown, show it */
    if( !_shown ) {
      var overlay = (Overlay)_ot.get_parent();
      overlay.add_overlay( _list );
    }

    _shown = true;

  }

  /* Hides the auto-completion box */
  public void hide() {
    if( !_shown ) return;
    _list.unparent();
    _shown = false;
  }

  /* Moves the selection down by one row */
  public void down() {
    if( !_shown ) return;
    var row = _list.get_selected_row();
    if( (row.get_index() + 1) < _size ) {
      _list.select_row( _list.get_row_at_index ( row.get_index() + 1 ) );
    }
  }

  /* Moves the selection up by one row */
  public void up() {
    if( !_shown ) return;
    var row = _list.get_selected_row();
    if( row.get_index() > 0 ) {
      _list.select_row( _list.get_row_at_index ( row.get_index() - 1 ) );
    }
  }

  /* Substitutes the currently selected entry */
  public void select() {
    if( !_shown ) return;
    activate_row( _list.get_selected_row() );
  }

  private void activate_row( ListBoxRow row ) {
    var label = (Label)row.get_child();
    var value = label.get_text();
    if( _start_pos == _end_pos ) {
      _ct.insert( value, _ot.undo_text );
    } else {
      _ct.replace( _start_pos, _end_pos, value, _ot.undo_text );
    }
    hide();
  }

}
