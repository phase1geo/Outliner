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

public class SearchBar : Box {

  private OutlineTable _ot;

  /* Default constructor */
  // public SearchBar( OutlineTable ot ) {
  public SearchBar() {

    // _ot = ot;

    add_search_entry();
    add_search_next();
    add_search_previous();
    add_replace_entry();
    add_replace_current();
    add_replace_all();

    show_all();

  }

  /* Creates the search entry field and adds it to this box */
  private void add_search_entry() {

    var entry = new Gtk.SearchEntry();
    entry.placeholder_text = _( "Find text…");
    entry.search_changed.connect( search );

    pack_start( entry, true, true, 5 );

  }

  /* Performs the text search */
  private void search() {

    // TBD

  }

  /* Creates the search next field and adds it to this box */
  private void add_search_next() {

    var next = new Gtk.Button.from_icon_name( "go-down-symbolic", IconSize.SMALL_TOOLBAR );
    next.clicked.connect( search_next );

    pack_start( next, false, false, 5 );

  }

  /* Perform the search for the next text match */
  private void search_next() {

    // TBD

  }

  /* Creates the search previous field and adds it to this box */
  private void add_search_previous() {

    var prev = new Gtk.Button.from_icon_name( "go-up-symbolic", IconSize.SMALL_TOOLBAR );
    prev.clicked.connect( search_previous );

    pack_start( prev, false, false, 5 );

  }

  /* Perform the search for the previous text match */
  private void search_previous() {

    // TBD

  }

  /* Adds the replace text entry field and adds it to this box */
  private void add_replace_entry() {

    var entry = new Gtk.Entry();
    entry.placeholder_text = _( "Replace with…");

    pack_start( entry, true, true, 5 );

  }

  /* Adds the replace current button and adds it to this box */
  private void add_replace_current() {

    var current = new Gtk.Button.with_label( _( "Replace Current" ) );
    current.clicked.connect( replace_current );

    pack_start( current, false, false, 5 );

  }

  /* Performs the replacement for the currently matched text */
  private void replace_current() {

    // TBD

  }

  /* Adds the replace all button and adds it to this box */
  private void add_replace_all() {

    var all = new Gtk.Button.with_label( _( "Replace All" ) );
    all.clicked.connect( replace_all );

    pack_start( all, false, false, 5 );

  }

  /* Performs the replacement for all text that matches the search text */
  private void replace_all() {

    // TBD

  }

}
