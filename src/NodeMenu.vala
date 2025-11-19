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
    { "action_delete_node",              action_delete_node },
    { "action_toggle_note",              action_toggle_note },
    { "action_add_tag",                  action_add_tag },
    { "action_toggle_expand",            action_toggle_expand },
    { "action_focus",                    action_focus },
    { "action_add_row_above",            action_add_row_above },
    { "action_add_row_below",            action_add_row_below },
    { "action_join_row",                 action_join_row },
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

    append_menu_item( edit_menu, KeyCommand.NODE_PASTE_REPLACE, _( "Paste and Replace" ) );
    edit_menu.append_submenu( _( "Clone" ),     clone_menu );
    edit_menu.append( _( "Delete" ),            "node.action_delete_node" );

    var node_menu = new GLib.Menu();
    append_menu_item( node_menu, KeyCommand.NODE_CHANGE_TEXT, _( "Edit Text" ) );
    append_menu_item( node_menu, KeyCommand.NODE_CHANGE_NOTE, _( "Edit Note" ) );
    node_menu.append( _( "Toggle Note Visibility" ), "node.action_toggle_note" );
    node_menu.append( _( "Add Tag" ),                "node.action_add_tag" );

    var tree_menu = new GLib.Menu();
    append_menu_item( tree_menu, KeyCommand.NODE_INDENT,   _( "Indent" ) );
    append_menu_item( tree_menu, KeyCommand.NODE_UNINDENT, _( "Unindent" ) );
    tree_menu.append( _( "Toggle Children Visibility" ), "node.action_toggle_expand" );
    tree_menu.append( _( "Focus" ),                      "node.action_focus" );

    var add_menu = new GLib.Menu();
    add_menu.append( _( "Add Row Above" ),     "node.action_add_row_above" );
    add_menu.append( _( "Add Row Below" ),     "node.action_add_row_below" );
    add_menu.append( _( "Join To Row Above" ), "node.action_join_row" );

    var select1_menu = new GLib.Menu();
    append_menu_item( select1_menu, KeyCommand.NODE_SELECT_UP,   _( "Select Row Above" ) );
    append_menu_item( select1_menu, KeyCommand.NODE_SELECT_DOWN, _( "Select Row Below" ) );

    var select2_menu = new GLib.Menu();
    append_menu_item( select2_menu, KeyCommand.NODE_SELECT_PREV_SIBLING, _( "Select Previous Sibling Row" ) );
    append_menu_item( select2_menu, KeyCommand.NODE_SELECT_NEXT_SIBLING, _( "Select Next Sibling Row" ) );

    var select3_menu = new GLib.Menu();
    append_menu_item( select3_menu, KeyCommand.NODE_SELECT_PARENT,     _( "Select Parent Row" ) );
    append_menu_item( select3_menu, KeyCommand.NODE_SELECT_LAST_CHILD, _( "Select Last Child Row" ) );

    var select4_menu = new GLib.Menu();
    append_menu_item( select4_menu, KeyCommand.NODE_SELECT_TOP,    _( "Select First Row" ) );
    append_menu_item( select4_menu, KeyCommand.NODE_SELECT_BOTTOM, _( "Select Last Row" ) );

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
    append_menu_item( label1_menu, KeyCommand.NODE_LABEL_TOGGLE, _( "Add Label" ) );
    label1_menu.append_submenu( _( "Move To Label" ), move_label_menu );

    var label2_menu = new GLib.Menu();
    append_menu_item( label2_menu, KeyCommand.NODE_LABEL_CLEAR_ALL, _( "Clear All Labels" ) );

    var label_menu = new GLib.Menu();
    label_menu.append_section( null, label1_menu );
    label_menu.append_section( null, label2_menu );

    var target_menu = new GLib.Menu();
    target_menu.append_submenu( _( "Select Row" ), select_menu );
    target_menu.append_submenu( _( "Labels" ),     label_menu );

    /* Add all of the submenus to ourself */
    menu.append_section( null, edit_menu );
    menu.append_section( null, node_menu );
    menu.append_section( null, tree_menu );
    menu.append_section( null, add_menu );
    menu.append_section( null, target_menu );

    /* Populate the select and move label submenus */
    for( int i=0; i<9; i++ ) {

      var name = _( "Label-%d" ).printf( i + 1 );
      var goto = (KeyCommand)(KeyCommand.NODE_LABEL_GOTO_1 + i);
      var move = (KeyCommand)(KeyCommand.NODE_MOVE_TO_LABEL_1 + i);

      append_menu_item( select_label_menu, goto, name );
      append_menu_item( move_label_menu,   move, name );

    }

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    ot.insert_action_group( "node", actions );

  }

  /* Called when the menu is popped up */
  protected override void on_popup() {

    var pasteable  = OutlinerClipboard.node_pasteable();
    var first_node = ot.root.get_first_node();

    /* Set the menu sensitivity */
    set_enabled( KeyCommand.EDIT_PASTE,                  pasteable );
    set_enabled( KeyCommand.NODE_PASTE_REPLACE,          pasteable );
    ot.action_set_enabled( "node.action_unclone",                  ot.selected.is_clone() );
    ot.action_set_enabled( "node.action_clone_paste",              ot.cloneable() );
    set_enabled( KeyCommand.NODE_INDENT,                 ot.indentable() );
    set_enabled( KeyCommand.NODE_UNINDENT,               ot.unindentable() );
    set_enabled( KeyCommand.NODE_SELECT_UP,              (ot.selected.get_previous_node() != null) );
    set_enabled( KeyCommand.NODE_SELECT_DOWN,            (ot.selected.get_next_node() != null) );
    set_enabled( KeyCommand.NODE_SELECT_PREV_SIBLING,    (ot.selected.get_previous_sibling() != null ) );
    set_enabled( KeyCommand.NODE_SELECT_NEXT_SIBLING,    (ot.selected.get_next_sibling() != null ) );
    set_enabled( KeyCommand.NODE_SELECT_PARENT,          !ot.selected.parent.is_root() );
    set_enabled( KeyCommand.NODE_SELECT_LAST_CHILD,      !ot.selected.is_leaf() );
    set_enabled( KeyCommand.NODE_SELECT_TOP,             ((first_node != ot.selected) && !first_node.is_root()) );
    set_enabled( KeyCommand.NODE_SELECT_BOTTOM,          ((ot.root.get_last_node() != ot.selected) && !first_node.is_root()) );
    ot.action_set_enabled( "node.action_join_row",                 ot.is_node_joinable() );
    ot.action_set_enabled( "node.action_toggle_expand",            (ot.selected.children.length > 0) );

    if( ot.labels.get_label_for_node( ot.selected ) == -1 ) {
      set_enabled( KeyCommand.NODE_LABEL_TOGGLE, ot.labels.label_available() );
    } else {
      set_enabled( KeyCommand.NODE_LABEL_TOGGLE, true );
    }

    for( int i=0; i<9; i++ ) {
      var node = ot.labels.get_node( i );
      var goto = (KeyCommand)(KeyCommand.NODE_LABEL_GOTO_1 + i);
      var move = (KeyCommand)(KeyCommand.NODE_MOVE_TO_LABEL_1 + i);
      set_enabled( move, (node != null) );
      set_enabled( goto, (node != null) );
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

  /* Toggles the expand/collapse property of the node */
  private void action_toggle_expand() {
    ot.toggle_expand( ot.selected );
  }

  /* Enters focus mode */
  private void action_focus() {
    ot.focus_on_selected();
  }

}
