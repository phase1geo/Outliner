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
using Gee;

public enum TabAddReason {
  NEW,
  OPEN,
  IMPORT,
  LOAD
}

public class MainWindow : Hdy.ApplicationWindow {

  private GLib.Settings               _settings;
  private Revealer                    _header_revealer;
  private Hdy.HeaderBar               _header;
  private DynamicNotebook             _nb;
  private Button                      _search_btn;
  private Popover?                    _export      = null;
  private Button?                     _undo_btn    = null;
  private Button?                     _redo_btn    = null;
  private ZoomWidget                  _zoom;
  private Granite.Widgets.ModeButton  _list_types;
  private FontButton                  _fonts_title;
  private FontButton                  _fonts_name;
  private FontButton                  _fonts_note;
  private Switch                      _condensed;
  private Switch                      _show_tasks;
  private Switch                      _show_depth;
  private Switch                      _blank_rows;
	private Switch                      _auto_sizing;
  private Switch                      _markdown;
  private Label                       _stats_chars;
  private Label                       _stats_words;
  private Label                       _stats_rows;
  private Label                       _stats_ttotal;
  private Label                       _stats_topen;
  private Label                       _stats_tip;
  private Label                       _stats_tdone;
  private bool                        _debug       = false;
  private Box                         _themes;
  private HashMap<string,RadioButton> _theme_buttons;
  private Exports                     _exports;
  private Exporter                    _exporter;
  private UnicodeInsert               _unicoder;

  private bool on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";

  public GLib.Settings settings {
    get {
      return( _settings );
    }
  }
  public Exports exports {
    get {
      return( _exports );
    }
  }
  public UnicodeInsert unicoder {
    get {
      return( _unicoder );
    }
  }

  public static Themes themes = new Themes();
  public static bool   enable_tag_completion = true;

  private const GLib.ActionEntry[] action_entries = {
    { "action_new",           action_new },
    { "action_open",          action_open },
    { "action_save",          action_save },
    { "action_save_as",       action_save_as },
    { "action_undo",          action_undo },
    { "action_redo",          action_redo },
    { "action_search",        action_search },
    { "action_quit",          action_quit },
    // { "action_export",        action_export },
    { "action_print",         action_print },
    { "action_shortcuts",     action_shortcuts },
    { "action_focus_mode",    action_focus_mode },
    { "action_reset_fonts",   action_reset_fonts },
    { "action_zoom_in",       action_zoom_in },
    { "action_zoom_out",      action_zoom_out },
    { "action_zoom_actual",   action_zoom_actual }
  };

  private delegate void ChangedFunc();

  public signal void canvas_changed( OutlineTable? ot );

  /* Create the main window UI */
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings = settings;

    /* Initialize variables */
    _theme_buttons = new HashMap<string,RadioButton>();

    var window_x = settings.get_int( "window-x" );
    var window_y = settings.get_int( "window-y" );
    var window_w = settings.get_int( "window-w" );
    var window_h = settings.get_int( "window-h" );

    /* Create the exports and load it */
    _exports = new Exports();

    /* Unicoder */
    _unicoder = new UnicodeInsert();

    var focus_mode = settings.get_boolean( "focus-mode" );

    enable_tag_completion = settings.get_boolean( "enable-tag-auto-completion" );

    /* Add the theme CSS */
    themes.add_css();

    /* Listen for changes to the system dark mode */
#if GRANITE_6_OR_NEWER
    var granite_settings = Granite.Settings.get_default();
    granite_settings.notify["prefers-color-scheme"].connect( () => {
      update_themes();
    });
#endif

    /* Create the header bar */
    _header = new Hdy.HeaderBar();
    _header.set_show_close_button( true );
    _header.get_style_context().add_class( "outliner-toolbar" );
    _header.get_style_context().add_class( "titlebar" );

    /* Add header bar revealer */
    _header_revealer = new Revealer();
    _header_revealer.add( _header );
    _header_revealer.reveal_child = !focus_mode;

    /* Set the main window data */
    title = _( "Outliner" );
    if( (window_x == -1) && (window_y == -1) ) {
      set_position( Gtk.WindowPosition.CENTER );
    } else {
      move( window_x, window_y );
    }
    set_default_size( window_w, window_h );
    destroy.connect( Gtk.main_quit );

