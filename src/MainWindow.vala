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

public class MainWindow : Gtk.ApplicationWindow {

  private GLib.Settings               _settings;
  private HeaderBar                   _header;
  private Notebook                    _nb;
  private Button                      _search_btn;
  private PopoverMenu                 _export;
  private Button?                     _undo_btn    = null;
  private Button?                     _redo_btn    = null;
  private ZoomWidget                  _zoom;
  private ModeGroup                   _list_types;
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
  private HashMap<string,CheckButton> _theme_buttons;
  private Exports                     _exports;
  private Exporter                    _exporter;
  private UnicodeInsert               _unicoder;
  private Label                       _info_label;

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
    { "action_preferences",   action_preferences },
    { "action_shortcuts",     action_shortcuts },
    { "action_focus_mode",    action_focus_mode },
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
    _theme_buttons = new HashMap<string,CheckButton>();

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
    _header = new HeaderBar() {
      show_title_buttons = true,
      title_widget = new Label( _( "Outliner" ) )
    };
    _header.get_style_context().add_class( "outliner-toolbar" );
    _header.get_style_context().add_class( "titlebar" );

    set_titlebar( _header );

    /* Set the main window data */
    set_default_size( window_w, window_h );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    _nb = new Notebook() {
      halign  = Align.FILL,
      valign  = Align.FILL,
      hexpand = true,
      vexpand = true
    };
    // _nb.add_button_visible = false;
    // _nb.tab_bar_behavior   = focus_mode ? DynamicNotebook.TabBarBehavior.NEVER : DynamicNotebook.TabBarBehavior.SINGLE;
    _nb.switch_page.connect( tab_switched );
    _nb.page_reordered.connect( tab_reordered );
    _nb.page_removed.connect( tab_removed );

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( get_icon_name( "document-new" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "New File" ), "<Control>n" )
    };
    new_btn.clicked.connect( do_new_file );
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( get_icon_name( "document-open" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Open File" ), "<Control>o" )
    };
    open_btn.clicked.connect( do_open_file );
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( get_icon_name( "document-save-as" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Save File As" ), "<Control><Shift>s" )
    };
    save_btn.clicked.connect( do_save_as_file );
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( get_icon_name( "edit-undo" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ),
      sensitive = false
    };
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( get_icon_name( "edit-redo" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ),
      sensitive = false
    };
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    /* Add the buttons on the right side in the reverse order */
    add_properties_button();
    add_export_button();
    add_stats_button();
    add_search_button();

    child = _nb;
    show();

  }

  /* Returns the name of the icon to use for a headerbar icon */
  private string get_icon_name( string icon_name ) {
    return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
  }

  /* Returns the OutlineTable associated with the given notebook page */
  public OutlineTable get_table( int page ) {
    var pg = _nb.get_nth_page( page );
    var sw = (ScrolledWindow)Utils.get_child_at_index( pg, 1 );
    var vp = (Viewport)sw.child;
    var ol = (Overlay)vp.child;
    var ot = (OutlineTable)ol.child;
    return( ot );
  }

  /* Returns the current drawing area */
  public OutlineTable? get_current_table( string? caller = null ) {
    if( _debug && (caller != null) ) {
      stdout.printf( "get_current_table called from %s\n", caller );
    }
    if( _nb.get_n_pages() == 0 ) { return( null ); }
    return( get_table( _nb.page ) );
  }

  /* Shows or hides the search bar for the current tab */
  private void toggle_search_bar() {
    var revealer = Utils.get_child_at_index( _nb.get_nth_page( _nb.page ), 0 ) as Revealer;
    if( revealer != null ) {
      var bar    = (SearchBar)revealer.child;
      var reveal = !revealer.reveal_child;
      revealer.reveal_child = reveal;
      bar.change_display( reveal );
    }
  }

  /* Shows or hides the information bar, setting the message to the given value */
  private void show_info_bar( string? msg ) {
    var info = Utils.get_child_at_index( _nb.get_nth_page( _nb.page ), 2 ) as InfoBar;
    if( info != null ) {
      if( msg != null ) {
        _info_label.label = msg;
        info.set_revealed( true );
      } else {
        info.set_revealed( false );
      }
    }
  }

  /* Updates the title */
  private void update_title( OutlineTable? ot ) {
    var suffix = " \u2014 Outliner";
    var title  = (Label)_header.title_widget;
    if( (ot == null) || !ot.document.is_saved() ) {
      title.label = _( "Unnamed Document" ) + suffix;
    } else {
      title.label = GLib.Path.get_basename( ot.document.filename ) + suffix;
    }
  }

  /* This needs to be called whenever the tab is changed */
  private void tab_changed( OutlineTable ot ) {
    do_buffer_changed( ot.undo_buffer );
    update_title( ot );
    canvas_changed( ot );
    ot.update_theme();
    ot.grab_focus();
    save_tab_state( ot );
  }

  /* Called whenever the current tab is switched in the notebook */
  private void tab_switched( Widget page, uint page_num ) {
    tab_changed( get_table( (int)page_num ) );
  }

  /* Called whenever the current tab is moved to a new position */
  private void tab_reordered( Widget page, uint page_num ) {
    save_tab_state( get_table( (int)page_num ) );
  }

  /* Called whenever the current tab is moved to a new position */
  private void tab_removed( Widget page, uint page_num ) {
    save_tab_state( get_table( (int)page_num ) );
  }

  /* Closes the current tab */
  public void close_current_tab() {
    if( _nb.get_n_pages() == 1 ) return;
    var ot = get_table( _nb.page );
    if( ot.document.is_saved() ) {
      _nb.detach_tab( _nb.get_nth_page( _nb.page ) );
    } else {
      show_save_warning( ot );
    }
  }

   /* Adds a new tab to the notebook */
  public OutlineTable add_tab( string? fname, TabAddReason reason ) {

    /* Create and pack the canvas */
    var ot = new OutlineTable( this, _settings );
    ot.map.connect( on_table_mapped );
    ot.undo_buffer.buffer_changed.connect( do_buffer_changed );
    ot.undo_text.buffer_changed.connect( do_buffer_changed );
    ot.theme_changed.connect( theme_changed );
    ot.focus_mode.connect( show_info_bar );
    ot.nodes_filtered.connect( show_info_bar );

    if( fname != null ) {
      ot.document.filename = fname;
    }

    /* Create the overlay that will hold the canvas so that we can put an entry box for emoji support */
    var overlay = new Overlay() {
      child = ot
    };

    /* Create the scrolled window for the treeview */
    var scroll = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hexpand = true,
      vexpand = true,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      hscrollbar_policy = PolicyType.EXTERNAL,
      child = overlay
    };

    /* Create the search bar */
    var search = new SearchBar( ot );
    var search_reveal = new Revealer() {
      halign = Align.FILL,
      child = search
    };

    /* Create the info bar */
    var info_bar = create_info_bar();

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( search_reveal );
    box.append( scroll );
    box.append( info_bar );

    var tab_label = new Label( ot.document.label );

    /* Add the page to the notebook */
    var tab_index = _nb.append_page( box, tab_label );

    /* Update the titlebar */
    update_title( ot );

    /* Make the drawing area new */
    switch( reason ) {
      case TabAddReason.NEW    :
        ot.initialize_for_new();
        _nb.page = tab_index;
        break;
      case TabAddReason.IMPORT :
      case TabAddReason.OPEN :
        ot.initialize_for_open();
        _nb.page = tab_index;
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

    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var ot = get_table( i );
      if( ot.document.filename == fname ) {
        ot.initialize_for_open();
        _nb.page = i;
        return( ot );
      }
    }

    return( add_tab( fname, reason ) );

  }


  /* Creates the info bar UI */
  private InfoBar create_info_bar() {

    _info_label = new Label( "" );

    var info_bar = new InfoBar() {
      halign = Align.FILL
    };
    info_bar.add_child( _info_label );
    info_bar.set_revealed( false );
    info_bar.message_type = MessageType.INFO;

    return( info_bar );

  }

  /* Save the current tab state */
  private void save_tab_state( OutlineTable current_table ) {

    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "outliner" );

    if( DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return;
    }

    var       fname        = GLib.Path.build_filename( dir, "tab_state.xml" );
    var       selected_tab = -1;
    Xml.Doc*  doc          = new Xml.Doc( "1.0" );
    Xml.Node* root         = new Xml.Node( null, "tabs" );

    doc->set_root_element( root );

    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var table = get_table( i );
      Xml.Node* node  = new Xml.Node( null, "tab" );
      node->new_prop( "path",  table.document.filename );
      node->new_prop( "saved", table.document.is_saved().to_string() );
      root->add_child( node );
      if( table == current_table ) {
        selected_tab = i;
      }
    }

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
      _nb.page = int.parse( s );
      // tab_changed( _nb.get_nth_page( _nb.current );
    }

    delete doc;

    return( _nb.get_n_pages() > 0 );

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
    app.set_accels_for_action( "win.action_preferences", { "<Control>period" } );
    app.set_accels_for_action( "win.action_shortcuts",   { "<Control>question" } );
    app.set_accels_for_action( "win.action_focus_mode",  { "F2" } );
    app.set_accels_for_action( "win.action_zoom_in",     { "<Control>plus", "<Control>equal" } );
    app.set_accels_for_action( "win.action_zoom_out",    { "<Control>minus" } );
    app.set_accels_for_action( "win.action_zoom_actual", { "<Control>0" } );

  }

  /* Adds the search functionality */
  private void add_search_button() {

    /* Create the menu button */
    _search_btn = new Button.from_icon_name( get_icon_name( "edit-find" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Search" ), "<Control>f" )
    };
    _search_btn.clicked.connect( toggle_search_bar );
    _header.pack_end( _search_btn );

  }

  /* Adds a statistic row to the given grid, returning the created value label */
  private Label add_stats_row( Grid grid, int row, string text ) {

    var lbl = new Label( text ) {
      margin_start = 30,
      xalign = 0
    };
    var val = new Label( "0" ) {
      xalign = 0
    };

    grid.attach( lbl, 0, row );
    grid.attach( val, 1, row );

    return( val );

  }

  /* Adds the statistics functionality */
  private void add_stats_button() {

    var grid = new Grid() {
      margin_start   = 10,
      margin_end     = 10,
      margin_top     = 10,
      margin_bottom  = 10,
      row_spacing    = 10,
      column_spacing = 10
    };

    var lmargin = "    ";

    var group_text = new Label( _( "<b>Text Statistics</b>" ) ) {
      xalign     = 0,
      use_markup = true
    };

    grid.attach( group_text, 0, 0, 2 );

    _stats_chars = add_stats_row( grid, 1, _( "Characters:" ) );
    _stats_words = add_stats_row( grid, 2, _( "Words:" ) );
    _stats_rows  = add_stats_row( grid, 3, _( "Rows:" ) );

    grid.attach( new Separator( Orientation.HORIZONTAL ), 0, 4, 2 );

    var group_tasks = new Label( _( "<b>Checkbox Statistics</b>" ) ) {
      xalign     = 0,
      use_markup = true
    };

    grid.attach( group_tasks, 0, 5, 2 );

    _stats_ttotal = add_stats_row( grid, 6, _( "Total:" ) );
    _stats_topen  = add_stats_row( grid, 7, _( "Incomplete:" ) );
    _stats_tip    = add_stats_row( grid, 8, _( "In Progress:" ) );
    _stats_tdone  = add_stats_row( grid, 9, _( "Completed:" ) );

    var popover = new Popover() {
      child = grid
    };

    var stats_btn = new MenuButton() {
      icon_name = "org.gnome.PowerStats",
      tooltip_markup = _( "Statistics" ),
      popover        = popover

    };
    popover.map.connect( stats_clicked );

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

    /* Create export menu */
    _exporter = new Exporter( this ) {
      margin_start = 10,
      margin_end   = 10
    };

    var export_menu_item = new GLib.MenuItem( null, null );
    export_menu_item.set_attribute( "custom", "s", "exporter" );

    var export_menu = new GLib.Menu();
    export_menu.append_item( export_menu_item );

    var print_menu = new GLib.Menu();
    print_menu.append( _( "Print…" ), "win.action_print" );

    var menu = new GLib.Menu();
    menu.append_section( null, export_menu );
    menu.append_section( null, print_menu );

    _export = new PopoverMenu.from_model( menu ) {
      cascade_popdown = false
    };

    _export.add_child( _exporter, "exporter" );

    /* Create the menu button */
    var menu_btn = new MenuButton() {
      icon_name    = (on_elementary ? "document-export" : "document-send-symbolic"),
      tooltip_text = _( "Export" ),
      popover      = _export
    };

    _exporter.export_done.connect(() => {
      menu_btn.popover.popdown();
    });

    _header.pack_end( menu_btn );

  }

  private Box create_theme_selector() {

    var theme_lbl = new Label( _( "Theme:" ) ) {
      halign = Align.START,
      hexpand = true
    };
    
    _themes = new Box( Orientation.HORIZONTAL, 10 ) {
      halign = Align.END
    };

    var names = new Array<string>();
    themes.names( ref names );

    CheckButton? rb = null;

    for( int i=0; i<names.length; i++ ) {
      var theme  = themes.get_theme( names.index( i ) );
      var button = new CheckButton() {
        halign       = Align.CENTER,
        tooltip_text = theme.label,
        group        = rb
      };
      button.get_style_context().add_class( theme.name );
      button.get_style_context().add_class( "color-button" );
      button.toggled.connect(() => {
        var table = get_current_table();
        table.set_theme( theme );
        theme_changed( table );
      });
      _theme_buttons.set( theme.name, button );
      if( rb == null ) {
        rb = button;
      }
    }

    var theme_box = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    theme_box.append( theme_lbl );
    theme_box.append( _themes );

    update_themes();

    return( theme_box );

  }

  /* Adds the property functionality */
  private void add_properties_button() {

    /* Add zoom widget */
    _zoom = new ZoomWidget( 100, 225, 25 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    _zoom.zoom_changed.connect( zoom_changed );

    var zoom_mi = new GLib.MenuItem( null, null );
    zoom_mi.set_attribute( "custom", "s", "zoom" );

    /* Add theme selector */
    var theme_box = create_theme_selector();

    var theme_mi = new GLib.MenuItem( null, null );
    theme_mi.set_attribute( "custom", "s", "theme" );

    /* Add list type selector */
    var ltbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    var ltlbl = new Label( _( "Enumeration Style:" ) ) {
      halign  = Align.START,
      hexpand = true
    };
    _list_types = new ModeGroup() {
      halign = Align.END
    };
    _list_types.changed.connect( link_type_changed );

    for( int i=0; i<NodeListType.LENGTH; i++ ) {
      var list_type = (NodeListType)i;
      _list_types.add_mode_text( list_type.label(), list_type.tooltip() );
    }

    ltbox.append( ltlbl );
    ltbox.append( _list_types );

    var list_type_mi = new GLib.MenuItem( null, null );
    list_type_mi.set_attribute( "custom", "s", "list_type" );

    /* Add condensed mode switch */
    var cbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    var clbl = new Label( _( "Condensed Mode:" ) ) {
      halign  = Align.START,
      hexpand = true
    };
    _condensed = new Switch() {
      halign = Align.END
    };
    _condensed.notify["active"].connect(() => {
      var table = get_current_table();
      table.condensed = _condensed.active;
    });
    cbox.append( clbl );
    cbox.append( _condensed );

    var condensed_mi = new GLib.MenuItem( null, null );
    condensed_mi.set_attribute( "custom", "s", "condensed" );

    /* Add show tasks switch */
    var tbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    var tlbl = new Label( _( "Show Checkboxes" ) ) {
      halign = Align.START,
      hexpand = true
    };
    _show_tasks = new Switch() {
      halign = Align.END
    };
    _show_tasks.notify["active"].connect(() => {
      var table = get_current_table();
      table.show_tasks = _show_tasks.active;
    });
    tbox.append( tlbl );
    tbox.append( _show_tasks );

    var tasks_mi = new GLib.MenuItem( null, null );
    tasks_mi.set_attribute( "custom", "s", "tasks" );

    /* Add show depth switch */
    var dbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    var dlbl = new Label( _( "Show Depth Lines" ) ) {
      halign = Align.START,
      hexpand = true
    };
    _show_depth = new Switch() {
      halign = Align.END
    };
    _show_depth.notify["active"].connect(() => {
      var table = get_current_table();
      table.show_depth = _show_depth.active;
    });
    dbox.append( dlbl );
    dbox.append( _show_depth );

    var depth_mi = new GLib.MenuItem( null, null );
    depth_mi.set_attribute( "custom", "s", "depth" );

    /* Add blank rows switch */
    var brbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    var brlbl = new Label( _( "Enable Blank Rows" ) ) {
      halign = Align.START,
      hexpand = true
    };
    _blank_rows = new Switch() {
      halign = Align.END
    };
    _blank_rows.notify["active"].connect(() => {
      var table = get_current_table();
      table.blank_rows = _blank_rows.active;
    });
    brbox.append( brlbl );
    brbox.append( _blank_rows );

    var blank_mi = new GLib.MenuItem( null, null );
    blank_mi.set_attribute( "custom", "s", "blank" );

    /* Add header sizing switch */
    var asbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    var aslbl = new Label( _( "Enable Header Auto-Sizing" ) ) {
      halign = Align.START,
      hexpand = true
    };
    _auto_sizing = new Switch() {
      halign = Align.END
    };
    _auto_sizing.notify["active"].connect(() => {
			var table = get_current_table();
			table.auto_sizing = _auto_sizing.active;
    });
		asbox.append( aslbl );
		asbox.append( _auto_sizing );

    var size_mi = new GLib.MenuItem( null, null );
    size_mi.set_attribute( "custom", "s", "size" );

    /* Add the Markdown switch */
    var mbox = new Box( Orientation.HORIZONTAL, 10 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    var mlbl = new Label( _( "Enable Markdown Highlighting" ) ) {
      halign = Align.START,
      hexpand = true
    };
    _markdown = new Switch() {
      halign = Align.END
    };
    _markdown.notify["active"].connect(() => {
      var table = get_current_table();
      table.markdown = _markdown.active;
    });
    mbox.append( mlbl );
    mbox.append( _markdown );

    var markdown_mi = new GLib.MenuItem( null, null );
    markdown_mi.set_attribute( "custom", "s", "markdown" );

    var top_menu = new GLib.Menu();
    top_menu.append_item( zoom_mi );
    top_menu.append_item( theme_mi );
    top_menu.append_item( list_type_mi );
    top_menu.append_item( condensed_mi );
    top_menu.append_item( tasks_mi );
    top_menu.append_item( depth_mi );
    top_menu.append_item( blank_mi );
    top_menu.append_item( size_mi );
    top_menu.append_item( markdown_mi );

    var misc_menu = new GLib.Menu();
    misc_menu.append( _( "Preferences" ),                 "win.action_preferences" );
    misc_menu.append( _( "Shortcuts Cheatsheet" ),        "win.action_shortcuts" );
    misc_menu.append( _( "Enter Distraction-Free Mode" ), "win.action_focus_mode" );

    var menu = new GLib.Menu();
    menu.append_section( null, top_menu );
    menu.append_section( null, misc_menu );

    /* Create the popover and associate it with the menu button */
    var prop_popover = new PopoverMenu.from_model( menu );
    prop_popover.add_child( _zoom,     "zoom" );
    prop_popover.add_child( theme_box, "theme" );
    prop_popover.add_child( ltbox,     "list_type" );
    prop_popover.add_child( cbox,      "condensed" );
    prop_popover.add_child( tbox,      "tasks" );
    prop_popover.add_child( dbox,      "depth" );
    prop_popover.add_child( brbox,     "blank" );
    prop_popover.add_child( asbox,     "size" );
    prop_popover.add_child( mbox,      "markdown" );

    /* Add the button */
    var prop_btn = new MenuButton() {
      icon_name    = get_icon_name( "open-menu" ),
      tooltip_text = _( "Properties" ),
      popover      = prop_popover
    };
    prop_popover.map.connect( properties_clicked );

    _header.pack_end( prop_btn );

  }

  /* Called whenever the themes need to be updated */
  private void update_themes() {

    var settings = Granite.Settings.get_default();
    var dark     = settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    var hide     = true;

    /* Remove all of the themes */
    while( _themes.get_first_child() != null ) {
      _themes.remove( _themes.get_first_child() );
    }

    var names = new Array<string>();
    themes.names( ref names );

    for( int i=0; i<names.length; i++ ) {
      var theme = themes.get_theme( names.index( i ) );
      if( !hide || (theme.prefer_dark == dark) ) {
        var button = _theme_buttons.get( theme.name );
        _themes.append( button );
      }
    }

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
  private void link_type_changed() {
    var selected = _list_types.selected;
    if( selected < NodeListType.LENGTH ) {
      get_current_table( "link_type_changed" ).list_type = (NodeListType)selected;
    }
  }

  /* Displays the save warning dialog window */
  public void show_save_warning( OutlineTable ot ) {

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
    save.get_style_context().add_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    dialog.add_action_widget( save, ResponseType.ACCEPT );

    dialog.set_transient_for( this );
    dialog.set_default_response( ResponseType.ACCEPT );
    dialog.set_title( "" );

    dialog.response.connect((id) => {
      switch( id ) {
        case ResponseType.ACCEPT :
          save_file( ot, true );
          break;
        case ResponseType.CLOSE  :
          if( ot.document.remove() ) {
            _nb.detach_tab( _nb.get_nth_page( _nb.page ) );
          }
          break;
      }
      dialog.destroy();
    });

    dialog.show();

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

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        open_file( dialog.get_file().get_path() );
        get_current_table( "do_open_file" ).grab_focus();
      }
      dialog.destroy();
    });

    dialog.show();

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
          string new_fname = "";
          if( exports.index( i ).filename_matches( fname, out new_fname ) ) {
            new_fname += ".outliner";
            var table = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
            update_title( table );
            if( exports.index( i ).import( fname, table ) ) {
              save_tab_state( get_table( _nb.page ) );
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
  private void on_table_mapped() {
    get_current_table().queue_draw();
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

  /* Allow the user to select a filename to save the document as */
  public void save_file( OutlineTable ot, bool close_tab = false ) {

    FileChooserDialog dialog = new FileChooserDialog( _( "Save File" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Save" ), ResponseType.ACCEPT );
    FileFilter        filter = new FileFilter();

    filter.set_filter_name( _( "Outliner" ) );
    filter.add_pattern( "*.outliner" );
    dialog.add_filter( filter );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var fname = dialog.get_file().get_path();
        if( fname.substring( -9, -1 ) != ".outliner" ) {
          fname += ".outliner";
        }
        ot.document.filename = fname;
        ot.document.save();
        var page = _nb.get_nth_page( _nb.page );
        var tab_label = (Label)_nb.get_tab_label( page );
        tab_label.label = ot.document.label;
        tab_label.tooltip_text = fname;
        update_title( ot );
        save_tab_state( get_table( _nb.page ) );
        if( close_tab ) {
          _nb.detach_tab( _nb.get_nth_page( _nb.page ) );
        } else {
          ot.grab_focus();
        }
      }
      dialog.destroy();
    });

    dialog.show();

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

  /* Displays the preferences window */
  private void action_preferences() {
    var prefs = new Preferences( this, _settings );
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

    var enable = (get_titlebar() == null);

    /* Hide the header bar */
    set_titlebar( enable ? _header : null );
    _nb.show_tabs = enable;
    _settings.set_boolean( "focus-mode", enable );

  }

  /* Returns the height of a single line label */
  public int get_label_height() {
    Requisition min_size, nat_size;
    _stats_chars.get_preferred_size( out min_size, out nat_size );
    return( nat_size.height );
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

