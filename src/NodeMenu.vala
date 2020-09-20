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

public class NodeMenu : Gtk.Menu {

  private OutlineTable _ot;
  private Gtk.MenuItem _copy;
  private Gtk.MenuItem _cut;
  private Gtk.MenuItem _paste;
  private Gtk.MenuItem _paste_replace;
  private Gtk.MenuItem _delete;
  private Gtk.MenuItem _clone_copy;
  private Gtk.MenuItem _clone_paste;
  private Gtk.MenuItem _unclone;
  private Gtk.MenuItem _edit_text;
  private Gtk.MenuItem _edit_note;
  private Gtk.MenuItem _note_display;
  private Gtk.MenuItem _add_above;
  private Gtk.MenuItem _add_below;
  private Gtk.MenuItem _join;
  private Gtk.MenuItem _indent;
  private Gtk.MenuItem _unindent;
  private Gtk.MenuItem _expander;
  private Gtk.MenuItem _focus;
  private Gtk.MenuItem _select_above;
  private Gtk.MenuItem _select_below;
  private Gtk.MenuItem _select_prev_sibling;
  private Gtk.MenuItem _select_next_sibling;
  private Gtk.MenuItem _select_parent;
  private Gtk.MenuItem _select_last_child;
  private Gtk.MenuItem _select_first;
  private Gtk.MenuItem _select_last;
  private Gtk.MenuItem _select_label;
  private Gtk.MenuItem _add_label;
  private Gtk.MenuItem _clear_all_labels;
  private Array<Gtk.MenuItem> _move_labels;
  private Array<Gtk.MenuItem> _select_labels;