    /* Allows the titlebar to be drawn without a large black border */
    _header_revealer.get_style_context().remove_class( "titlebar" );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    _nb = new DynamicNotebook();
    _nb.add_button_visible = false;
    _nb.tab_bar_behavior   = focus_mode ? DynamicNotebook.TabBarBehavior.NEVER : DynamicNotebook.TabBarBehavior.SINGLE;
    _nb.tab_switched.connect( tab_switched );
    _nb.tab_reordered.connect( tab_reordered );
    _nb.tab_removed.connect( tab_removed );
    _nb.close_tab_requested.connect( close_tab_requested );
    _nb.get_style_context().add_class( Gtk.STYLE_CLASS_INLINE_TOOLBAR );

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( get_icon_name( "document-new" ), get_icon_size() );
    new_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "New File" ), "<Control>n" ) );
    new_btn.clicked.connect( do_new_file );
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( get_icon_name( "document-open" ), get_icon_size() );
    open_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Open File" ), "<Control>o" ) );
    open_btn.clicked.connect( do_open_file );
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( get_icon_name( "document-save-as" ), get_icon_size() );
    save_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Save File As" ), "<Control><Shift>s" ) );
    save_btn.clicked.connect( do_save_as_file );
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( get_icon_name( "edit-undo" ), get_icon_size() );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( get_icon_name( "edit-redo" ), get_icon_size() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    /* Add the buttons on the right side in the reverse order */
    add_properties_button();
    add_export_button();
    add_stats_button();
    add_search_button();

    var top_box = new Box( Orientation.VERTICAL, 0 );
    top_box.pack_start( _header_revealer, false, true, 0 );
    top_box.pack_start( _nb, true, true, 0 );

    /* Display the UI */
    add( top_box );
    show_all();

  }

  static construct {
    Hdy.init();
  }

  /* Returns the name of the icon to use for a headerbar icon */
  private string get_icon_name( string icon_name ) {
    return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
  }

  /* Returns the size of the icon to use for a headerbar icon */
  private IconSize get_icon_size() {
    return( on_elementary ? IconSize.LARGE_TOOLBAR : IconSize.SMALL_TOOLBAR );
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

  /* Shows or hides the information bar, setting the message to the given value */
  private void show_info_bar( string? msg ) {
    if( _nb.current != null ) {
      var box  = _nb.current.page as Gtk.Box;
      var info = box.get_children().nth_data( 2 ) as Gtk.InfoBar;
      if( info != null ) {
        if( msg != null ) {
          var lbl = info.get_content_area().get_children().nth_data( 0 ) as Gtk.Label;
          lbl.label = msg;
          info.set_revealed( true );
        } else {
          info.set_revealed( false );
        }
      }
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
    do_fonts_changed( ot );
    update_title( ot );
    canvas_changed( ot );
    ot.update_theme();
    ot.grab_focus();
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

  /* Closes the current tab */
  public void close_current_tab() {
    if( _nb.n_tabs == 1 ) return;
    _nb.current.close();
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
    box.border_width = 0;

    /* Create and pack the canvas */
    var ot = new OutlineTable( this, _settings );
    ot.map_event.connect( on_table_mapped );
    ot.undo_buffer.buffer_changed.connect( do_buffer_changed );
    ot.undo_text.buffer_changed.connect( do_buffer_changed );
    ot.theme_changed.connect( theme_changed );
    ot.focus_mode.connect( show_info_bar );
    ot.nodes_filtered.connect( show_info_bar );

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
    var search_reveal = new Revealer();
    search_reveal.add( search );

    /* Create the info bar */
    var info_bar = create_info_bar();

    box.pack_start( search_reveal, false, true );
    box.pack_start( scroll,        true,  true );
    box.pack_start( info_bar,      false, true );

    /* Create the tab in the notebook */
    var tab = new Tab( ot.document.label, null, box );
    tab.pinnable = false;
    tab.tooltip  = fname;

    /* Add the page to the notebook */
    _nb.insert_tab( tab, _nb.n_tabs );

    /* Update the titlebar */
    update_title( ot );

    /* Make the drawing area new */
    switch( reason ) {
      case TabAddReason.NEW    :
        ot.initialize_for_new();
        _nb.current = tab;
        break;
      case TabAddReason.IMPORT :
      case TabAddReason.OPEN :
        ot.initialize_for_open();
        _nb.current = tab;
        break;
    }

    ot.grab_focus();

    return( ot );

  }

  /*
   Checks to see if any other tab contains the given filename.  If the filename
   is already found, refresh the tab with the file contents and make it the current
   tab; otherwise, add the new tab and populate it.
  */
  private OutlineTable add_tab_conditionally( string fname, TabAddReason reason ) {

    foreach( Tab tab in _nb.tabs ) {
      var ot = get_table( tab );
      if( ot.document.filename == fname ) {
        ot.initialize_for_open();
        _nb.current = tab;
        return( ot );
      }
    }

    return( add_tab( fname, reason ) );

  }


  /* Creates the info bar UI */
  private InfoBar create_info_bar() {

    var lbl = new Label( "" );

    var info_bar = new InfoBar();
    info_bar.get_content_area().add( lbl );
    info_bar.set_revealed( false );
    info_bar.message_type = MessageType.INFO;

    return( info_bar );

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

    app.set_accels_for_action( "win.action_new",         { "<Control>n" } );
    app.set_accels_for_action( "win.action_open",        { "<Control>o" } );
    app.set_accels_for_action( "win.action_save",        { "<Control>s" } );
    app.set_accels_for_action( "win.action_save_as",     { "<Control><Shift>s" } );
    app.set_accels_for_action( "win.action_undo",        { "<Control>z" } );
    app.set_accels_for_action( "win.action_redo",        { "<Control><Shift>z" } );
    app.set_accels_for_action( "win.action_search",      { "<Control>f" } );
    app.set_accels_for_action( "win.action_quit",        { "<Control>q" } );
    // app.set_accels_for_action( "win.action_export",      { "<Control>e" } );
    app.set_accels_for_action( "win.action_print",       { "<Control>p" } );
    app.set_accels_for_action( "win.action_shortcuts",   { "<Control>question" } );
    app.set_accels_for_action( "win.action_focus_mode",  { "F2" } );
    app.set_accels_for_action( "win.action_zoom_in",     { "<Control>plus", "<Control>equal" } );
    app.set_accels_for_action( "win.action_zoom_out",    { "<Control>minus" } );
    app.set_accels_for_action( "win.action_zoom_actual", { "<Control>0" } );

  }

  /* Adds the search functionality */
  private void add_search_button() {

    /* Create the menu button */
    _search_btn = new Button.from_icon_name( get_icon_name( "edit-find" ), get_icon_size() );
    _search_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Search" ), "<Control>f" ) );
    _search_btn.clicked.connect( toggle_search_bar );
    _header.pack_end( _search_btn );

  }

  /* Adds the statistics functionality */
  private void add_stats_button() {

    var stats_btn = new MenuButton();
    stats_btn.set_image( new Image.from_icon_name( "org.gnome.PowerStats", get_icon_size() ) );
    stats_btn.set_tooltip_markup( _( "Statistics" ) );
    stats_btn.clicked.connect( stats_clicked );

    var grid = new Grid();
    grid.border_width       = 10;
    grid.row_spacing        = 10;
    // grid.column_homogeneous = true;
    grid.column_spacing     = 10;

    var lmargin = "    ";

    var group_text = new Label( _( "<b>Text Statistics</b>" ) );
    group_text.xalign     = 0;
    group_text.use_markup = true;

    var lbl_chars = new Label( lmargin + _( "Characters:") );
    lbl_chars.xalign = 0;
    _stats_chars  = new Label( "0" );
    _stats_chars.xalign = 0;

    var lbl_words = new Label( lmargin + _( "Words:" ) );
    lbl_words.xalign = 0;
    _stats_words  = new Label( "0" );
    _stats_words.xalign = 0;

    var lbl_rows = new Label( lmargin + _( "Rows:") );
    lbl_rows.xalign = 0;
    _stats_rows  = new Label( "0" );
    _stats_rows.xalign = 0;

    var group_tasks = new Label( _( "<b>Checkbox Statistics</b>" ) );
    group_tasks.xalign     = 0;
    group_tasks.use_markup = true;

    var lbl_ttotal = new Label( lmargin + _( "Total:" ) );
    lbl_ttotal.xalign = 0;
    _stats_ttotal  = new Label( "0" );
    _stats_ttotal.xalign = 0;

    var lbl_topen = new Label( lmargin + _( "Incomplete:" ) );
    lbl_topen.xalign = 0;
    _stats_topen  = new Label( "0" );
    _stats_topen.xalign = 0;

    var lbl_tip   = new Label( lmargin + _( "In Progress:" ) );
    lbl_tip.xalign = 0;
    _stats_tip    = new Label( "0" );
    _stats_tip.xalign = 0;

    var lbl_tdone = new Label( lmargin + _( "Completed:" ) );
    lbl_tdone.xalign = 0;
    _stats_tdone  = new Label( "0" );
    _stats_tdone.xalign = 0;

    grid.attach( group_text,    0, 0, 2 );
    grid.attach( lbl_chars,     0, 1 );
    grid.attach( _stats_chars,  1, 1 );
    grid.attach( lbl_words,     0, 2 );
    grid.attach( _stats_words,  1, 2 );
    grid.attach( lbl_rows,      0, 3 );
    grid.attach( _stats_rows,   1, 3 );
    grid.attach( new Separator( Orientation.HORIZONTAL ), 0, 4, 2 );
    grid.attach( group_tasks,   0, 5, 2 );
    grid.attach( lbl_ttotal,    0, 6 );
    grid.attach( _stats_ttotal, 1, 6 );
    grid.attach( lbl_topen,     0, 7 );
    grid.attach( _stats_topen,  1, 7 );
    grid.attach( lbl_tip,       0, 8 );
    grid.attach( _stats_tip,    1, 8 );
    grid.attach( lbl_tdone,     0, 9 );
    grid.attach( _stats_tdone,  1, 9 );
    grid.show_all();

    /* Create the popover and associate it with the menu button */
    stats_btn.popover = new Popover( null );
    stats_btn.popover.add( grid );

    /* Add the button to the header bar */
    _header.pack_end( stats_btn );

  }

  /* Toggle the statistics bar */
  private void stats_clicked() {
    int char_count, word_count, row_count;
    int tasks_open, tasks_doing, tasks_done;
    get_current_table( "toggle_stats" ).calculate_statistics(
      out char_count, out word_count, out row_count,
      out tasks_open, out tasks_doing, out tasks_done );
    var task_total = tasks_open + tasks_doing + tasks_done;
    _stats_chars.label = char_count.to_string();
    _stats_words.label = word_count.to_string();
    _stats_rows.label  = row_count.to_string();
    _stats_ttotal.label = task_total.to_string();
    if( task_total > 0 ) {
      _stats_topen.label = "%d  (%d%%)".printf( tasks_open,  (int)(((tasks_open  * 1.0) / task_total) * 100) );
      _stats_tip.label   = "%d  (%d%%)".printf( tasks_doing, (int)(((tasks_doing * 1.0) / task_total) * 100) );
      _stats_tdone.label = "%d  (%d%%)".printf( tasks_done,  (int)(((tasks_done  * 1.0) / task_total) * 100) );
    } else {
      _stats_topen.label = "--";
      _stats_tip.label   = "--";
      _stats_tdone.label = "--";
    }
  }

  /* Adds the export functionality */
  private void add_export_button() {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.image = new Image.from_icon_name( (on_elementary ? "document-export" : "document-send-symbolic"), get_icon_size() );
    menu_btn.tooltip_text = _( "Export" );

    _header.pack_end( menu_btn );

    /* Create export menu */
    _exporter = new Exporter( this );
    _exporter.export_done.connect(() => {
      Utils.hide_popover( menu_btn.popover );
    });

    /* Create export menu */
    var box = new Box( Orientation.VERTICAL, 5 );

    var print = new ModelButton();
    print.get_child().destroy();
    print.add( new Granite.AccelLabel( _( "Print…" ), "<Control>p" ) );
    print.action_name = "win.action_print";
    print.set_sensitive( false );

    box.margin = 5;
    box.pack_start( _exporter, false, true );
    box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
    box.pack_start( print,  false, true );
    box.show_all();

    /* Create the popover and associate it with clicking on the menu button */
    _export = new Popover( null );
    _export.add( box );

    menu_btn.popover = _export;

  }

  /* Returns the font box for the given target type */
  private Box create_font_box( FontTarget target, string label, ref FontButton? fbtn ) {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( "%s:".printf( label ) );
    var btn = new FontButton();
    btn.show_style = false;
    btn.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    btn.font_set.connect(() => {
      var table = get_current_table();
      table.change_font( target, btn.get_font_family().get_name(), (btn.get_font_size() / Pango.SCALE) );
    });

    box.pack_start( lbl,  false, false, 10 );
    box.pack_end(   btn, false, false, 10 );

    fbtn = btn;

    return( box );

  }

  /* Adds the property functionality */
  private void add_properties_button() {

    /* Add the button */
    var prop_btn = new MenuButton();
    prop_btn.set_image( new Image.from_icon_name( get_icon_name( "open-menu" ), get_icon_size() ) );
    prop_btn.set_tooltip_text( _( "Properties" ) );
    prop_btn.clicked.connect( properties_clicked );
    _header.pack_end( prop_btn );

    var box = new Box( Orientation.VERTICAL, 0 );

    _zoom = new ZoomWidget( 100, 225, 25 );
    _zoom.margin = 10;
    _zoom.zoom_changed.connect( zoom_changed );

    box.pack_start( _zoom, false, false, 0 );

    /* Add theme selector */
    var theme_box = new Box( Orientation.HORIZONTAL, 0 );
    var theme_lbl = new Label( _( "Theme:" ) );
    _themes = new Box( Orientation.HORIZONTAL, 0 );
    theme_box.pack_start( theme_lbl, false, false, 10 );
    theme_box.pack_end(   _themes, false, false, 10 );
    box.pack_start( theme_box, false, false, 10 );

    var names = new Array<string>();
    themes.names( ref names );

    RadioButton? rb = null;

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
      if( rb == null ) {
        rb = button;
      }
    }

    update_themes();

    /* Add list type selector */
    var ltbox = new Box( Orientation.HORIZONTAL, 0 );
    var ltlbl = new Label( _( "Enumeration Style:" ) );
    _list_types = new Granite.Widgets.ModeButton();
    _list_types.has_tooltip = true;
    _list_types.button_release_event.connect( link_type_changed );
    _list_types.query_tooltip.connect( link_type_show_tooltip );

    for( int i=0; i<NodeListType.LENGTH; i++ ) {
      _list_types.append_text( ((NodeListType)i).label() );
    }

    ltbox.pack_start( ltlbl,       false, false, 10 );
    ltbox.pack_end(   _list_types, false, false, 10 );
    box.pack_start( ltbox, false, false, 10 );

    /* Add title font selection button */
    var title_font = create_font_box( FontTarget.TITLE, _( "Title Font" ), ref _fonts_title );
    box.pack_start( title_font, false, false, 10 );

    /* Add row font selection button */
    var row_font = create_font_box( FontTarget.NAME, _( "Row Font" ), ref _fonts_name );
    box.pack_start( row_font, false, false, 10 );

    /* Add row font selection button */
    var note_font = create_font_box( FontTarget.NOTE, _( "Note Font" ), ref _fonts_note );
    box.pack_start( note_font, false, false, 10 );

    /* Add condensed mode switch */
    var cbox = new Box( Orientation.HORIZONTAL, 0 );
    var clbl = new Label( _( "Condensed Mode:" ) );
    _condensed = new Switch();
    _condensed.state_set.connect( (state) => {
      var table = get_current_table();
      table.condensed = state;
      return( false );
    });
    cbox.pack_start( clbl,       false, true,  10 );
    cbox.pack_end(   _condensed, false, false, 10 );
    box.pack_start( cbox, false, false, 10 );

    /* Add show tasks switch */
    var tbox = new Box( Orientation.HORIZONTAL, 0 );
    var tlbl = new Label( _( "Show Checkboxes" ) );
    _show_tasks = new Switch();
    _show_tasks.state_set.connect( (state) => {
      var table = get_current_table();
      table.show_tasks = state;
      return( false );
    });
    tbox.pack_start( tlbl,        false, true,  10 );
    tbox.pack_end(   _show_tasks, false, false, 10 );
    box.pack_start( tbox, false, false, 10 );

    /* Add show depth switch */
    var dbox = new Box( Orientation.HORIZONTAL, 0 );
    var dlbl = new Label( _( "Show Depth Lines" ) );
    _show_depth = new Switch();
    _show_depth.state_set.connect( (state) => {
      var table = get_current_table();
      table.show_depth = state;
      return( false );
    });
    dbox.pack_start( dlbl,        false, true,  10 );
    dbox.pack_end(   _show_depth, false, false, 10 );
    box.pack_start( dbox, false, false, 10 );

    /* Add blank rows switch */
    var brbox = new Box( Orientation.HORIZONTAL, 0 );
    var brlbl = new Label( _( "Enable Blank Rows" ) );
    _blank_rows = new Switch();
    _blank_rows.state_set.connect( (state) => {
      var table = get_current_table();
      table.blank_rows = state;
      return( false );
    });
    brbox.pack_start( brlbl,       false, true, 10 );
    brbox.pack_end(   _blank_rows, false, false, 10 );
    box.pack_start( brbox, false, false, 10 );

    /* Add header sizing switch */
    var asbox = new Box( Orientation.HORIZONTAL, 0 );
    var aslbl = new Label( _( "Enable Header Auto-Sizing" ) );
    _auto_sizing = new Switch();
    _auto_sizing.state_set.connect( (state) => {
			var table = get_current_table();
			table.auto_sizing = state;
			return( false );
    });
		asbox.pack_start( aslbl,        false, true, 10 );
		asbox.pack_end(   _auto_sizing, false, false, 10 );
		box.pack_start( asbox, false, false, 10 );

    /* Add the Markdown switch */
    var mbox = new Box( Orientation.HORIZONTAL, 0 );
    var mlbl = new Label( _( "Enable Markdown Highlighting" ) );
    _markdown = new Switch();
    _markdown.state_set.connect( (state) => {
      var table = get_current_table();
      table.markdown = state;
      return( false );
    });
    mbox.pack_start( mlbl,      false, true, 10 );
    mbox.pack_end(   _markdown, false, false, 10 );
    box.pack_start( mbox, false, false, 10 );

    /* Add a separator for the ModelButtons */
    box.pack_start( new Separator( Orientation.HORIZONTAL ) );

    var btn_box = new Box( Orientation.VERTICAL, 0 );

    /* Add button to display shortcuts */
    var shortcuts = new ModelButton();
    shortcuts.get_child().destroy();
    shortcuts.add( new Granite.AccelLabel( _( "Shortcuts Cheatsheet" ), "<Control>question" ) );
    shortcuts.action_name = "win.action_shortcuts";
    btn_box.pack_start( shortcuts, false, false, 5 );

    /* Focus mode */
    var focus_mode = new ModelButton();
    focus_mode.get_child().destroy();
    focus_mode.add( new Granite.AccelLabel( _( "Enter Distraction-Free Mode" ), "F2" ) );
    focus_mode.action_name = "win.action_focus_mode";
    btn_box.pack_start( focus_mode, false, false, 5 );

    /* Font reset */
    var reset_fonts = new ModelButton();
    reset_fonts.text = _( "Reset Fonts to Defaults" );
    reset_fonts.action_name = "win.action_reset_fonts";
    btn_box.pack_start( reset_fonts, false, false, 5 );

    box.pack_start( btn_box, false, false, 0 );

    box.show_all();

    /* Create the popover and associate it with the menu button */
    var prop_popover = new Popover( null );
    prop_popover.add( box );
    prop_btn.popover = prop_popover;

  }

  /* Called whenever the themes need to be updated */
  private void update_themes() {

#if GRANITE_6_OR_NEWER
    var settings = Granite.Settings.get_default();
    var dark     = settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    var hide     = true;
#else
    var dark     = false;
    var hide     = false;
#endif

    /* Remove all of the themes */
    _themes.get_children().foreach((entry) => {
      _themes.remove( entry );
    });

    var names = new Array<string>();
    themes.names( ref names );

    for( int i=0; i<names.length; i++ ) {
      var theme = themes.get_theme( names.index( i ) );
      if( !hide || (theme.prefer_dark == dark) ) {
        var button = _theme_buttons.get( theme.name );
        _themes.pack_start( button, false, false, 10 );
      }
    }

    _themes.show_all();

  }

  /* Returns the current zoom factor */
  public double get_zoom_factor() {
    return( _zoom.factor );
  }

  /* Called whenever the user changes the zoom level */
  private void zoom_changed( double factor ) {

    var table = get_current_table( "zoom_changed" );

    table.zoom_changed();
    queue_draw();

  }

  /* Causes the link type to change */
  private bool link_type_changed( Gdk.EventButton e ) {
    if( _list_types.selected < NodeListType.LENGTH ) {
      get_current_table( "link_type_changed" ).list_type = (NodeListType)_list_types.selected;
    }
    return( false );
  }

  /* Displays the tooltip for the link type widget */
  private bool link_type_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( !keyboard ) {
      int button_width = (int)(_list_types.get_allocated_width() / NodeListType.LENGTH);
      if( (x / button_width) < NodeListType.LENGTH ) {
        tooltip.set_text( ((NodeListType)(x / button_width)).tooltip() );
        return( true );
      }
    }
    return( false );
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

    for( int i=0; i<exports.length(); i++ ) {
      if( exports.index( i ).importable ) {
        filter = new FileFilter();
        filter.set_filter_name( exports.index( i ).label );
        foreach( string extension in exports.index( i ).extensions ) {
          filter.add_pattern( "*" + extension );
        }
        dialog.add_filter( filter );
      }
    }

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
      var table = add_tab_conditionally( fname, TabAddReason.OPEN );
      update_title( table );
      table.document.load();
      return( true );
    } else {
      for( int i=0; i<exports.length(); i++ ) {
        if( exports.index( i ).importable ) {
          string new_fname;
          if( exports.index( i ).filename_matches( fname, out new_fname ) ) {
            new_fname += ".outliner";
            var table = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
            update_title( table );
            if( exports.index( i ).import( fname, table ) ) {
              save_tab_state( _nb.current );
              return( true );
            }
            close_current_tab();
          }
        }
      }
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
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.undo_tooltip(), "<Control>z" ) );
    _redo_btn.set_sensitive( buf.redoable() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.redo_tooltip(), "<Control><Shift>z" ) );
  }

  /* Called whenever the tab is changed to update the current document's font information */
  private void do_fonts_changed( OutlineTable ot ) {
    var title_fd = _fonts_title.get_font_desc();
    var name_fd  = _fonts_name.get_font_desc();
    var note_fd  = _fonts_note.get_font_desc();
    if( ot.title_font_family != null ) {
      title_fd.set_family( ot.title_font_family );
    }
    if( ot.name_font_family != null ) {
      name_fd.set_family( ot.name_font_family );
    }
    if( ot.note_font_family != null ) {
      note_fd.set_family( ot.note_font_family );
    }
    title_fd.set_size( (int)(ot.title_font_size * Pango.SCALE) );
    name_fd.set_size( (int)(ot.name_font_size * Pango.SCALE) );
    note_fd.set_size( (int)(ot.note_font_size * Pango.SCALE) );
    _fonts_title.set_font_desc( title_fd );
    _fonts_name.set_font_desc( name_fd );
    _fonts_note.set_font_desc( note_fd );
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
      if( fname.substring( -9, -1 ) != ".outliner" ) {
        fname += ".outliner";
      }
      ot.document.filename = fname;
      ot.document.save();
      _nb.current.label = ot.document.label;
      _nb.current.tooltip = fname;
      update_title( ot );
      save_tab_state( _nb.current );
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

  /* Called when the user uses the Control-Plus/Equal shortcut */
  private void action_zoom_in() {
    _zoom.zoom_in();
  }

  /* Called when the user uses the Control-Minus shortcut */
  private void action_zoom_out() {
    _zoom.zoom_out();
  }

  /* Called when the user uses the Control-0 shortcut */
  private void action_zoom_actual() {
    _zoom.zoom_actual();
  }

  /* Called when the user uses the Control-q keyboard shortcut */
  private void action_quit() {
    destroy();
  }

  /*
   Checks the given filename to see if it contains any of the given suffixes.
   If a valid suffix is found, return the filename without modification; otherwise,
   returns the filename with the extension added.
  */
  public string repair_filename( string fname, string[] extensions ) {
    foreach (string ext in extensions) {
      if( fname.has_suffix( ext ) ) {
        return( fname );
      }
    }
    return( fname + extensions[0] );
  }

  /* Exports the model to the printer */
  private void action_print() {
    var print = new ExportPrint();
    print.print( get_current_table( "action_print" ), this );
  }

  /* Called whenever the properties button is clicked */
  private void properties_clicked() {
    var table      = get_current_table( "properties_clicked" );
    var theme_name = table.get_theme().name;
    _theme_buttons.get( theme_name ).active = true;
    _condensed.state     = table.condensed;
    _show_tasks.state    = table.show_tasks;
    _show_depth.state    = table.show_depth;
    _blank_rows.state    = table.blank_rows;
    _auto_sizing.state   = table.auto_sizing;
    _markdown.state      = table.markdown;
    _list_types.selected = table.list_type;
  }

  /* Displays the shortcuts cheatsheet */
  private void action_shortcuts() {

    var builder = new Builder.from_resource( "/com/github/phase1geo/outliner/shortcuts/shortcuts.ui" );
    var win     = builder.get_object( "shortcuts" ) as ShortcutsWindow;
    var table   = get_current_table( "action_shortcuts" );

    win.transient_for = this;
    win.view_name     = null;

    /* Display the most relevant information based on the current state */
    if( table.selected != null ) {
      if( (table.selected.mode == NodeMode.EDITABLE) ||
          (table.selected.mode == NodeMode.NOTEEDIT) ) {
        win.section_name = "text-editing";
      } else {
        win.section_name = "node";
      }
    } else {
      win.section_name = "general";
    }

    win.show();

  }

  /* Hides the header bar */
  public void action_focus_mode() {

    var enable = _header_revealer.reveal_child;

    /* Hide the header bar */
    _header_revealer.reveal_child = !enable;
    _nb.tab_bar_behavior   = enable ? DynamicNotebook.TabBarBehavior.NEVER : DynamicNotebook.TabBarBehavior.SINGLE;
    _settings.set_boolean( "focus-mode", enable );

  }

  /* Called whenever the user selects the reset fonts button in the properties popover */
  private void action_reset_fonts() {

    var table        = get_current_table( "action_reset_fonts" );
    var title_family = _settings.get_string( "default-title-font-family" );
    var name_family  = _settings.get_string( "default-row-font-family" );
    var note_family  = _settings.get_string( "default-note-font-family" );
    var title_size   = _settings.get_int( "default-title-font-size" );
    var name_size    = _settings.get_int( "default-row-font-size" );
    var note_size    = _settings.get_int( "default-note-font-size" );

    /* Update the table */
    table.change_font( FontTarget.TITLE, title_family, title_size );
    table.change_font( FontTarget.NAME,  name_family, name_size );
    table.change_font( FontTarget.NOTE,  note_family, note_size );

    /* Update the UI */
    do_fonts_changed( table );

  }

  /* Returns the height of a single line label */
  public int get_label_height() {
    int min_height, nat_height;
    _stats_chars.get_preferred_height( out min_height, out nat_height );
    return( nat_height );
  }

  /* Generate a notification */
  public void notification( string title, string msg, NotificationPriority priority = NotificationPriority.NORMAL ) {

    GLib.Application? app = null;
    @get( "application", ref app );

    if( app != null ) {
      var notification = new Notification( title );
      notification.set_body( msg );
      notification.set_priority( priority );
      app.send_notification( "com.github.phase1geo.outliner", notification );
    }

  }

}

