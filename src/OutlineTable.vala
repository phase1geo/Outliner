/*
* Copyright (c) 2018 (https://github.com/phase1geo/Outliner)
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

public class OutlineTable : TreeView {

  public UndoBuffer undo_buffer { get; set; }
  public Theme      theme       { get; set; default = new Theme(); }

  /* Default constructor */
  public OutlineTable() {

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );

  }

  /* Called by this class when a change is made to the table */
  public signal void changed();

  public void initialize_for_new() {
    // TBD
  }

  public void initialize_for_open() {
    // TBD
  }

  /* Loads the table information from the given XML node */
  public void load( Xml.Node* n ) {
    // TBD
  }

  /* Saves the table information to the given XML node */
  public void save( Xml.Node* n ) {
    // TBD
  }

  /* Finds the rows that match the given search criteria */
  public void get_match_items( string pattern, bool[] opts, ref Gtk.ListStore items ) {
    // TBD
  }

}

