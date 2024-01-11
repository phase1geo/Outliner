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

public class NodeMenu : Gtk.PopoverMenu {

  private OutlineTable _ot;

  private const GLib.ActionEntry action_entries[] = {
    { "action_clone_copy",               action_clone_copy },
    { "action_clone_paste",              action_clone_paste },
    { "action_unclone",                  action_unclone },
    { "action_copy",                     action_copy },
    { "action_cut",                      action_cut },
    { "action_paste",                    action_paste },
    { "action_paste_replace",            action_paste_replace },
    { "action_delete_node",              action_delete_node },
    { "action_edit_text",                action_edit_text },
    { "action_edit_note",                action_edit_note },
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
  };

  public NodeMenu( Gtk.Application app, OutlineTable ot ) {

    _ot = ot;

    var clone1_menu = new GLib.Menu();
    clone1_menu.append( _( "Copy As Clone" ), "node.action_clone_copy" );
    clone1_menu.append( _( "Paste Clone" ),   "node.action_clone_paste" );

    var clone2_menu = new GLib.Menu();
    clone2_menu.append( _( "Unclone" ), "node.action_unclone" );

    var clone_menu = new GLib.Menu();
    clone_menu.add_section( null, clone1_menu );
    clone_menu.add_section( null, clone2_menu );

    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Copy" ),              "node.action_copy" );
    edit_menu.append( _( "Cut" ),               "node.action_cut" );
    edit_menu.append( _( "Paste" ),             "node.action_paste" );
    edit_menu.append( _( "Paste and Replace" ), "node.action_paste_replace" );
    edit_menu.append_submenu( _( "Clone" ),     clone_menu );
    edit_menu.append( _( "Delete" ),            "node.action_delete_node" );

    var node_menu = new GLib.Menu();
    node_menu.append( _( "Edit Text" ),              "node.action_edit_text" );
    node_menu.append( _( "Edit Note" ),              "node.action_edit_note" );
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

    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, node_menu );
    menu.append_section( null, tree_menu );
    menu.append_section( null, add_menu );
    menu.append_section( null, target_menu );

    /* Populate the select and move label submenus */
    for( int i=0; i<9; i++ ) {

      var lbl_value  = i + 1;
      var index      = i;
      var move_name  = _( "Label-%d" ).printf( lbl_value );
      var move_accel = "<Control>%d".printf( lbl_value );
      var sel_name   = _( "Label-%d" ).printf( lbl_value );
      var sel_accel  = "%d".printf( lbl_value );

      select_label_menu.append( sel_name, "node.action_select_label('%s')".printf( index.to_string() ) );
      move_label_menu.append( move_name, "node.action_move_to_label('%s')".printf( index.to_string() ) );

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

    base.from_model( menu );

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "node", actions );

