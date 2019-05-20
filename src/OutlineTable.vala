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

  private TreeStore        _store;
  private CellRendererText _cell;

  public UndoBuffer undo_buffer { get; set; }
  public Theme      theme       { get; set; default = new Theme(); }

  /* Default constructor */
  public OutlineTable() {

    /* Allocate storage item */
    _store = new TreeStore( 1, typeof (string) );

    /* Allocate cell renderer */
    _cell          = new CellRendererText();
    _cell.editable = true;
    _cell.edited.connect((path, txt) => {
      TreeIter iter;
      if( _store.get_iter_from_string( out iter, path ) ) {
        Value val = Value( typeof( string ) );
        val.set_string( txt );
        _store.set_value( iter, 0, val );
      }
    });

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );

    /* Enable the expanders in the tree */
    this.insert_column_with_attributes( -1, "Something", _cell, "markup", 0, null );
    this.model           = _store;
    this.show_expanders  = true;
    this.reorderable     = true;
    this.activate_on_single_click = false;
    this.expander_column = get_column( 0 );
    this.enable_tree_lines = true;

    row_activated.connect((path, col) => {
      set_cursor( path, col, true );
      grab_focus();
    });
    drag_motion.connect((ctx, x, y, t) => {
      TreePath             path;
      TreeViewDropPosition pos;
      if( get_dest_row_at_pos( x, y, out path, out pos ) ) {
        stdout.printf( "path: %s, pos: %s\n", path.to_string(), pos.to_string() );
        set_drag_dest_row( path, pos );
      } else {
        set_drag_dest_row( null, pos );
      }
      return( false );
    });
    
    /*
     Add some test data so that we can test things before we add the
     ability to save and load data.
    */
    add_test_data();

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

  /* Indents the currently selected row such that it becomes the child of the sibling row above it */
  public void indent() {
    TreeModel model;
    TreeIter  iter;
    TreeIter  other;
    Value     val;
    get_selection().get_selected( out model, out iter );
    _store.get_value( iter, 0, out val );
    other = iter;
    if( model.iter_previous( ref iter ) ) {
      TreeIter new_iter;
      _store.remove( ref other );
      _store.append( out new_iter, iter );
      _store.set( new_iter, 0, (string)val, -1 );
      expand_to_path( _store.get_path( iter ) );
      get_selection().select_iter( new_iter );
    }
  }

  /* Removes the currently selected row from its parent and places itself just below its parent */
  public void unindent() {
    TreeModel model;
    TreeIter  iter;
    TreeIter  parent;
    TreeIter? grandparent;
    Value     val;
    get_selection().get_selected( out model, out iter );
    _store.get_value( iter, 0, out val );
    if( model.iter_parent( out parent, iter ) ) {
      TreeIter new_iter;
      if( !model.iter_parent( out grandparent, parent ) ) {
        grandparent = null;
      }
      _store.remove( ref iter );
      _store.insert_after( out new_iter, grandparent, parent );
      _store.set( new_iter, 0, (string)val, -1 );
      get_selection().select_iter( new_iter );
    }
  }

  /* Temporary function which gives us some test data */
  private void add_test_data() {

    /* Let's display some stuff to see how things work */
    TreeIter level0;
    TreeIter level1;
    TreeIter level2;

    _store.append( out level0, null );
    _store.set( level0, 0, "Main Idea", -1 );

    _store.append( out level1, level0 );
    _store.set( level1, 0, "First things", -1 );
    _store.append( out level1, level0 );
    _store.set( level1, 0, "Second things", -1 );

    _store.append( out level2, level1 );
    _store.set( level2, 0, "Subitem A", -1 );
    _store.append( out level2, level1 );
    _store.set( level2, 0, "Subitem B", -1 );

    _store.append( out level1, level0 );
    _store.set( level1, 0, "Third things", -1 );

    this.expand_all();

  }

}

