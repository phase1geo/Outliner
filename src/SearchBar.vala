/*
* Copyright (c) 2020 (https://github.com/phase1geo/Minder)
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

using Gdk;
using Gtk;

public class SearchMatch {

  public Node? node  { set; get; default = null; }
  public bool  name  { set; get; default = true; }
  public int   start { set; get; default = -1; }
  public int   end   { set; get; default = -1; }

  public SearchMatch() {}

  public string to_string() {
    return( (node == null) ? "none" : "name: %s, str: %s, start: %d, end: %d".printf( name.to_string(), (name ? node.name.text.text : node.note.text.text), start, end ) );
  }

}

public class SearchBar : Box {

  private OutlineTable _ot;
  private SearchEntry  _search_entry;
  private Button       _search_next;
  private Button       _search_prev;
  private SearchEntry  _replace_entry;
  private Button       _replace_current;
  private Button       _replace_all;
  private SearchMatch  _next;
  private SearchMatch  _prev;
  private int          _ignore_update;

  /* Default constructor */
  public SearchBar( OutlineTable ot ) {

    _ot = ot;

    _next = new SearchMatch();
    _prev = new SearchMatch();
    _ignore_update = 0;

    add_search_entry();
    add_search_next();
    add_search_previous();
    add_spacer();
    add_replace_entry();
    add_replace_current();
    add_replace_all();

    _ot.selected_changed.connect( update_next_previous );
    _ot.cursor_changed.connect( update_next_previous );

  }

  /* Called whenever the search bar is displayed or hidden */
  public void change_display( bool show ) {
    if( !show ) {
      _search_entry.text = "";
      search();
      _ignore_update = 2;
    } else {
      _search_entry.grab_focus();
      update_state();
      _ignore_update = 0;
    }
  }

  /* Creates the search entry field and adds it to this box */
  private void add_search_entry() {

    _search_entry = new Gtk.SearchEntry() {
      placeholder_text = _( "Find text…")
    };

    _search_entry.search_changed.connect( search );
    _search_entry.activate.connect( search_next );
    _search_entry.icon_release.connect((pos, e) => {
      if( pos == EntryIconPosition.SECONDARY ) {
        _search_entry.grab_focus();
      }
    });

    append( _search_entry );

  }

  /* Performs the text search */
  private void search() {

    /* Perform search */
    _ot.do_search( _search_entry.text );

    /* Update the UI state */
    update_next_previous();

  }

  /* Called whenever the cursor changes position or the selected node changes */
  private void update_next_previous() {

    if( _ignore_update > 0 ) {
      if( _ignore_update == 1 ) {
        _ignore_update = 0;
      }
      return;
    }

    /* Get the next and previous matches */
    find_next_match();
    find_prev_match();

    /* Update the UI state */
    update_state();

  }

  /* Updates the UI state */
  private void update_state() {

    var found = (_next.node != null) || (_prev.node != null) || is_match_selected();

    _search_next.set_sensitive( _next.node != null );
    _search_prev.set_sensitive( _prev.node != null );
    _replace_entry.editable  = found;
    _replace_entry.can_focus = found;
    _replace_current.set_sensitive( (_replace_entry.text != "") && is_match_selected() );
    _replace_all.set_sensitive( (_replace_entry.text != "") && found );

  }

  /* Creates the search next field and adds it to this box */
  private void add_search_next() {

    _search_next = new Gtk.Button.from_icon_name( "go-down-symbolic" );
    _search_next.clicked.connect( search_next );

    append( _search_next );

  }

  /* Finds the match after the currently selected node */
  private void find_next_match() {

    _next.node  = _ot.selected;
    _next.name  = true;
    _next.start = -1;

    var start = 0;

    if( _next.node != null ) {
      switch( _next.node.mode ) {
        case NodeMode.EDITABLE :
          _next.name = true;
          start = _next.node.name.is_selected() ? _next.node.name.selend : _next.node.name.cursor + 1;
          break;
        case NodeMode.NOTEEDIT :
          _next.name = false;
          start = _next.node.note.is_selected() ? _next.node.note.selend : _next.node.note.cursor + 1;
          break;
      }
    } else if( _ot.root.children.length > 0 ) {
      _next.node = _ot.root.children.index( 0 );
    } else {
      return;
    }

    if( _next.name ) {
      _next.node.name.text.get_search_match( start, true, ref _next );
    } else {
      _next.node.note.text.get_search_match( start, true, ref _next );
    }

    while( (_next.node != null) && (_next.start == -1) ) {
      _next.name = !_next.name;
      if( _next.name ) {
        _next.node = _next.node.get_next_node();
      }
      if( _next.node != null ) {
        if( _next.name ) {
          _next.node.name.text.get_search_match( 0, true, ref _next );
        } else {
          _next.node.note.text.get_search_match( 0, true, ref _next );
        }
      }
    }

  }

  /* Finds the match after the currently selected node */
  private void find_prev_match() {

    _prev.node  = _ot.selected;
    _prev.name  = false;
    _prev.start = -1;

    var start = 0;

    if( _prev.node != null ) {
      switch( _prev.node.mode ) {
        case NodeMode.EDITABLE :
          _prev.name = true;
          start = _prev.node.name.is_selected() ? _prev.node.name.selstart : _prev.node.name.cursor;
          break;
        case NodeMode.NOTEEDIT :
          _prev.name = false;
          start = _prev.node.note.is_selected() ? _prev.node.name.selstart : _prev.node.note.cursor;
          break;
      }
    } else {
      return;
    }

    if( _prev.name ) {
      _prev.node.name.text.get_search_match( start, false, ref _prev );
    } else {
      _prev.node.note.text.get_search_match( start, false, ref _prev );
    }

    while( (_prev.node != null) && (_prev.start == -1) ) {
      _prev.name = !_prev.name;
      if( !_prev.name ) {
        _prev.node = _prev.node.get_previous_node();
      }
      if( _prev.node != null ) {
        if( _prev.name ) {
          _prev.node.name.text.get_search_match( _prev.node.name.text.text.length, false, ref _prev );
        } else {
          _prev.node.note.text.get_search_match( _prev.node.name.text.text.length, false, ref _prev );
        }
      }
    }

  }

  /* Perform the search for the next text match */
  private void search_next() {
    select_matched_text( _next );
  }

  /* Selects the matched text */
  private void select_matched_text( SearchMatch match ) {

    if( match.node == null ) return;

    var selchange = (match.node != _ot.selected);
    var curchange = (match.name ? match.node.name.cursor : match.node.note.cursor) != match.end;

    /* Set the matched node to edit mode and select the matched text */
    _ignore_update = selchange ? 1 : 0;
    _ot.selected   = match.node;
    _ot.edit_selected( match.name );

    if( match.name ) {
      _ot.selected.name.change_selection( match.start, match.end );
      _ot.selected.name.set_cursor_only( match.end );
    } else {
      _ot.selected.note.change_selection( match.start, match.end );
      _ot.selected.note.set_cursor_only( match.end );
    }

    /* Make sure that we update the search bar */
    if( !curchange ) {
      _ot.cursor_changed();
    }

  }

  /* Creates the search previous field and adds it to this box */
  private void add_search_previous() {

    _search_prev = new Gtk.Button.from_icon_name( "go-up-symbolic" );
    _search_prev.clicked.connect( search_previous );

    append( _search_prev );

  }

  /* Perform the search for the previous text match */
  private void search_previous() {

    /* Select the matched text */
    select_matched_text( _prev );

  }

  /* Adds a spacer between the search and replace portions of the search bar */
  private void add_spacer() {
    var lbl = new Label( " " );
    pack_start( lbl, false, false, 2 );
  }

  /* Returns true if the selected text is a matched pattern */
  private bool is_match_selected() {

    var pattern = _search_entry.text;

    if( (_ot.selected != null) && (pattern != "") ) {
      string? seltext = null;
      switch( _ot.selected.mode ) {
        case NodeMode.EDITABLE :  seltext = _ot.selected.name.get_selected_text();  break;
        case NodeMode.NOTEEDIT :  seltext = _ot.selected.note.get_selected_text();  break;
      }
      return( (seltext != null) && (seltext == pattern) );
    }

    return( false );

  }

  /* Adds the replace text entry field and adds it to this box */
  private void add_replace_entry() {

    var focus_controller = new EventControllerFocus();
    _replace_entry = new Gtk.SearchEntry() {
      halign            = Align.FILL,
      hexpand           = true,
      placeholder_text  = _( "Replace with…"),
      primary_icon_name = null
    };
    _replace_entry.add_controller( focus_controller );

    _replace_entry.search_changed.connect( replace_text_changed );
    _replace_entry.enter.connect( replace_focus_in );

    _replace_entry.icon_release.connect((pos, e) => {
      if( (pos == EntryIconPosition.SECONDARY) && _replace_entry.can_focus ) {
        _replace_entry.grab_focus();
      }
    });

    append( _replace_entry );

  }

  /* Called when the search box loses focus */
  private bool replace_focus_in() {
    if( !is_match_selected() ) {
      select_matched_text( _next );
    }
    return( false );
  }

  /* Called whenever the replacement text is changed */
  private void replace_text_changed() {
    update_state();
  }

  /* Adds the replace current button and adds it to this box */
  private void add_replace_current() {

    _replace_current = new Gtk.Button.with_label( _( "Replace" ) );
    _replace_current.clicked.connect( replace_current );

    append( _replace_current );

  }

  /* Performs the replacement for the currently matched text */
  private void replace_current() {

    /* Replace the current match */
    _ot.replace_current( _replace_entry.text );

    /* Jump to the next match */
    select_matched_text( _next );

  }

  /* Adds the replace all button and adds it to this box */
  private void add_replace_all() {

    _replace_all = new Gtk.Button.with_label( _( "Replace All" ) );
    _replace_all.clicked.connect( replace_all );

    append( _replace_all );

  }

  /* Performs the replacement for all text that matches the search text */
  private void replace_all() {

    _ot.replace_all( _search_entry.text, _replace_entry.text );

  }

}