    /* Add keyboard shortcuts */
    app.set_accels_for_action( "node.action_copy",                     { "<Control>c" } );
    app.set_accels_for_action( "node.action_cut",                      { "<Control>x" } );
    app.set_accels_for_action( "node.action_paste",                    { "<Control>v" } );
    app.set_accels_for_action( "node.action_paste_replace",            { "<Control><Shift>v" } );
    app.set_accels_for_action( "node.action_delete_node",              { "Delete" } );
    app.set_accels_for_action( "node.action_edit_text",                { "e" } );
    app.set_accels_for_action( "node.action_edit_note",                { "<Shift>e" } );
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

  }

  /* Called when the menu is popped up */
  public void show_menu( double x, double y ) {

    var pasteable  = OutlinerClipboard.node_pasteable();
    var first_node = _ot.root.get_first_node();

    /* Set the menu sensitivity */
    action_set_enabled( "node.action_paste",                    pasteable );
    action_set_enabled( "node.action_paste_replace",            pasteable );
    action_set_enabled( "node.action_unclone",                  _ot.selected.is_clone() );
    action_set_enabled( "node.action_clone_paste",              _ot.cloneable() );
    action_set_enabled( "node.action_indent",                   _ot.indentable() );
    action_set_enabled( "node.action_unindent",                 _ot.unindentable() );
    action_set_enabled( "node.action_select_node_above",        (_ot.selected.get_previous_node() != null) );
    action_set_enabled( "node.action_select_node_below",        (_ot.selected.get_next_node() != null) );
    action_set_enabled( "node.action_select_prev_sibling_node", (_ot.selected.get_previous_sibling() != null) );
    action_set_enabled( "node.action_select_next_sibling_node", (_ot.selected.get_next_sibling() != null) );
    action_set_enabled( "node.action_select_parent_node",       !_ot.selected.parent.is_root() );
    action_set_enabled( "node.action_select_last_child_node",   !_ot.selected.is_leaf() );
    action_set_enabled( "node.action_select_first_node",        ((first_node != _ot.selected) && !first_node.is_root()) );
    action_set_enabled( "node.action_select_last_node",         ((_ot.root.get_last_node() != _ot.selected) && !first_node.is_root()) );
    action_set_enabled( "node.action_join_row",                 _ot.is_node_joinable() );
    action_set_enabled( "node.action_toggle_expand",            (_ot.selected.children.length > 0) );

    if( _ot.labels.get_label_for_node( _ot.selected ) == -1 ) {
      action_set_enabled( "node.action_toggle_label", _ot.labels.label_available() );
    } else {
      action_set_enabled( "node.action_toggle_label", true );
    }

    for( int i=0; i<9; i++ ) {
      var node = _ot.labels.get_node( i );
      action_set_enabled( "node.action_move_to_label('%s')".printf( i ), (node != null) );
      action_set_enabled( "node.action_select_label('%s')".printf( i ),  (node != null) );
    }

    if( _ot.selected.hide_note ) {
      action_set_enabled( "node.action_toggle_note", (_ot.selected.note.text.text != "") );
    } else {
      action_set_enabled( "node.action_toggle_note", true );
    }

    /* Display the menu */
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    pointing_to = rect;
    popup();

  }

  /* Copies the currently selected node */
  private void action_copy() {
    _ot.copy_selected_node();
  }

  /* Cuts the currently selected node */
  private void action_cut() {
    _ot.cut_selected_node();
  }

  /* Pastes the given node as a sibling of the selected node */
  private void action_paste() {
    OutlinerClipboard.paste( _ot, false );
  }

  /* Pastes the given node as a sibling of the selected node */
  private void action_paste_replace() {
    OutlinerClipboard.paste( _ot, true );
  }

  /* Clones the currently selected node */
  private void action_clone_copy() {
    _ot.clone_node( _ot.selected );
  }

  /* Pastes the given clone within the currently selected node */
  private void action_clone_paste() {
    _ot.paste_clone( true );
  }

  /* Unclones the currently selected node */
  private void action_unclone() {
    _ot.unclone_node( _ot.selected );
  }

  /* Deletes the currently selected node */
  private void action_delete_node() {
    _ot.delete_current_node();
  }

  /* Edit the current node's name field */
  private void action_edit_text() {
    _ot.edit_selected( true );
  }

  /* Edit the current node's note field */
  private void action_edit_note() {
    _ot.edit_selected( false );
  }

  private void action_add_tag() {
    _ot.tagger.show_add_ui();
  }

  /* Toggles the note display status of the currently selected node */
  private void action_toggle_note() {
    _ot.toggle_note( _ot.selected, false );
  }

  /* Adds a new row above the currently selected row */
  private void action_add_row_above() {
    _ot.add_sibling_node( false );
  }

  /* Adds a new row below the currently selected row */
  private void action_add_row_below() {
    _ot.add_sibling_node( true );
  }

  /* Joins the current row to the one above it */
  private void action_join_row() {
    _ot.join_row();
  }

  /* Indents the currently selected row by one level */
  private void action_indent() {
    _ot.indent();
  }

  /* Unindents the currently selected row by one level */
  private void action_unindent() {
    _ot.unindent();
  }

  /* Toggles the expand/collapse property of the node */
  private void action_toggle_expand() {
    _ot.toggle_expand( _ot.selected );
  }

  /* Enters focus mode */
  private void action_focus() {
    _ot.focus_on_selected();
  }

  /* Selects the node just above the selected node */
  private void action_select_node_above() {
    _ot.change_selected( _ot.selected.get_previous_node() );
  }

  /* Selects the node just below the selected node */
  private void action_select_node_below() {
    _ot.change_selected( _ot.selected.get_next_node() );
  }

  /* Selects the previous sibling node relative to the selected node */
  private void action_select_prev_sibling_node() {
    _ot.change_selected( _ot.selected.get_previous_sibling() );
  }

  /* Selects the next sibling node relative to the selected node */
  private void action_select_next_sibling_node() {
    _ot.change_selected( _ot.selected.get_next_sibling() );
  }

  /* Selects the parent node of the selected node */
  private void action_select_parent_node() {
    _ot.change_selected( _ot.selected.parent );
  }

  /* Selects the last child node of the selected node */
  private void action_select_last_child_node() {
    _ot.change_selected( _ot.selected.get_last_child() );
  }

  /* Selects the top-most node of the document */
  private void action_select_first_node() {
    _ot.change_selected( _ot.root.get_first_node() );
  }

  /* Selects the bottom-most node of the document */
  private void action_select_last_node() {
    _ot.change_selected( _ot.root.get_last_node() );
  }

  /* Adds a label to the currently selected node */
  private void action_toggle_label() {
    _ot.toggle_label();
  }

  /* Selects the given label index */
  private void action_select_label( SimpleAction action, Variant? variant ) {
    var index = int.parse( variant.get_string() );
    _ot.goto_label( index );
  }

  /* Clears all of the set labels */
  private void action_clear_all_labels() {
    _ot.clear_all_labels();
  }

}
