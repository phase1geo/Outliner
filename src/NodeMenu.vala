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

public class NodeMenu : BaseMenu {

  private const GLib.ActionEntry action_entries[] = {
    { "action_clone_copy",               action_clone_copy },
    { "action_clone_paste",              action_clone_paste },
    { "action_unclone",                  action_unclone },
    { "action_paste_replace",            action_paste_replace },
    { "action_delete_node",              action_delete_node },
    { "action_toggle_note",              action_toggle_note },
    { "action_add_tag",                  action_add_tag },
    { "action_indent",                   action_indent },
    { "action_unindent",                 action_unindent },
    { "action_toggle_expand",            action_toggle_expand },
    { "action_focus",                    action_focus },
    { "action_add_row_above",            action_add_row_above },
    { "action_add_row_below",            action_add_row_below },
    { "action_join_row",                 action_join_row },
    { "action_select_node_above",        action_select_node_above },
    { "action_select_node_below",        action_select_node_below },
    { "action_select_prev_sibling_node", action_select_prev_sibling_node },
    { "action_select_next_sibling_node", action_select_next_sibling_node },
    { "action_select_parent_node",       action_select_parent_node },
    { "action_select_last_child_node",   action_select_last_child_node },
    { "action_select_first_node",        action_select_first_node },
    { "action_select_last_node",         action_select_last_node },
    { "action_select_label",             action_select_label, "s" },
    { "action_move_to_label",            action_move_to_label, "s" },
  };

  /* Constructor */
  public NodeMenu( Gtk.Application app, OutlineTable ot ) {

    base( app, ot, "node-tmp" );

    var clone1_menu = new GLib.Menu();
    clone1_menu.append( _( "Copy As Clone" ), "node.action_clone_copy" );
    clone1_menu.append( _( "Paste Clone" ),   "node.action_clone_paste" );

    var clone2_menu = new GLib.Menu();
    clone2_menu.append( _( "Unclone" ), "node.action_unclone" );

    var clone_menu = new GLib.Menu();
    clone_menu.append_section( null, clone1_menu );
    clone_menu.append_section( null, clone2_menu );

    var edit_menu = new GLib.Menu();
    append_menu_item( edit_menu, KeyCommand.EDIT_COPY,  _( "Copy" ) );
    append_menu_item( edit_menu, KeyCommand.EDIT_CUT,   _( "Cut" ) );
    append_menu_item( edit_menu, KeyCommand.EDIT_PASTE, _( "Paste" ) );

    edit_menu.append( _( "Paste and Replace" ), "node.action_paste_replace" );
    edit_menu.append_submenu( _( "Clone" ),     clone_menu );
    edit_menu.append( _( "Delete" ),            "node.action_delete_node" );

    var node_menu = new GLib.Menu();
    append_menu_item( node_menu, KeyCommand.EDIT_SELECTED, _( "Edit Text" ) );
    append_menu_item( node_menu, KeyCommand.EDIT_NOTE,     _( "Edit Note" ) );
    node_menu.append( _( "Toggle Note Visibility" ), "node.action_toggle_note" );
    node_menu.append( _( "Add Tag" ),                "node.action_add_tag" );

    var tree_menu = new GLib.Menu();
    tree_menu.append( _( "Indent" ),                     "node.action_indent" );
    tree_menu.append( _( "Unindent" ),                   "node.action_unindent" );
    tree_menu.append( _( "Toggle Children Visibility" ), "node.action_toggle_expand" );
    tree_menu.append( _( "Focus" ),                      "node.action_focus" );

    var add_menu = new GLib.Menu();
    add_menu.append( _( "Add Row Above" ),     "node.action_add_row_above" );
    add_menu.append( _( "Add Row Below" ),     "node.action_add_row_below" );
    add_menu.append( _( "Join To Row Above" ), "node.action_join_row" );

    var select1_menu = new GLib.Menu();
    select1_menu.append( _( "Select Row Above" ), "node.action_select_node_above" );
    select1_menu.append( _( "Select Row Below" ), "node.action_select_node_below" );

    var select2_menu = new GLib.Menu();
    select2_menu.append( _( "Select Previous Sibling Row" ), "node.action_select_prev_sibling_node" );
    select2_menu.append( _( "Select Next Sibling Row" ),     "node.action_select_next_sibling_node" );

    var select3_menu = new GLib.Menu();
    select3_menu.append( _( "Select Parent Row" ), "node.action_select_parent_node" );
    select3_menu.append( _( "Select Last Child" ), "node.action_select_last_child_node" );

    var select4_menu = new GLib.Menu();
    select4_menu.append( _( "Select First Row" ), "node.action_select_first_node" );
    select4_menu.append( _( "Select Last Row" ),  "node.action_select_last_node" );

    // These will be populated a bit later
    var select_label_menu = new GLib.Menu();
    var move_label_menu = new GLib.Menu();

    var select5_menu = new GLib.Menu();
    select5_menu.append_submenu( _( "Select Labeled Row" ), select_label_menu );

    var select_menu = new GLib.Menu();
    select_menu.append_section( null, select1_menu );
    select_menu.append_section( null, select2_menu );
    select_menu.append_section( null, select3_menu );
    select_menu.append_section( null, select4_menu );
    select_menu.append_section( null, select5_menu );

    var label1_menu = new GLib.Menu();
    label1_menu.append( _( "Add Label" ), "node.action_toggle_label" );
    label1_menu.append_submenu( _( "Move To Label" ), move_label_menu );

    var label2_menu = new GLib.Menu();
    label2_menu.append( _( "Clear All Labels" ), "node.action_clear_all_labels" );

    var label_menu = new GLib.Menu();
    label_menu.append_section( null, label1_menu );
    label_menu.append_section( null, label2_menu );

    var target_menu = new GLib.Menu();
    target_menu.append_submenu( _( "Select Row" ), select_menu );
    target_menu.append_submenu( _( "Labels" ),     label_menu );

    /* Add all of the submenus to ourself */
    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, node_menu );
    menu.append_section( null, tree_menu );
    menu.append_section( null, add_menu );
    menu.append_section( null, target_menu );

