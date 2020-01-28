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
  private Gtk.MenuItem _delete;

  public NodeMenu( OutlineTable ot ) {

    _ot = ot;

    _copy = new Gtk.MenuItem.with_label( _( "Copy" ) );
    _copy.activate.connect( copy );
    Utils.add_accel_label( _copy, 'c', Gdk.ModifierType.CONTROL_MASK );

    _cut = new Gtk.MenuItem.with_label( _( "Cut" ) );
    _cut.activate.connect( cut );
    Utils.add_accel_label( _cut, 'x', Gdk.ModifierType.CONTROL_MASK );

    _paste = new Gtk.MenuItem.with_label( _( "Paste" ) );
    _paste.activate.connect( paste );
    Utils.add_accel_label( _paste, 'v', Gdk.ModifierType.CONTROL_MASK );

    _delete = new Gtk.MenuItem.with_label( _( "Delete" ) );
    _delete.activate.connect( delete_node );
    Utils.add_accel_label( _delete, 65535, 0 );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste );
    add( _delete );
    add( new SeparatorMenuItem() );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Called when the menu is popped up */
  private void on_popup() {

    /* Set the menu sensitivity */
    _paste.set_sensitive( _ot.node_clipboard.wait_is_text_available() );

  }

  /* Copies the currently selected node */
  private void copy() {
    _ot.copy_node_to_clipboard( _ot.selected );
  }

  /* Cuts the currently selected node */
  private void cut() {
    _ot.cut_node_to_clipboard( _ot.selected );
  }

  /* Pastes the given node as a sibling of the selected node */
  private void paste() {
    _ot.paste_node();
  }

  /* Deletes the currently selected node */
  private void delete_node() {
    _ot.delete_current_node();
  }

}
