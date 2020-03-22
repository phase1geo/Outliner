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
  private Gtk.MenuItem _paste_above;
  private Gtk.MenuItem _paste_below;
  private Gtk.MenuItem _delete;
  private Gtk.MenuItem _clone;
  private Gtk.MenuItem _unclone;
  private Gtk.MenuItem _paste_clone;
  private Gtk.MenuItem _edit_text;
  private Gtk.MenuItem _edit_note;
  private Gtk.MenuItem _note_display;
  private Gtk.MenuItem _add_above;
  private Gtk.MenuItem _add_below;
  private Gtk.MenuItem _indent;
  private Gtk.MenuItem _unindent;
  private Gtk.MenuItem _expander;

  public NodeMenu( OutlineTable ot ) {

    _ot = ot;

    _copy = new Gtk.MenuItem.with_label( _( "Copy" ) );
    _copy.activate.connect( copy );
    Utils.add_accel_label( _copy, 'c', Gdk.ModifierType.CONTROL_MASK );

    _cut = new Gtk.MenuItem.with_label( _( "Cut" ) );
    _cut.activate.connect( cut );
    Utils.add_accel_label( _cut, 'x', Gdk.ModifierType.CONTROL_MASK );

    _paste_above = new Gtk.MenuItem.with_label( _( "Paste Above" ) );
    _paste_above.activate.connect( paste_above );
    Utils.add_accel_label( _paste_above, 'v', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK) );

    _paste_below = new Gtk.MenuItem.with_label( _( "Paste Below" ) );
    _paste_below.activate.connect( paste_below );
    Utils.add_accel_label( _paste_below, 'v', Gdk.ModifierType.CONTROL_MASK );

    _delete = new Gtk.MenuItem.with_label( _( "Delete" ) );
    _delete.activate.connect( delete_node );
    Utils.add_accel_label( _delete, 65535, 0 );

    _clone = new Gtk.MenuItem.with_label( _( "Copy As Clone" ) );
    _clone.activate.connect( clone );

    _unclone = new Gtk.MenuItem.with_label( _( "Unclone" ) );
    _unclone.activate.connect( unclone );

    _paste_clone = new Gtk.MenuItem.with_label( _( "Paste Clone" ) );
    _paste_clone.activate.connect( paste_clone );

    _edit_text = new Gtk.MenuItem.with_label( _( "Edit Text" ) );
    _edit_text.activate.connect( edit_text );
    Utils.add_accel_label( _edit_text, 'e', 0 );

    _edit_note = new Gtk.MenuItem.with_label( _( "Edit Note" ) );
    _edit_note.activate.connect( edit_note );
    Utils.add_accel_label( _edit_note, 'e', Gdk.ModifierType.SHIFT_MASK );

    _note_display = new Gtk.MenuItem.with_label( _( "Show Note" ) );
    _note_display.activate.connect( toggle_note );

    _add_above = new Gtk.MenuItem.with_label( _( "Add Row Above" ) );
    _add_above.activate.connect( add_row_above );
    Utils.add_accel_label( _add_above, 65293, Gdk.ModifierType.SHIFT_MASK );

    _add_below = new Gtk.MenuItem.with_label( _( "Add Row Below" ) );
    _add_below.activate.connect( add_row_below );
    Utils.add_accel_label( _add_below, 65293, 0 );

    _indent = new Gtk.MenuItem.with_label( _( "Indent" ) );
    _indent.activate.connect( indent );
    Utils.add_accel_label( _indent, 65289, 0 );

    _unindent = new Gtk.MenuItem.with_label( _( "Unindent" ) );
    _unindent.activate.connect( unindent );
    Utils.add_accel_label( _unindent, 65289, Gdk.ModifierType.SHIFT_MASK );

    _expander = new Gtk.MenuItem.with_label( _( "Expand Children" ) );
    _expander.activate.connect( toggle_expand );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste_above );
    add( _paste_below );
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _clone );
    add( _unclone );
    add( _paste_clone );
    add( new SeparatorMenuItem() );
    add( _edit_text );
    add( _edit_note );
    add( _note_display );
    add( new SeparatorMenuItem() );
    add( _indent );
    add( _unindent );
    add( _expander );
    add( new SeparatorMenuItem() );
    add( _add_above );
    add( _add_below );


    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Called when the menu is popped up */
  private void on_popup() {

    var pasteable = _ot.node_clipboard.wait_is_text_available();

    /* Set the menu sensitivity */
    _paste_above.set_sensitive( pasteable );
    _paste_below.set_sensitive( pasteable );
    _unclone.set_sensitive( _ot.selected.is_clone() );
    _paste_clone.set_sensitive( _ot.cloneable() );
    _indent.set_sensitive( _ot.indentable() );
    _unindent.set_sensitive( _ot.unindentable() );

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
    _ot.copy_node_to_clipboard( _ot.selected );
  }

  /* Clones the currently selected node */
  private void clone() {
    _ot.clone_node( _ot.selected );
  }

  /* Unclones the currently selected node */
  private void unclone() {
    _ot.unclone_node( _ot.selected );
  }

  /* Cuts the currently selected node */
  private void cut() {
    _ot.cut_node_to_clipboard( _ot.selected );
  }

  /* Pastes the given node as a sibling of the selected node */
  private void paste_above() {
    _ot.paste_node( false );
  }

  /* Pastes the given node as a sibling of the selected node */
  private void paste_below() {
    _ot.paste_node( true );
  }

  /* Pastes the given clone within the currently selected node */
  private void paste_clone() {
    _ot.paste_clone( true );
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

}