    /* Populate the select and move label submenus */
    for( int i=0; i<9; i++ ) {

      var name = _( "Label-%d" ).printf( i + 1 );

      select_label_menu.append( name, "node.action_select_label('%d')".printf( i ) );
      move_label_menu.append( name, "node.action_move_to_label('%d')".printf( i ) );

    }

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    ot.insert_action_group( "node", actions );

    /* Add keyboard shortcuts */
    app.set_accels_for_action( "node.action_paste_replace",            { "<Control><Shift>v" } );
    app.set_accels_for_action( "node.action_delete_node",              { "Delete" } );
    app.set_accels_for_action( "node.action_indent",                   { "Tab" } );
    app.set_accels_for_action( "node.action_unindent",                 { "<Shift>Tab" } );
    app.set_accels_for_action( "node.action_focus",                    { "f" } );
    app.set_accels_for_action( "node.action_add_row_above",            { "<Shift>Return" } );
    app.set_accels_for_action( "node.action_add_row_below",            { "Return" } );
    app.set_accels_for_action( "node.action_join_row",                 { "<Control>BackSpace" } );
    app.set_accels_for_action( "node.action_select_node_above",        { "Up" } );
    app.set_accels_for_action( "node.action_select_node_below",        { "Down" } );
    app.set_accels_for_action( "node.action_select_prev_sibling_node", { "<Shift>Up" } );
    app.set_accels_for_action( "node.action_select_next_sibling_node", { "<Shift>Down" } );
    app.set_accels_for_action( "node.action_select_parent_node",       { "a" } );
    app.set_accels_for_action( "node.action_select_last_child_node",   { "c" } );
    app.set_accels_for_action( "node.action_select_first_node",        { "<Shift>t" } );
    app.set_accels_for_action( "node.action_select_last_node",         { "<Shift>b" } );
    app.set_accels_for_action( "node.action_toggle_label",             { "numbersign" } );
    
