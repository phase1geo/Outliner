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
using Gee;

public enum TabAddReason {
  NEW,
  OPEN,
  IMPORT,
  LOAD
}

public class MainWindow : ApplicationWindow {

  private const string DESKTOP_SCHEMA = "io.elementary.desktop";
  private const string DARK_KEY       = "prefer-dark";

  private GLib.Settings   _settings;
  private HeaderBar?      _header         = null;
  private DynamicNotebook _nb;
  private Button          _search_btn;
  private Popover?        _export         = null;
  private Button?         _undo_btn       = null;
  private Button?         _redo_btn       = null;
  private SpinButton      _zoom;
  private bool            _debug          = false;
  private bool            _prefer_dark    = false;
  private HashMap<string,RadioButton> _theme_buttons;

  public static Themes themes = new Themes();

  private const GLib.ActionEntry[] action_entries = {
    { "action_new",           action_new },
    { "action_open",          action_open },
    { "action_save",          action_save },
    { "action_save_as",       action_save_as },
    { "action_undo",          action_undo },
    { "action_redo",          action_redo },
    { "action_search",        action_search },
    { "action_quit",          action_quit },
    { "action_export",        action_export },
    { "action_print",         action_print }
  };

  private delegate void ChangedFunc();

  public signal void canvas_changed( OutlineTable? ot );

  /* Create the main window UI */
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings = settings;

    /* Initialize variables */
    _theme_buttons = new HashMap<string,RadioButton>();

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    var window_x = settings.get_int( "window-x" );
    var window_y = settings.get_int( "window-y" );
    var window_w = settings.get_int( "window-w" );
    var window_h = settings.get_int( "window-h" );

    /* Add the theme CSS */
    themes.add_css();

    /* Create the header bar */
    _header = new HeaderBar();
    _header.set_show_close_button( true );