  public NodeMenu( OutlineTable ot ) {

    _ot = ot;

    _copy = new Gtk.MenuItem();
    _copy.add( new Granite.AccelLabel( _( "Copy" ), "<Control>c" ) );
    _copy.activate.connect( copy );

    _cut = new Gtk.MenuItem();
    _cut.add( new Granite.AccelLabel( _( "Cut" ), "<Control>x" ) );
    _cut.activate.connect( cut );

    _paste = new Gtk.MenuItem();
    _paste.add( new Granite.AccelLabel( _( "Paste" ), "<Control>v" ) );
    _paste.activate.connect( paste );

    _paste_replace = new Gtk.MenuItem();
    _paste_replace.add( new Granite.AccelLabel( _( "Paste and Replace" ), "<Control><Shift>v" ) );
    _paste_replace.activate.connect( paste_replace );

    _delete = new Gtk.MenuItem();
    _delete.add( new Granite.AccelLabel( _( "Delete" ), "Delete" ) );
    _delete.activate.connect( delete_node );

    var clone = new Gtk.MenuItem.with_label( _( "Clone" ) );
    var clone_menu = new Gtk.Menu();
    clone.set_submenu( clone_menu );

    _clone_copy = new Gtk.MenuItem.with_label( _( "Copy As Clone" ) );
    _clone_copy.activate.connect( clone_copy );

    _clone_paste = new Gtk.MenuItem.with_label( _( "Paste Clone" ) );
    _clone_paste.activate.connect( clone_paste );

    _unclone = new Gtk.MenuItem.with_label( _( "Unclone" ) );
    _unclone.activate.connect( unclone );

    _edit_text = new Gtk.MenuItem();
    _edit_text.add( new Granite.AccelLabel( _( "Edit Text" ), "e" ) );
    _edit_text.activate.connect( edit_text );

    _edit_note = new Gtk.MenuItem();
    _edit_note.add( new Granite.AccelLabel( _( "Edit Note" ), "<Shift>e" ) );
    _edit_note.activate.connect( edit_note );

    _note_display = new Gtk.MenuItem.with_label( _( "Show Note" ) );
    _note_display.activate.connect( toggle_note );

    var tag_add = new Gtk.MenuItem.with_label( _( "Add Tag" ) );
    tag_add.activate.connect( add_tag );

    _add_above = new Gtk.MenuItem();
    _add_above.add( new Granite.AccelLabel( _( "Add Row Above" ), "<Shift>Return" ) );
    _add_above.activate.connect( add_row_above );

    _add_below = new Gtk.MenuItem();
    _add_below.add( new Granite.AccelLabel( _( "Add Row Below" ), "Return" ) );
    _add_below.activate.connect( add_row_below );

    _join = new Gtk.MenuItem();
    _join.add( new Granite.AccelLabel( _( "Join To Row Above" ), "<Control>BackSpace" ) );
    _join.activate.connect( join_row );

    _indent = new Gtk.MenuItem();
    _indent.add( new Granite.AccelLabel( _( "Indent" ), "Tab" ) );
    _indent.activate.connect( indent );

    _unindent = new Gtk.MenuItem();
    _unindent.add( new Granite.AccelLabel( _( "Unindent" ), "<Shift>Tab" ) );
    _unindent.activate.connect( unindent );

    _expander = new Gtk.MenuItem.with_label( _( "Expand Children" ) );
    _expander.activate.connect( toggle_expand );

    _focus = new Gtk.MenuItem();
    _focus.add( new Granite.AccelLabel( _( "Focus" ), "f" ) );
    _focus.activate.connect( focus_mode_enter );

    var select = new Gtk.MenuItem.with_label( _( "Select Row" ) );
    var selmenu = new Gtk.Menu();
    select.set_submenu( selmenu );

    _select_above = new Gtk.MenuItem();
    _select_above.add( new Granite.AccelLabel( _( "Select Row Above" ), "Up" ) );
    _select_above.activate.connect( select_node_above );

    _select_below = new Gtk.MenuItem();
    _select_below.add( new Granite.AccelLabel( _( "Select Row Below" ), "Down" ) );
    _select_below.activate.connect( select_node_below );

    _select_prev_sibling = new Gtk.MenuItem();
    _select_prev_sibling.add( new Granite.AccelLabel( _( "Select Previous Sibling Row" ), "<Shift>Up" ) );
    _select_prev_sibling.activate.connect( select_prev_sibling_node );

    _select_next_sibling = new Gtk.MenuItem();
    _select_next_sibling.add( new Granite.AccelLabel( _( "Select Next Sibling Row" ), "<Shift>Down" ) );
    _select_next_sibling.activate.connect( select_next_sibling_node );

    _select_parent = new Gtk.MenuItem();
    _select_parent.add( new Granite.AccelLabel( _( "Select Parent Row" ), "a" ) );
    _select_parent.activate.connect( select_parent_node );

    _select_last_child = new Gtk.MenuItem();
    _select_last_child.add( new Granite.AccelLabel( _( "Select Last Child Row" ), "c" ) );
    _select_last_child.activate.connect( select_last_child_node );

    _select_first = new Gtk.MenuItem();
    _select_first.add( new Granite.AccelLabel( _( "Select First Row" ), "<Shift>t" ) );
    _select_first.activate.connect( select_first_node );

    _select_last = new Gtk.MenuItem();
    _select_last.add( new Granite.AccelLabel( _( "Select Last Row" ), "<Shift>b" ) );
    _select_last.activate.connect( select_last_node );

    _select_label = new Gtk.MenuItem.with_label( _( "Select Labeled Row" ) );
    var lbl_selmenu = new Gtk.Menu();
    _select_label.set_submenu( lbl_selmenu );

    var labels = new Gtk.MenuItem.with_label( _( "Labels" ) );
    var lblmenu = new Gtk.Menu();
    labels.set_submenu( lblmenu );

    _add_label = new Gtk.MenuItem();
    _add_label.add( new Granite.AccelLabel( _( "Add Label" ), "numbersign" ) );
    _add_label.activate.connect( toggle_label );

    var move_to_label = new Gtk.MenuItem.with_label( _( "Move To Label" ) );
    var lbl_movemenu = new Gtk.Menu();
    move_to_label.set_submenu( lbl_movemenu );

    _clear_all_labels = new Gtk.MenuItem.with_label( _( "Clear All Labels" ) );
    _clear_all_labels.activate.connect( clear_all_labels );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste );
    add( _paste_replace );
    add( clone );
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _edit_text );
    add( _edit_note );
    add( _note_display );
    add( tag_add );
    add( new SeparatorMenuItem() );
    add( _indent );
    add( _unindent );
    add( _expander );
    add( _focus );
    add( new SeparatorMenuItem() );
    add( _add_above );
    add( _add_below );
    add( _join );
    add( new SeparatorMenuItem() );
    add( select );
    add( labels );

    /* Add the clone menu items */
    clone_menu.add( _clone_copy );
    clone_menu.add( _clone_paste );
    clone_menu.add( new SeparatorMenuItem() );
    clone_menu.add( _unclone );

    /* Add the select menu items */
    selmenu.add( _select_above );
    selmenu.add( _select_below );
    selmenu.add( new SeparatorMenuItem() );
    selmenu.add( _select_prev_sibling );
    selmenu.add( _select_next_sibling );
    selmenu.add( new SeparatorMenuItem() );
    selmenu.add( _select_parent );
    selmenu.add( _select_last_child );
    selmenu.add( new SeparatorMenuItem() );
    selmenu.add( _select_first );
    selmenu.add( _select_last );
    selmenu.add( new SeparatorMenuItem() );
    selmenu.add( _select_label );

    /* Add the labels menu items */
    lblmenu.add( _add_label );
    lblmenu.add( move_to_label );
    lblmenu.add( new SeparatorMenuItem() );
    lblmenu.add( _clear_all_labels );

    _move_labels   = new Array<Gtk.MenuItem>();
    _select_labels = new Array<Gtk.MenuItem>();

    /* Populate the add and move label submenus */
    for( int i=0; i<9; i++ ) {

      var lbl_value = i + 1;
      var index     = i;

      var move_item = new Gtk.CheckMenuItem();
      move_item.add( new Granite.AccelLabel( _( "Label-" ) + lbl_value.to_string(), "<Control>" + lbl_value.to_string() ) );
      move_item.activate.connect(() => {
        _ot.handle_control_number( index );
      });
      lbl_movemenu.add( move_item );
      _move_labels.append_val( move_item );

      var sel_item = new Gtk.MenuItem();
      sel_item.add( new Granite.AccelLabel( _( "Label-" ) + lbl_value.to_string(), lbl_value.to_string() ) );
      sel_item.activate.connect(() => {
        select_label( index );
      });
      lbl_selmenu.add( sel_item );
      _select_labels.append_val( sel_item );

    }

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Called when the menu is popped up */
  private void on_popup() {

    var pasteable  = OutlinerClipboard.node_pasteable();
    var first_node = _ot.root.get_first_node();

    /* Set the menu sensitivity */
    _paste.set_sensitive( pasteable );
    _paste_replace.set_sensitive( pasteable );
    _unclone.set_sensitive( _ot.selected.is_clone() );
    _clone_paste.set_sensitive( _ot.cloneable() );
    _indent.set_sensitive( _ot.indentable() );
    _unindent.set_sensitive( _ot.unindentable() );
    _select_above.set_sensitive( _ot.selected.get_previous_node() != null );
    _select_below.set_sensitive( _ot.selected.get_next_node() != null );
    _select_prev_sibling.set_sensitive( _ot.selected.get_previous_sibling() != null );
    _select_next_sibling.set_sensitive( _ot.selected.get_next_sibling() != null );
    _select_parent.set_sensitive( !_ot.selected.parent.is_root() );
    _select_last_child.set_sensitive( !_ot.selected.is_leaf() );
    _select_first.set_sensitive( (first_node != _ot.selected) && !first_node.is_root() );
    _select_last.set_sensitive( (_ot.root.get_last_node() != _ot.selected) && !first_node.is_root() );
    _select_label.set_sensitive( false );
    _join.set_sensitive( _ot.is_node_joinable() );

    if( _ot.labels.get_label_for_node( _ot.selected ) == -1 ) {
      _add_label.label = _( "Add Label" );
      _add_label.set_sensitive( _ot.labels.label_available() );
    } else {
      _add_label.label = _( "Remove Label" );
      _add_label.set_sensitive( true );
    }

    for( int i=0; i<9; i++ ) {
      var node = _ot.labels.get_node( i );
      _move_labels.index( i ).set_sensitive( node != null );
      _select_labels.index( i ).set_sensitive( node != null );
      if( node != null ) {
        _select_label.set_sensitive( true );
      }
    }

    if( _ot.selected.hide_note ) {
      _note_display.label = _( "Show Note" );
      _note_display.set_sensitive( (_ot.selected.note.text.text != "") );
    } else {
      _note_display.label = _( "Hide Note" );
      _note_display.set_sensitive( true );
    }

    _expander.label = _ot.selected.expanded ? _( "Hide Children" ) : _( "Show Children" );
    _expander.set_sensitive( _ot.selected.children.length > 0 );

  }

  /* Copies the currently selected node */
  private void copy() {
    _ot.copy_selected_node();
  }

  /* Cuts the currently selected node */
  private void cut() {
    _ot.cut_selected_node();
  }

  /* Pastes the given node as a sibling of the selected node */
  private void paste() {
    OutlinerClipboard.paste( _ot, false );
  }

  /* Pastes the given node as a sibling of the selected node */
  private void paste_replace() {
    OutlinerClipboard.paste( _ot, true );
  }

  /* Clones the currently selected node */
  private void clone_copy() {
    _ot.clone_node( _ot.selected );
  }

  /* Pastes the given clone within the currently selected node */
  private void clone_paste() {
    _ot.paste_clone( true );
  }

  /* Unclones the currently selected node */
  private void unclone() {
    _ot.unclone_node( _ot.selected );
  }

  /* Deletes the currently selected node */
  private void delete_node() {
    _ot.delete_current_node();
  }

  /* Edit the current node's name field */
  private void edit_text() {
    _ot.edit_selected( true );
  }

  /* Edit the current node's note field */
  private void edit_note() {
    _ot.edit_selected( false );
  }

  private void add_tag() {
    _ot.tagger.show_add_ui();
  }

  /* Toggles the note display status of the currently selected node */
  private void toggle_note() {
    _ot.toggle_note( _ot.selected, false );
  }

  /* Adds a new row above the currently selected row */
  private void add_row_above() {
    _ot.add_sibling_node( false );
  }

  /* Adds a new row below the currently selected row */
  private void add_row_below() {
    _ot.add_sibling_node( true );
  }

  /* Joins the current row to the one above it */
  private void join_row() {
    _ot.join_row();
  }

  /* Indents the currently selected row by one level */
  private void indent() {
    _ot.indent();
  }

  /* Unindents the currently selected row by one level */
  private void unindent() {
    _ot.unindent();
  }

  /* Toggles the expand/collapse property of the node */
  private void toggle_expand() {
    _ot.toggle_expand( _ot.selected );
  }

  /* Enters focus mode */
  private void focus_mode_enter() {
    _ot.focus_on_selected();
  }

  /* Selects the node just above the selected node */
  private void select_node_above() {
    _ot.change_selected( _ot.selected.get_previous_node() );
  }

  /* Selects the node just below the selected node */
  private void select_node_below() {
    _ot.change_selected( _ot.selected.get_next_node() );
  }

  /* Selects the previous sibling node relative to the selected node */
  private void select_prev_sibling_node() {
    _ot.change_selected( _ot.selected.get_previous_sibling() );
  }

  /* Selects the next sibling node relative to the selected node */
  private void select_next_sibling_node() {
    _ot.change_selected( _ot.selected.get_next_sibling() );
  }

  /* Selects the parent node of the selected node */
  private void select_parent_node() {
    _ot.change_selected( _ot.selected.parent );
  }

  /* Selects the last child node of the selected node */
  private void select_last_child_node() {
    _ot.change_selected( _ot.selected.get_last_child() );
  }

  /* Selects the top-most node of the document */
  private void select_first_node() {
    _ot.change_selected( _ot.root.get_first_node() );
  }

  /* Selects the bottom-most node of the document */
  private void select_last_node() {
    _ot.change_selected( _ot.root.get_last_node() );
  }

  /* Adds a label to the currently selected node */
  private void toggle_label() {
    _ot.toggle_label();
  }

  /* Selects the given label index */
  private void select_label( int index ) {
    _ot.goto_label( index );
  }

  /* Clears all of the set labels */
  private void clear_all_labels() {
    _ot.clear_all_labels();
  }

}
