/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

public class SearchMatch {

  public Node node  { private set; get; }
  public bool name  { private set; get; }
  public int  start { private set; get; }

  public SearchMatch( Node node, bool name, int start ) {
    this.node  = node;
    this.name  = name;
    this.start = start;
  }

}

public class SearchBar : Box {

  private OutlineTable       _ot;
  private SearchEntry        _search_entry;
  private Button             _search_next;
  private Button             _search_prev;
  private SearchEntry        _replace_entry;
  private Button             _replace_current;
  private Button             _replace_all;
  private Array<SearchMatch> _matches;
  private int                _match_ptr;

  /* Default constructor */
  public SearchBar( OutlineTable ot ) {

    _ot = ot;

    /* Initialize variables */
    _matches = new Array<SearchMatch>();

    add_search_entry();
    add_search_next();
    add_search_previous();
    add_replace_entry();
    add_replace_current();
    add_replace_all();

    show_all();

  }

  /* Called whenever the search bar is displayed or hidden */
  public void change_display( bool show ) {
    if( !show ) {
      _search_entry.text = "";
      search();
    } else {
      _search_entry.grab_focus();
    }
  }

  /* Creates the search entry field and adds it to this box */
  private void add_search_entry() {

    _search_entry = new Gtk.SearchEntry();
    _search_entry.placeholder_text = _( "Find text…");
    _search_entry.search_changed.connect( search );
    _search_entry.activate.connect( search_next );

    pack_start( _search_entry, true, true, 5 );

  }

  /* Performs the text search */
  private void search() {

    /* Clear the current matches */
    _matches.remove_range( 0, _matches.length );

    /* Perform search */
    _ot.do_search( _search_entry.text, ref _matches );

    /* Get the closest match to the current cursor position */
    find_next_match();

    /* Update the UI state */
    update_state();

  }

  /* Updates the UI state */
  private void update_state() {

    _search_next.set_sensitive( _match_ptr < _matches.length );
    _search_prev.set_sensitive( (_matches.length > 0) && (_match_ptr !=  0) );
    _replace_entry.set_sensitive( _matches.length > 0 );
    _replace_current.set_sensitive( (_replace_entry.text != "") && (_matches.length > 0) );
    _replace_all.set_sensitive( (_replace_entry.text != "") && (_matches.length > 0) );

  }

  /* Creates the search next field and adds it to this box */
  private void add_search_next() {

    _search_next = new Gtk.Button.from_icon_name( "go-down-symbolic", IconSize.SMALL_TOOLBAR );
    _search_next.clicked.connect( search_next );

    pack_start( _search_next, false, false, 5 );

  }

  /* Finds the match after the currently selected node */
  private void find_next_match() {

    var selected = _ot.selected;

    if( (_matches.length == 0) || (selected == null) ) {
      _match_ptr = 0;
      return;
    }

    var y      = selected.y;
    var cursor = (selected.mode == NodeMode.EDITABLE) ? selected.name.cursor :
                 (selected.mode == NodeMode.NOTEEDIT) ? selected.note.cursor : -1;

    _match_ptr = -1;

    for( int i=0; i<_matches.length; i++ ) {
      var match = _matches.index( i );
      stdout.printf( "  i: %d, matches: %u, match.node.y: %g, y: %g, match.start: %d, cursor: %d\n", i, _matches.length, match.node.y, y, match.start, cursor );
      if( (match.node.y >= y) && ((match.node != selected) || (match.start > cursor)) ) {
        _match_ptr = i;
        return;
      }
    }

  }

  /* Perform the search for the next text match */
  private void search_next() {

    /* Get the next match */
    find_next_match();

    /* Select the matched text */
    select_matched_text();

    /* Update the UI state */
    update_state();

  }

  /* Selects the matched text */
  private void select_matched_text() {

    var current = _matches.index( _match_ptr );
    var pattern = _search_entry.text;
    var end     = current.start + pattern.length;

    /* Set the matched node to edit mode and select the matched text */
    _ot.selected = current.node;
    _ot.edit_selected( current.name );
    if( current.name ) {
      _ot.selected.name.change_selection( current.start, end );
      _ot.selected.name.set_cursor_only( end );
    } else {
      _ot.selected.note.change_selection( current.start, end );
      _ot.selected.note.set_cursor_only( end );
    }

  }

  /* Creates the search previous field and adds it to this box */
  private void add_search_previous() {

    _search_prev = new Gtk.Button.from_icon_name( "go-up-symbolic", IconSize.SMALL_TOOLBAR );
    _search_prev.clicked.connect( search_previous );

    pack_start( _search_prev, false, false, 5 );

  }

  /* Perform the search for the previous text match */
  private void search_previous() {

    /* Get the previous match */
    find_next_match();
    _match_ptr--;

    /* Select the matched text */
    select_matched_text();

    /* Update the UI state */
    update_state();

  }

  /* Adds the replace text entry field and adds it to this box */
  private void add_replace_entry() {

    _replace_entry = new Gtk.SearchEntry();
    _replace_entry.placeholder_text = _( "Replace with…");

    pack_start( _replace_entry, true, true, 5 );

  }

  /* Adds the replace current button and adds it to this box */
  private void add_replace_current() {

    _replace_current = new Gtk.Button.with_label( _( "Replace Current" ) );
    _replace_current.clicked.connect( replace_current );

    pack_start( _replace_current, false, false, 5 );

  }

  /* Performs the replacement for the currently matched text */
  private void replace_current() {

    // TBD

  }

  /* Adds the replace all button and adds it to this box */
  private void add_replace_all() {

    _replace_all = new Gtk.Button.with_label( _( "Replace All" ) );
    _replace_all.clicked.connect( replace_all );

    pack_start( _replace_all, false, false, 5 );

  }

  /* Performs the replacement for all text that matches the search text */
  private void replace_all() {

    var replace = _replace_entry.text;

    for( int i=0; i<_matches.length; i++ ) {
      var match = _matches.index( i );
      if( match.name ) {
        /* TBD */
      }
    }

  }

}
