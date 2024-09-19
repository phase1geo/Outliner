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

using Gtk;

public class Exporter : Box {

  private MainWindow _win;
  private MenuButton _mb;
  private Revealer   _stack_reveal;
  private Stack      _stack;

  private const GLib.ActionEntry action_entries[] = {
    { "action_select_export", action_select_export, "s" },
  };

  public signal void export_done();

  /* Constructor */
  public Exporter( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    _win = win;

    /* Create the exporter dropdown menu */
    var menu = new GLib.Menu();
    for( int i=0; i<win.exports.length(); i++ ) {
      var export = win.exports.index( i );
      if( export.exportable ) {
        menu.append( export.label, "exporter.action_select_export('%s')".printf( export.name ) );
      }
    }

    _mb = new MenuButton() {
      halign = Align.START,
      hexpand = true,
      always_show_arrow = true,
      menu_model = menu
    };

    var export = new Button.with_label( _( "Export…" ) ) {
      halign = Align.END,
      tooltip_markup = Utils.tooltip_with_accel( _( "Export With Current Settings" ), "<Control>e" )
    };
    export.clicked.connect(() => {
      do_export();
      export_done();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( _mb );
    bbox.append( export );

    _stack = new Stack() {
      transition_type = StackTransitionType.NONE,
      hhomogeneous    = true,
      vhomogeneous    = false
    };

    _stack_reveal = new Revealer() {
      child = _stack
    };

    populate();

    append( bbox );
    append( _stack_reveal );

    /* Initialize the UI */
    select_export( win.settings.get_string( "last-export" ) );

    /* Add the menu actions */
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "exporter", actions );

  }

  /* Populates the exporter widget with the available export types */
  private void populate() {
    for( int i=0; i<_win.exports.length(); i++ ) {
      var export = _win.exports.index( i );
      if( export.exportable ) {
        add_export_options( export );
      }
    }
  }

  /* Selecting the export */
  private void select_export( string name ) {
    var export = _win.exports.get_by_name( name );
    if( export != null ) {
      _mb.label = export.label;
      _stack.visible_child_name = export.name;
      _stack_reveal.reveal_child = export.settings_available();
      _win.settings.set_string( "last-export", export.name );
    }
  }

  /* Menu action to select an export */
  private void action_select_export( SimpleAction action, Variant? variant ) {
    select_export( variant.get_string() );
  }

  /* Add the given export */
  private void add_export_options( Export export ) {

    /* Add the page */
    var opts = new Grid() {
      margin_start   = 5,
      margin_end     = 5,
      margin_top     = 5,
      margin_bottom  = 5,
      column_spacing = 5,
      hexpand        = true
    };

    export.add_settings( opts );

    var label = new Label( "<i>" + _( "Export Options" ) + "</i>" ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget  = label,
      label_xalign  = (float)0.5,
      margin_top    = 5,
      margin_bottom = 5,
      child = opts
    };

    /* Add the options to the options stack */
    _stack.add_named( frame, export.name );

  }

  /* Perform the export */
  public void do_export() {

    var name   = _stack.visible_child_name;
    var export = _win.exports.get_by_name( name );

    var dialog = new FileChooserDialog( _( "Export As %s" ).printf( export.label ), _win, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );
    Utils.set_chooser_folder( dialog );

    /* Set the default filename */
    var default_fname = Utils.rootname( _win.get_current_table().document.filename );
    dialog.set_current_name( _win.repair_filename( default_fname, export.extensions ) );

    /* Set the filter */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( export.label );
    foreach( string extension in export.extensions ) {
      filter.add_pattern( "*" + extension );
    }
    dialog.set_filter( filter );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {

        /* Close the dialog and parent window */
        dialog.hide();

        /* Perform the export */
        var fname = dialog.get_file().get_path();
        export.export( fname = _win.repair_filename( fname, export.extensions ), _win.get_current_table() );
        Utils.store_chooser_folder( fname, false );

        /* Generate notification to indicate that the export completed */
        _win.notification( _( "Minder Export Completed" ), fname );

      }
      dialog.destroy();
    });

    dialog.show();

  }

}