    for( int i=0; i<9; i++ ) {
      app.set_accels_for_action( "node.action_select_label('%d')".printf( i ), { "%d".printf( i + 1 ) } );
      app.set_accels_for_action( "node.action_move_to_label('%d')".printf( i ), { "<control>%d".printf( i + 1 ) } );
    }

  }

  /* Called when the menu is popped up */
  protected override void on_popup() {

    var pasteable  = OutlinerClipboard.node_pasteable();
    var first_node = ot.root.get_first_node();

    /* Set the menu sensitivity */
    set_enabled( KeyCommand.EDIT_PASTE,                  pasteable );
    ot.action_set_enabled( "node.action_paste_replace",            pasteable );
    ot.action_set_enabled( "node.action_unclone",                  ot.selected.is_clone() );
    ot.action_set_enabled( "node.action_clone_paste",              ot.cloneable() );
    ot.action_set_enabled( "node.action_indent",                   ot.indentable() );
    ot.action_set_enabled( "node.action_unindent",                 ot.unindentable() );
    ot.action_set_enabled( "node.action_select_node_above",        (ot.selected.get_previous_node() != null) );
    ot.action_set_enabled( "node.action_select_node_below",        (ot.selected.get_next_node() != null) );
    ot.action_set_enabled( "node.action_select_prev_sibling_node", (ot.selected.get_previous_sibling() != null) );
    ot.action_set_enabled( "node.action_select_next_sibling_node", (ot.selected.get_next_sibling() != null) );
    ot.action_set_enabled( "node.action_select_parent_node",       !ot.selected.parent.is_root() );
    ot.action_set_enabled( "node.action_select_last_child_node",   !ot.selected.is_leaf() );
    ot.action_set_enabled( "node.action_select_first_node",        ((first_node != ot.selected) && !first_node.is_root()) );
    ot.action_set_enabled( "node.action_select_last_node",         ((ot.root.get_last_node() != ot.selected) && !first_node.is_root()) );
    ot.action_set_enabled( "node.action_join_row",                 ot.is_node_joinable() );
    ot.action_set_enabled( "node.action_toggle_expand",            (ot.selected.children.length > 0) );

    if( ot.labels.get_label_for_node( ot.selected ) == -1 ) {
      ot.action_set_enabled( "node.action_toggle_label", ot.labels.label_available() );
    } else {
      ot.action_set_enabled( "node.action_toggle_label", true );
    }

    for( int i=0; i<9; i++ ) {
      var node = ot.labels.get_node( i );
      ot.action_set_enabled( "node.action_move_to_label('%d')".printf( i ), (node != null) );
      ot.action_set_enabled( "node.action_select_label('%d')".printf( i ),  (node != null) );
    }

    if( ot.selected.hide_note ) {
      ot.action_set_enabled( "node.action_toggle_note", (ot.selected.note.text.text != "") );
    } else {
      ot.action_set_enabled( "node.action_toggle_note", true );
    }

  }

  /* Pastes the given node as a sibling of the selected node */
  private void action_paste_replace() {
    OutlinerClipboard.paste( ot, true );
  }

  /* Clones the currently selected node */
  private void action_clone_copy() {
    ot.clone_node( ot.selected );
  }

  /* Pastes the given clone within the currently selected node */
  private void action_clone_paste() {
    ot.paste_clone( true );
  }

  /* Unclones the currently selected node */
  private void action_unclone() {
    ot.unclone_node( ot.selected );
  }

  /* Deletes the currently selected node */
  private void action_delete_node() {
    ot.delete_current_node();
  }

  private void action_add_tag() {
    ot.tagger.show_add_ui();
  }

  /* Toggles the note display status of the currently selected node */
  private void action_toggle_note() {
    ot.toggle_note( ot.selected, false );
  }

  /* Adds a new row above the currently selected row */
  private void action_add_row_above() {
    ot.add_sibling_node( false );
  }

  /* Adds a new row below the currently selected row */
  private void action_add_row_below() {
    ot.add_sibling_node( true );
  }

  /* Joins the current row to the one above it */
  private void action_join_row() {
    ot.join_row();
  }

  /* Indents the currently selected row by one level */
  private void action_indent() {
    ot.indent();
  }

  /* Unindents the currently selected row by one level */
  private void action_unindent() {
    ot.unindent();
  }

  /* Toggles the expand/collapse property of the node */
  private void action_toggle_expand() {
    ot.toggle_expand( ot.selected );
  }

  /* Enters focus mode */
  private void action_focus() {
    ot.focus_on_selected();
  }

  /* Selects the node just above the selected node */
  private void action_select_node_above() {
    ot.change_selected( ot.selected.get_previous_node() );
  }

  /* Selects the node just below the selected node */
  private void action_select_node_below() {
    ot.change_selected( ot.selected.get_next_node() );
  }

  /* Selects the previous sibling node relative to the selected node */
  private void action_select_prev_sibling_node() {
    ot.change_selected( ot.selected.get_previous_sibling() );
  }

  /* Selects the next sibling node relative to the selected node */
  private void action_select_next_sibling_node() {
    ot.change_selected( ot.selected.get_next_sibling() );
  }

  /* Selects the parent node of the selected node */
  private void action_select_parent_node() {
    ot.change_selected( ot.selected.parent );
  }

  /* Selects the last child node of the selected node */
  private void action_select_last_child_node() {
    ot.change_selected( ot.selected.get_last_child() );
  }

  /* Selects the top-most node of the document */
  private void action_select_first_node() {
    ot.change_selected( ot.root.get_first_node() );
  }

  /* Selects the bottom-most node of the document */
  private void action_select_last_node() {
    ot.change_selected( ot.root.get_last_node() );
  }

  /* Adds a label to the currently selected node */
  private void action_toggle_label() {
    ot.toggle_label();
  }

  /* Selects the given label index */
  private void action_select_label( SimpleAction action, Variant? variant ) {
    var index = int.parse( variant.get_string() );
    ot.goto_label( index );
  }
  
  /* Moves the current row to the given label */
  private void action_move_to_label( SimpleAction action, Variant? variant ) {
    var index = int.parse( variant.get_string() );
    ot.handle_control_number( index );
  }

  /* Clears all of the set labels */
  private void action_clear_all_labels() {
    ot.clear_all_labels();
  }

}