    /* Set the main window data */
    title = _( "Outliner" );
    if( (window_x == -1) && (window_y == -1) ) {
      set_position( Gtk.WindowPosition.CENTER );
    } else {
      move( window_x, window_y );
    }
    set_default_size( window_w, window_h );
    set_titlebar( _header );
    set_border_width( 2 );
    destroy.connect( Gtk.main_quit );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    _nb = new DynamicNotebook();
    _nb.add_button_visible = false;
    _nb.tab_bar_behavior   = DynamicNotebook.TabBarBehavior.SINGLE;
    _nb.tab_switched.connect( tab_switched );
    _nb.tab_reordered.connect( tab_reordered );
    _nb.tab_removed.connect( tab_removed );
    _nb.close_tab_requested.connect( close_tab_requested );

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( "document-new", IconSize.LARGE_TOOLBAR );
    new_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "New File" ), "Ctrl + N" ) );
    new_btn.clicked.connect( do_new_file );
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( "document-open", IconSize.LARGE_TOOLBAR );
    open_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Open File" ), "Ctrl + O" ) );
    open_btn.clicked.connect( do_open_file );
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( "document-save-as", IconSize.LARGE_TOOLBAR );
    save_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Save File As" ), "Ctrl + Shift + S" ) );
    save_btn.clicked.connect( do_save_as_file );
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( "edit-undo", IconSize.LARGE_TOOLBAR );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Undo" ), "Ctrl + Z" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( "edit-redo", IconSize.LARGE_TOOLBAR );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Redo" ), "Ctrl + Shift + Z" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    /* Add the buttons on the right side in the reverse order */
    add_properties_button();
    add_export_button();
    add_search_button();

    /* Display the UI */
    add( _nb );
    show_all();

  }

  /* Returns the OutlineTable from the given tab */
  private OutlineTable? get_table( Tab tab ) {
    var box  = tab.page as Gtk.Box;
    var bin1 = box.get_children().nth_data( 1 ) as Gtk.ScrolledWindow;
    var bin2 = bin1.get_child() as Gtk.Bin;  // Viewport
    var bin3 = bin2.get_child() as Gtk.Bin;  // Overlay
    return( bin3.get_child() as OutlineTable );
  }

  /* Returns the current drawing area */
  public OutlineTable? get_current_table( string? caller = null ) {
    if( _debug && (caller != null) ) {
      stdout.printf( "get_current_table called from %s\n", caller );
    }
    if( _nb.current == null ) { return( null ); }
    return( get_table( _nb.current ) );
  }

  /* Shows or hides the search bar for the current tab */
  private void toggle_search_bar() {
    if( _nb.current != null ) {
      var box = _nb.current.page as Gtk.Box;
      var revealer = box.get_children().nth_data( 0 ) as Gtk.Revealer;
      if( revealer != null ) {
        var bar    = revealer.get_child() as SearchBar;
        var reveal = !revealer.reveal_child;
        revealer.reveal_child = reveal;
        bar.change_display( reveal );
      }
    }
  }

  /* Handles any changes to the dark mode preference gsettings for the desktop */
  private void handle_prefer_dark_changes() {
    var lookup = SettingsSchemaSource.get_default().lookup( DESKTOP_SCHEMA, false );
    if( lookup != null ) {
      var desktop_settings = new GLib.Settings( DESKTOP_SCHEMA );
      _prefer_dark = desktop_settings.get_boolean( DARK_KEY );
      desktop_settings.changed.connect(() => {
        _prefer_dark = desktop_settings.get_boolean( DARK_KEY );
        theme_changed( get_current_table( "handle_prefer_dark_changes" ) );
      });
    }
  }

  /* Updates the title */
  private void update_title( OutlineTable? ot ) {
    string suffix = " \u2014 Outliner";
    if( (ot == null) || !ot.document.is_saved() ) {
      _header.set_title( _( "Unnamed Document" ) + suffix );
    } else {
      _header.set_title( GLib.Path.get_basename( ot.document.filename ) + suffix );
    }
  }

  /* This needs to be called whenever the tab is changed */
  private void tab_changed( Tab tab ) {
    var ot = get_table( tab );
    do_buffer_changed( ot.undo_buffer );
    update_title( ot );
    canvas_changed( ot );
    save_tab_state( tab );
  }

  /* Called whenever the current tab is switched in the notebook */
  private void tab_switched( Tab? old_tab, Tab new_tab ) {
    tab_changed( new_tab );
  }

  /* Called whenever the current tab is moved to a new position */
  private void tab_reordered( Tab? tab, int new_pos ) {
    save_tab_state( tab );
  }

  /* Called whenever the current tab is moved to a new position */
  private void tab_removed( Tab tab ) {
    save_tab_state( tab );
  }

  /* Called whenever the user clicks on the close button and the tab is unnamed */
  private bool close_tab_requested( Tab tab ) {
    var ot  = get_table( tab );
    var ret = ot.document.is_saved() || show_save_warning( ot );
    return( ret );
  }

   /* Adds a new tab to the notebook */
  public OutlineTable add_tab( string? fname, TabAddReason reason ) {

    var box = new Box( Orientation.VERTICAL, 0 );

    /* Create and pack the canvas */
    var ot = new OutlineTable( _settings );
    ot.map_event.connect( on_table_mapped );
    ot.undo_buffer.buffer_changed.connect( do_buffer_changed );
    ot.undo_text.buffer_changed.connect( do_buffer_changed );

    if( fname != null ) {
      ot.document.filename = fname;
    }

    /* Create the overlay that will hold the canvas so that we can put an entry box for emoji support */
    var overlay = new Overlay();
    overlay.add( ot );

    /* Create the scrolled window for the treeview */
    var scroll = new ScrolledWindow( null, null );
    scroll.vscrollbar_policy = PolicyType.AUTOMATIC;
    scroll.hscrollbar_policy = PolicyType.EXTERNAL;
    scroll.add( overlay );

    /* Create the search bar */
    var search = new SearchBar( ot );

    /* Create the search revealer */
    var search_reveal = new Revealer();
    search_reveal.add( search );

    box.pack_start( search_reveal, false, true );
    box.pack_start( scroll,        true,  true );

    /* Create the tab in the notebook */
    var tab = new Tab( ot.document.label, null, box );
    tab.pinnable = false;
    tab.tooltip  = fname;

    /* Add the page to the notebook */
    _nb.insert_tab( tab, _nb.n_tabs );

    /* Update the titlebar */
    update_title( ot );

    /* Make the drawing area new */
    if( reason == TabAddReason.NEW ) {
      ot.initialize_for_new();
    }

    /* Indicate that the tab has changed */
    if( reason != TabAddReason.LOAD ) {
      _nb.current = tab;
    }

    ot.grab_focus();

    return( ot );

  }

  /* Save the current tab state */
  private void save_tab_state( Tab current_tab ) {

    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "outliner" );

    if( DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return;
    }

    var       fname        = GLib.Path.build_filename( dir, "tab_state.xml" );
    var       selected_tab = -1;
    var       i            = 0;
    Xml.Doc*  doc          = new Xml.Doc( "1.0" );
    Xml.Node* root         = new Xml.Node( null, "tabs" );

    doc->set_root_element( root );

    _nb.tabs.foreach((tab) => {
      var       table = get_table( tab );
      Xml.Node* node  = new Xml.Node( null, "tab" );
      node->new_prop( "path",  table.document.filename );
      node->new_prop( "saved", table.document.is_saved().to_string() );
      root->add_child( node );
      if( tab == current_tab ) {
        selected_tab = i;
      }
      i++;
    });

    if( selected_tab > -1 ) {
      root->new_prop( "selected", selected_tab.to_string() );
    }

    /* Save the file */
    doc->save_format_file( fname, 1 );

    delete doc;

  }

  /* Loads the tab state */
  public bool load_tab_state() {

    var tab_state = GLib.Path.build_filename( Environment.get_user_data_dir(), "outliner", "tab_state.xml" );

    /* If the file does not exist, skip the rest and return false */
    if( !FileUtils.test( tab_state, FileTest.EXISTS ) ) return( false );

    Xml.Doc* doc = Xml.Parser.parse_file( tab_state );

    if( doc == null ) { return( false ); }

    var root = doc->get_root_element();
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tab") ) {
        var fname = it->get_prop( "path" );
        var saved = it->get_prop( "saved" );
        var table = add_tab( fname, TabAddReason.LOAD );
        table.document.load_filename( fname, bool.parse( saved ) );
        table.document.load();
      }
    }

    var s = root->get_prop( "selected" );
    if( s != null ) {
      _nb.current = _nb.get_tab_by_index( int.parse( s ) );
      tab_changed( _nb.current );
    }

    delete doc;

    return( _nb.n_tabs > 0 );

  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {

    app.set_accels_for_action( "win.action_new",     { "<Control>n" } );
    app.set_accels_for_action( "win.action_open",    { "<Control>o" } );
    app.set_accels_for_action( "win.action_save",    { "<Control>s" } );
    app.set_accels_for_action( "win.action_save_as", { "<Control><Shift>s" } );
    app.set_accels_for_action( "win.action_undo",    { "<Control>z" } );
    app.set_accels_for_action( "win.action_redo",    { "<Control><Shift>z" } );
    app.set_accels_for_action( "win.action_search",  { "<Control>f" } );
    app.set_accels_for_action( "win.action_quit",    { "<Control>q" } );
    app.set_accels_for_action( "win.action_print",   { "<Control>p" } );

  }

  /* Adds the search functionality */
  private void add_search_button() {

    /* Create the menu button */
    _search_btn = new Button.from_icon_name( "edit-find", IconSize.LARGE_TOOLBAR );
    _search_btn.set_tooltip_markup( _( "Search   <i>(Control-F)</i>" ) );
    _search_btn.clicked.connect( toggle_search_bar );
    _header.pack_end( _search_btn );

  }

  /* Adds the export functionality */
  private void add_export_button() {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( new Image.from_icon_name( "document-export", IconSize.LARGE_TOOLBAR ) );
    menu_btn.set_tooltip_text( _( "Export" ) );
    _header.pack_end( menu_btn );

    /* Create export menu */
    var box = new Box( Orientation.VERTICAL, 5 );

    var export = new ModelButton();
    export.text = _( "Export..." );
    export.action_name = "win.action_export";

    var print = new ModelButton();
    print.text = _( "Print" );
    print.action_name = "win.action_print";
    print.set_sensitive( false );

    box.margin = 5;
    box.pack_start( export, false, true );
    box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
    box.pack_start( print,  false, true );
    box.show_all();

    /* Create the popover and associate it with clicking on the menu button */
    _export = new Popover( null );
    _export.add( box );
    menu_btn.popover = _export;

  }

  /* Adds the property functionality */
  private void add_properties_button() {

    /* Add the button */
    var prop_btn = new MenuButton();
    prop_btn.set_image( new Image.from_icon_name( "open-menu", IconSize.LARGE_TOOLBAR ) );
    prop_btn.set_tooltip_text( _( "Properties" ) );
    prop_btn.clicked.connect( properties_clicked );
    _header.pack_end( prop_btn );

    var box = new Box( Orientation.VERTICAL, 0 );

    var zoom_box = new Box( Orientation.HORIZONTAL, 0 );
    var zoom_lbl = new Label( _( "Zoom" ) + " %:" );

    _zoom = new SpinButton.with_range( 25, 200, 25 );
    _zoom.set_value( 100 );
    _zoom.value_changed.connect( zoom_changed );

    zoom_box.pack_start( zoom_lbl, false, false, 10 );
    zoom_box.pack_start( _zoom,    true,  true,  10 );

    box.pack_start( zoom_box, false, false, 10 );

    /* Add theme selector */
    var names     = new Array<string>();
    var theme_box = new Box( Orientation.HORIZONTAL, 0 );
    RadioButton? rb = null;
    themes.names( ref names );
    for( int i=0; i<names.length; i++ ) {
      var theme  = themes.get_theme( names.index( i ) );
      var button = new RadioButton.from_widget( rb );
      button.halign       = Align.CENTER;
      button.tooltip_text = theme.label;
      button.get_style_context().add_class( theme.name );
      button.get_style_context().add_class( "color-button" );
      button.clicked.connect(() => {
        var table = get_current_table();
        table.set_theme( theme );
        theme_changed( table );
      });
      _theme_buttons.set( theme.name, button );
      theme_box.pack_start( button, false, false, 10 );
      if( rb == null ) {
        rb = button;
      }
    }
    box.pack_start( theme_box, false, false, 10 );

    box.show_all();

    /* Create the popover and associate it with the menu button */
    var prop_popover = new Popover( null );
    prop_popover.add( box );
    prop_btn.popover = prop_popover;

  }

  /* Called whenever the user changes the zoom level */
  private void zoom_changed() {

    var table = get_current_table( "zoom_changed" );
    var zoom  = (int)_zoom.get_value();

    switch( zoom ) {
      case 25  :  table.zoom_changed(  9, 7,  2 );   break;
      case 50  :  table.zoom_changed( 10, 8,  3 );   break;
      case 75  :  table.zoom_changed( 11, 9,  4 );   break;
      case 100 :  table.zoom_changed( 12, 10, 5 );   break;
      case 125 :  table.zoom_changed( 13, 11, 6 );   break;
      case 150 :  table.zoom_changed( 14, 12, 7 );   break;
      case 175 :  table.zoom_changed( 15, 13, 8 );   break;
      case 200 :  table.zoom_changed( 16, 14, 9 );   break;
      default  :  table.zoom_changed( 12, 10, 10 );  break;
    }

    queue_draw();

  }

  /* Displays the save warning dialog window */
  public bool show_save_warning( OutlineTable ot ) {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "Save current unnamed document?" ),
      _( "Changes will be permanently lost if not saved." ),
      "dialog-warning",
      ButtonsType.NONE
    );

    var dont = new Button.with_label( _( "Discard Changes" ) );
    dialog.add_action_widget( dont, ResponseType.CLOSE );

    var cancel = new Button.with_label( _( "Cancel" ) );
    dialog.add_action_widget( cancel, ResponseType.CANCEL );

    var save = new Button.with_label( _( "Save" ) );
    save.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    dialog.add_action_widget( save, ResponseType.ACCEPT );

    dialog.set_transient_for( this );
    dialog.set_default_response( ResponseType.ACCEPT );
    dialog.set_title( "" );

    dialog.show_all();

    var res = dialog.run();

    dialog.destroy();

    switch( res ) {
      case ResponseType.ACCEPT :  return( save_file( ot ) );
      case ResponseType.CLOSE  :  return( ot.document.remove() );
    }

    return( false );

  }

  /* Creates a new document and adds it to the notebook */
  public void do_new_file() {

    var ot = add_tab( null, TabAddReason.NEW );

    /* Set the title to indicate that we have a new document */
    update_title( ot );

  }

  /* Allow the user to open a Outliner file */
  public void do_open_file() {

    /* Get the file to open from the user */
    FileChooserNative dialog = new FileChooserNative( _( "Open File" ), this, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );

    /* Create file filters */
    var filter = new FileFilter();
    filter.set_filter_name( "Outliner" );
    filter.add_pattern( "*.outliner" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( "Freemind / Freeplane" );
    filter.add_pattern( "*.mm" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( "Minder" );
    filter.add_pattern( "*.minder" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( "OPML" );
    filter.add_pattern( "*.opml" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      open_file( dialog.get_filename() );
    }

    get_current_table( "do_open_file" ).grab_focus();

  }

  /* Opens the file and display it in the table */
  public bool open_file( string fname ) {
    if( !FileUtils.test( fname, FileTest.IS_REGULAR ) ) {
      return( false );
    }
    if( fname.has_suffix( ".outliner" ) ) {
      var table = add_tab( fname, TabAddReason.OPEN );
      update_title( table );
      table.document.load();
      return( true );
 /*
    } else if( fname.has_suffix( ".opml" ) ) {
      _doc = new Document( _table, _settings );
      _table.initialize_for_open();
      update_title();
      ExportOPML.import( fname, _table );
      return( true );
    } else if( fname.has_suffix( ".minder" ) ) {
      _doc = new Docuemnt( _table, _settings );
      _table.initialize_for_open();
      update_title();
      ExportMinder.import( fname, _table );
      return( true );
*/
    }
    return( false );
  }

  /* Perform an undo action */
  public void do_undo() {
    var table = get_current_table( "do_undo" );
    if( table.is_node_editable() || table.is_note_editable() ) {
      table.undo_text.undo();
    } else {
      table.undo_buffer.undo();
    }
    table.grab_focus();
  }

  /* Perform a redo action */
  public void do_redo() {
    var table = get_current_table( "do_redo" );
    if( table.is_node_editable() || table.is_note_editable() ) {
      table.undo_text.redo();
    } else {
      table.undo_buffer.redo();
    }
    table.grab_focus();
  }

  /* Called when the outline table is initially mapped */
  private bool on_table_mapped( Gdk.EventAny e ) {
    get_current_table().queue_draw();
    return( false );
  }

  /* Called whenever the theme is changed */
  private void theme_changed( OutlineTable ot ) {
    Gtk.Settings? settings = Gtk.Settings.get_default();
    if( settings != null ) {
      settings.gtk_application_prefer_dark_theme = ot.get_theme().prefer_dark;
    }
  }

  /*
   Called whenever the undo buffer changes state.  Updates the state of
   the undo and redo buffer buttons.
  */
  public void do_buffer_changed( UndoBuffer buf ) {
    _undo_btn.set_sensitive( buf.undoable() );
    _undo_btn.set_tooltip_text( buf.undo_tooltip() );
    _redo_btn.set_sensitive( buf.redoable() );
    _redo_btn.set_tooltip_text( buf.redo_tooltip() );
  }

  /* Allow the user to select a filename to save the document as */
  public bool save_file( OutlineTable ot ) {
    FileChooserDialog dialog = new FileChooserDialog( _( "Save File" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Save" ), ResponseType.ACCEPT );
    FileFilter        filter = new FileFilter();
    bool              retval = false;
    filter.set_filter_name( _( "Outliner" ) );
    filter.add_pattern( "*.outliner" );
    dialog.add_filter( filter );
    if( dialog.run() == ResponseType.ACCEPT ) {
      string fname = dialog.get_filename();
      if( fname.substring( -7, -1 ) != ".outliner" ) {
        fname += ".outliner";
      }
      ot.document.filename = fname;
      ot.document.save();
      update_title( ot );
      retval = true;
    }
    dialog.close();
    ot.grab_focus();
    return( retval );
  }

  /* Called when the save as button is clicked */
  public void do_save_as_file() {
    save_file( get_current_table( "do_save_as_file" ) );
  }

  /* Called when the user uses the Control-n keyboard shortcut */
  private void action_new() {
    do_new_file();
  }

  /* Called when the user uses the Control-o keyboard shortcut */
  private void action_open() {
    do_open_file();
  }

  /* Called when the user uses the Control-s keyboard shortcut */
  private void action_save() {
    var table = get_current_table( "action_save" );
    if( table.document.is_saved() ) {
      table.document.save();
    } else {
      save_file( table );
    }
  }

  /* Called when the user uses the Control-S keyboard shortcut */
  private void action_save_as() {
    do_save_as_file();
  }

  /* Called when the user uses the Control-z keyboard shortcut */
  private void action_undo() {
    do_undo();
  }

  /* Called when the user uses the Control-Z keyboard shortcut */
  private void action_redo() {
    do_redo();
  }

  /* Called when the user uses the Control-f keyboard shortcut */
  private void action_search() {
    _search_btn.clicked();
  }

  /* Called when the user uses the Control-q keyboard shortcut */
  private void action_quit() {
    destroy();
  }

  /* Exports the model to various formats */
  private void action_export() {

    FileChooserDialog dialog = new FileChooserDialog( _( "Export As" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );

    /* Markdown */
    FileFilter md_filter = new FileFilter();
    md_filter.set_filter_name( _( "Markdown" ) );
    md_filter.add_pattern( "*.md" );
    md_filter.add_pattern( "*.markdown" );
    dialog.add_filter( md_filter );

    /* Minder */
    FileFilter minder_filter = new FileFilter();
    minder_filter.set_filter_name( _( "Minder" ) );
    minder_filter.add_pattern( "*.minder" );
    dialog.add_filter( minder_filter );

    /* OPML */
    FileFilter opml_filter = new FileFilter();
    opml_filter.set_filter_name( _( "OPML" ) );
    opml_filter.add_pattern( "*.opml" );
    dialog.add_filter( opml_filter );

    /* PDF */
    FileFilter pdf_filter = new FileFilter();
    pdf_filter.set_filter_name( _( "PDF" ) );
    pdf_filter.add_pattern( "*.pdf" );
    dialog.add_filter( pdf_filter );

    /* PlainText */
    FileFilter txt_filter = new FileFilter();
    txt_filter.set_filter_name( _( "PlainText" ) );
    txt_filter.add_pattern( "*.txt" );
    dialog.add_filter( txt_filter );

    if( dialog.run() == ResponseType.ACCEPT ) {

      var fname  = dialog.get_filename();
      var filter = dialog.get_filter();
      var table  = get_current_table( "action_export" );

      if( md_filter == filter ) {
        ExportMarkdown.export( repair_filename( fname, {".md", ".markdown"} ), table );
      } else if( minder_filter == filter ) {
        ExportMinder.export( repair_filename( fname, {".minder"} ), table );
      } else if( opml_filter == filter ) {
        ExportOPML.export( repair_filename( fname, {".opml"} ), table );
      } else if( pdf_filter == filter ) {
        ExportPDF.export( repair_filename( fname, {".pdf"} ), table );
      } else if( txt_filter == filter ) {
        ExportText.export( repair_filename( fname, {".txt"} ), table );
      }

    }

    dialog.close();

  }

  /*
   Checks the given filename to see if it contains any of the given suffixes.
   If a valid suffix is found, return the filename without modification; otherwise,
   returns the filename with the extension added.
  */
  private string repair_filename( string fname, string[] extensions ) {
    foreach (string ext in extensions) {
      if( fname.has_suffix( ext ) ) {
        return( fname );
      }
    }
    return( fname + extensions[0] );
  }

  /* Exports the model to the printer */
  private void action_print() {
/* TBD
    var print = new ExportPrint();
    print.print( _canvas, this );
*/
  }

  private void properties_clicked() {
    string theme_name = get_current_table( "properties_clicked" ).get_theme().name;
    _theme_buttons.get( theme_name ).active = true;
  }

}

