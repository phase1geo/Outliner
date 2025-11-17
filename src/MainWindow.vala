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

public class ShortcutTooltip {
  private Widget _widget;
  private string _label;
  public ShortcutTooltip( Widget w, string l ) {
    _widget = w;
    _label  = l;
  }
  public void set_tooltip( Shortcut? shortcut ) {
    _widget.tooltip_markup = (shortcut == null) ? _label : Utils.tooltip_with_accel( _label, shortcut.get_accelerator() );
  }
}

public class MainWindow : Gtk.ApplicationWindow {

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
  private Box?                        _themes = null;
  private HashMap<string,CheckButton> _theme_buttons;
  private Exports                     _exports;
  private Exporter                    _exporter;
  private UnicodeInsert               _unicoder;
  private Label                       _info_label;
  private SimpleActionGroup           _actions;
  private Shortcuts                   _shortcuts;
  private Gee.HashMap<KeyCommand, ShortcutTooltip> _shortcut_widgets;

  private bool on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";

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
  public Shortcuts shortcuts {
    get {
      return( _shortcuts );
    }
  }

  public static Themes themes = new Themes();
  public static bool   enable_tag_completion = true;

  private delegate void ChangedFunc();

  public signal void canvas_changed( OutlineTable? ot );

  //-------------------------------------------------------------
  // Create the main window UI
  public MainWindow( Gtk.Application app ) {

    Object( application: app );

    // Initialize variables
    _theme_buttons = new HashMap<string,CheckButton>();

    var window_w = Outliner.settings.get_int( "window-w" );
    var window_h = Outliner.settings.get_int( "window-h" );

    // Create the exports and load it
    _exports = new Exports();

    // Unicoder
    _unicoder = new UnicodeInsert();

    var focus_mode = Outliner.settings.get_boolean( "focus-mode" );

    enable_tag_completion = Outliner.settings.get_boolean( "enable-tag-auto-completion" );

    // Add the theme CSS
    themes.add_css();

    // Create the header bar
    _header = new HeaderBar() {
      show_title_buttons = true,
      title_widget = new Label( _( "Outliner" ) )
    };
    _header.get_style_context().add_class( "outliner-toolbar" );
    _header.get_style_context().add_class( "titlebar" );

    set_titlebar( _header );

    // Set the main window data
    set_default_size( window_w, window_h );

    // Load the user shortcuts
    _shortcuts = new Shortcuts();
    _shortcuts.shortcut_changed.connect( shortcut_changed );

    _shortcut_widgets = new Gee.HashMap<KeyCommand, ShortcutTooltip>();

    // Set the stage for menu actions
    _actions = new SimpleActionGroup();
    insert_action_group( "win", _actions );

    // Add keyboard shortcuts
    add_keyboard_shortcuts( app );

    _nb = new Notebook() {
      scrollable = true,
      halign  = Align.FILL,
      valign  = Align.FILL,
      hexpand = true,
      vexpand = true
    };
    _nb.switch_page.connect( tab_switched );
    _nb.page_reordered.connect( tab_reordered );
    _nb.page_removed.connect( tab_removed );

    // Set shortcuts until we have a tab menu
    set_action_for_command( KeyCommand.TAB_GOTO_NEXT );
    set_action_for_command( KeyCommand.TAB_GOTO_PREV );
    set_action_for_command( KeyCommand.TAB_CLOSE_CURRENT );

    // Create title toolbar
    var new_btn = new Button.from_icon_name( get_icon_name( "document-new" ) );
    register_widget_for_shortcut( new_btn, KeyCommand.FILE_NEW, _( "New File" ) );
    new_btn.clicked.connect(() => { execute_command( KeyCommand.FILE_NEW ); });
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( get_icon_name( "document-open" ) );
    register_widget_for_shortcut( open_btn, KeyCommand.FILE_OPEN, _( "Open File" ) );
    new_btn.clicked.connect(() => { execute_command( KeyCommand.FILE_OPEN ); });
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( get_icon_name( "document-save-as" ) );
    register_widget_for_shortcut( save_btn, KeyCommand.FILE_SAVE_AS, _( "Save File As" ) );
    save_btn.clicked.connect(() => { execute_command( KeyCommand.FILE_SAVE_AS ); });
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( get_icon_name( "edit-undo" ) ) {
      sensitive = false
    };
    register_widget_for_shortcut( _undo_btn, KeyCommand.UNDO_ACTION, _( "Undo" ) );
    _undo_btn.clicked.connect(() => { execute_command( KeyCommand.UNDO_ACTION ); });
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( get_icon_name( "edit-redo" ) ) {
      sensitive = false
    };
    register_widget_for_shortcut( _redo_btn, KeyCommand.REDO_ACTION, _( "Redo" ) );
    _redo_btn.clicked.connect(() => { execute_command( KeyCommand.REDO_ACTION ); });
    _header.pack_start( _redo_btn );

    // Add the buttons on the right side in the reverse order
    add_properties_button();
    add_export_button();
    add_stats_button();
    add_search_button();

    child = _nb;
    show();

    // Listen for changes to the system dark mode
    var granite_settings = Granite.Settings.get_default();
    granite_settings.notify["prefers-color-scheme"].connect( () => {
      update_themes( "prefers-color-scheme" );
    });

  }

  //-------------------------------------------------------------
  // Returns the next tab in the tabbar.
  public void next_tab() {
    _nb.next_page();
  }

  //-------------------------------------------------------------
  // Returns the previous tab in the tabbar.
  public void previous_tab() {
    _nb.prev_page();
  }

  //-------------------------------------------------------------
  // Returns the name of the icon to use for a headerbar icon
  private string get_icon_name( string icon_name ) {
    return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
  }

  //-------------------------------------------------------------
  // Returns the OutlineTable associated with the given notebook
  // page
  public OutlineTable get_table( int page ) {
    var pg = _nb.get_nth_page( page );
    var sw = (ScrolledWindow)Utils.get_child_at_index( pg, 1 );
    var vp = (Viewport)sw.child;
    var ol = (Overlay)vp.child;
    var ot = (OutlineTable)ol.child;
    return( ot );
  }

  //-------------------------------------------------------------
  // Returns the current drawing area
  public OutlineTable? get_current_table( string? caller = null ) {
    if( _debug && (caller != null) ) {
      stdout.printf( "get_current_table called from %s\n", caller );
    }
    if( _nb.get_n_pages() == 0 ) { return( null ); }
    return( get_table( _nb.page ) );
  }

  //-------------------------------------------------------------
  // Shows or hides the search bar for the current tab
  private void toggle_search_bar() {
    var revealer = Utils.get_child_at_index( _nb.get_nth_page( _nb.page ), 0 ) as Revealer;
    if( revealer != null ) {
      var bar    = (SearchBar)revealer.child;
      var reveal = !revealer.reveal_child;
      revealer.reveal_child = reveal;
      bar.change_display( reveal );
    }
  }

  //-------------------------------------------------------------
  // Shows or hides the information bar, setting the message to
  // the given value
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

  //-------------------------------------------------------------
  // Updates the title
  private void update_title( OutlineTable? ot ) {
    var suffix = " \u2014 Outliner";
    var title  = (Label)_header.title_widget;
    if( (ot == null) || !ot.document.is_saved() ) {
      title.label = _( "Unnamed Document" ) + suffix;
    } else {
      title.label = GLib.Path.get_basename( ot.document.filename ) + suffix;
    }
  }

  //-------------------------------------------------------------
  // This needs to be called whenever the tab is changed
  private void tab_changed( OutlineTable ot ) {
    do_buffer_changed( ot.undo_buffer );
    update_title( ot );
    canvas_changed( ot );
    ot.update_theme();
    ot.grab_focus();
    save_tab_state( "tab-changed" );
  }

  //-------------------------------------------------------------
  // Called whenever the current tab is switched in the notebook
  private void tab_switched( Widget page, uint page_num ) {
    tab_changed( get_table( (int)page_num ) );
  }

  //-------------------------------------------------------------
  // Called whenever the current tab is moved to a new position
  private void tab_reordered( Widget page, uint page_num ) {
    save_tab_state( "tab-reordered" );
  }

  //-------------------------------------------------------------
  // Called whenever the current tab is moved to a new position
  private void tab_removed( Widget page, uint page_num ) {
    save_tab_state( "tab-removed");
  }

  //-------------------------------------------------------------
  // Closes the current tab
  public void close_current_tab() {
    close_tab( _nb.page );
  }

  //-------------------------------------------------------------
  // Closes the tab at the given location
  public void close_tab( int page ) {
    if( _nb.get_n_pages() == 1 ) return;
    var ot = get_table( _nb.page );
    if( ot.document.is_saved() ) {
      _nb.detach_tab( _nb.get_nth_page( _nb.page ) );
    } else {
      show_save_warning( ot );
    }
  }

  //-------------------------------------------------------------
  // Adds a new tab to the notebook
  public OutlineTable add_tab( string? fname, TabAddReason reason ) {

    stdout.printf( "In add_tab\n" );

    // Create and pack the canvas
    var ot = new OutlineTable( this );
    ot.map.connect( on_table_mapped );
    ot.undo_buffer.buffer_changed.connect( do_buffer_changed );
    ot.undo_text.buffer_changed.connect( do_buffer_changed );
    ot.theme_changed.connect( theme_changed );
    ot.focus_mode.connect( show_info_bar );
    ot.nodes_filtered.connect( show_info_bar );

    if( fname != null ) {
      ot.document.filename = fname;
    }

    // Create the overlay that will hold the canvas so that we can put an entry box for emoji support
    var overlay = new Overlay() {
      child = ot
    };

    // Create the scrolled window for the treeview
    var scroll = new ScrolledWindow() {
      halign = Align.FILL,
      valign = Align.FILL,
      hexpand = true,
      vexpand = true,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      hscrollbar_policy = PolicyType.EXTERNAL,
      child = overlay
    };

    // Create the search bar
    var search = new SearchBar( ot );
    var search_reveal = new Revealer() {
      halign = Align.FILL,
      child = search
    };

    // Create the info bar
    var info_bar = create_info_bar();

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( search_reveal );
    box.append( scroll );
    box.append( info_bar );

    var tab_label = new Label( ot.document.label ) {
      margin_start  = 10,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      tooltip_text  = ot.document.filename
    };

    var tab_close = new Button.from_icon_name( "window-close-symbolic" ) {
      has_frame     = false,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };

    var tab_revealer = new Revealer() {
      reveal_child = true,
      transition_type = RevealerTransitionType.CROSSFADE,
      child = tab_close
    };

    var tab_focus = new EventControllerMotion();
    var tab_box = new Box( Orientation.HORIZONTAL, 5 );
    tab_box.add_controller( tab_focus );
    tab_box.append( tab_label );
    tab_box.append( tab_revealer );

    // We need to unreveal the close button
    var other_page = _nb.get_nth_page( _nb.page );
    if( other_page != null ) {
      var label    = _nb.get_tab_label( other_page );
      var revealer = (Revealer)Utils.get_child_at_index( label, 1 );
      revealer.reveal_child = false;
    }

    // Add the page to the notebook
    var tab_index = _nb.append_page( box, tab_box );

    tab_focus.enter.connect((x, y) => {
      if( _nb.get_n_pages() > 1 ) {
        tab_revealer.reveal_child = true;
      }
    });
    tab_focus.leave.connect(() => {
      if( _nb.page != tab_index ) {
        tab_revealer.reveal_child = false;
      }
    });

    tab_close.clicked.connect(() => {
      close_tab( tab_index );
    });

    // Update the titlebar
    update_title( ot );

    // Make the drawing area new
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

  //-------------------------------------------------------------
  // Checks to see if any other tab contains the given filename.
  // If the filename is already found, refresh the tab with the
  // file contents and make it the current tab; otherwise, add
  // the new tab and populate it.
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

  //-------------------------------------------------------------
  // Creates the info bar UI
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

  //-------------------------------------------------------------
  // Save the current tab state
  private void save_tab_state(string msg = "") {

    stdout.printf( "In save_tab_state, msg: %s\n", msg );

    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "outliner" );

    if( DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return;
    }

    var       fname = GLib.Path.build_filename( dir, "tab_state.xml" );
    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "tabs" );

    doc->set_root_element( root );

    stdout.printf( "Saving tab state, n_pages: %u\n", _nb.get_n_pages() );

    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var table = get_table( i );
      Xml.Node* node  = new Xml.Node( null, "tab" );
      node->new_prop( "path",  table.document.filename );
      node->new_prop( "saved", table.document.is_saved().to_string() );
      root->add_child( node );
    }

    root->new_prop( "selected", _nb.page.to_string() );

    // Save the file
    doc->save_format_file( fname, 1 );

    delete doc;

  }

  //-------------------------------------------------------------
  // Returns the path of the tab_state.xml file.
  private string get_tab_state_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "outliner", "tab_state.xml" ) );
  }

  //-------------------------------------------------------------
  // Loads the tab state
  public void load_tab_state() {

    var tab_state = GLib.Path.build_filename( Environment.get_user_data_dir(), "outliner", "tab_state.xml" );
    var tabs      = 0;

    // If the file does not exist, skip the rest and return false
    if( !FileUtils.test( tab_state, FileTest.EXISTS ) ) {
      do_new_file();
      return;
    }

    Xml.Doc* doc = Xml.Parser.parse_file( tab_state );

    if( doc == null ) {
      do_new_file();
      return;
    }

    var root = doc->get_root_element();
    var tab_skipped = false;

    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tab") ) {
        var fname = it->get_prop( "path" );
        if( FileUtils.test( fname, FileTest.EXISTS ) ) {
          var saved = it->get_prop( "saved" );
          var table = add_tab( fname, TabAddReason.LOAD );
          table.document.load_filename( fname, bool.parse( saved ) );
          table.document.load();
          tabs++;
        } else {
          tab_skipped = true;
        }
      }
    }

    if( tabs == 0 ) {
      do_new_file();
    } else {
      var s = root->get_prop( "selected" );
      if( s != null ) {
        stdout.printf( "Setting current tab to %d\n", _nb.page );
        _nb.page = int.parse( s );
      }
    }

    if( (tabs == 0) || tab_skipped ) {
      save_tab_state( "load-tab-state" );
    }

    delete doc;

  }

  //-------------------------------------------------------------
  // Adds keyboard shortcuts for the menu actions
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
    app.set_accels_for_action( "win.action_preferences", { "<Control>comma" } );
    app.set_accels_for_action( "win.action_shortcuts",   { "<Control>question" } );
    app.set_accels_for_action( "win.action_focus_mode",  { "F2" } );
    app.set_accels_for_action( "win.action_zoom_in",     { "<Control>plus", "<Control>equal" } );
    app.set_accels_for_action( "win.action_zoom_out",    { "<Control>minus" } );
    app.set_accels_for_action( "win.action_zoom_actual", { "<Control>0" } );

  }

  //-------------------------------------------------------------
  // Adds the search functionality
  private void add_search_button() {

    // Create the menu button
    _search_btn = new Button.from_icon_name( get_icon_name( "edit-find" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "Search" ), "<Control>f" )
    };
    _search_btn.clicked.connect( toggle_search_bar );
    _header.pack_end( _search_btn );

  }

  //-------------------------------------------------------------
  // Adds a statistic row to the given grid, returning the created
  // value label
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

  //-------------------------------------------------------------
  // Adds the statistics functionality
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

    // Add the button to the header bar
    _header.pack_end( stats_btn );

  }

  //-------------------------------------------------------------
  // Toggle the statistics bar
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

  //-------------------------------------------------------------
  // Adds the export functionality
  private void add_export_button() {

    // Create export menu
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

    // Create the menu button
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

    update_themes( "create-theme-selector" );

    return( theme_box );

  }

  //-------------------------------------------------------------
  // Adds the property functionality
  private void add_properties_button() {

    // Add zoom widget
    _zoom = new ZoomWidget( 100, 225, 25 ) {
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    _zoom.zoom_changed.connect( zoom_changed );

    var zoom_mi = new GLib.MenuItem( null, null );
    zoom_mi.set_attribute( "custom", "s", "zoom" );

    // Add theme selector
    var theme_box = create_theme_selector();

    var theme_mi = new GLib.MenuItem( null, null );
    theme_mi.set_attribute( "custom", "s", "theme" );

    // Add list type selector
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

    // Add condensed mode switch
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

    // Add show tasks switch
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

    // Add show depth switch
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

    // Add blank rows switch
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

    // Add header sizing switch
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

    // Add the Markdown switch
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
    append_menu_item( misc_menu, KeyCommand.SHOW_PREFERENCES,  _( "Preferences" ) );
    append_menu_item( misc_menu, KeyCommand.SHOW_SHORTCUTS,    _( "Shortcuts Cheatsheet" ) );
    append_menu_item( misc_menu, KeyCommand.TOGGLE_FOCUS_MODE, _( "Enter Distraction-Free Mode" ) );

    var menu = new GLib.Menu();
    menu.append_section( null, top_menu );
    menu.append_section( null, misc_menu );

    // Create the popover and associate it with the menu button
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

    // Add the button
    var prop_btn = new MenuButton() {
      icon_name    = get_icon_name( "open-menu" ),
      tooltip_text = _( "Properties" ),
      popover      = prop_popover
    };
    prop_popover.map.connect( properties_clicked );

    _header.pack_end( prop_btn );

  }

  //-------------------------------------------------------------
  // Called whenever the themes need to be updated
  private void update_themes( string msg = "" ) {

    if( _themes == null ) {
      stdout.printf( "Attempting to update themes before _themes is allocated: %s\n", msg );
      return;
    }

    var settings = Granite.Settings.get_default();
    var dark     = settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
    var hide     = true;

    // Remove all of the themes
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

  //-------------------------------------------------------------
  // Returns the current zoom factor
  public double get_zoom_factor() {
    return( _zoom.factor );
  }

  //-------------------------------------------------------------
  // Called whenever the user changes the zoom level
  private void zoom_changed( double factor ) {

    var table = get_current_table( "zoom_changed" );

    table.zoom_changed();
    queue_draw();

  }

  //-------------------------------------------------------------
  // Causes the link type to change
  private void link_type_changed() {
    var selected = _list_types.selected;
    if( selected < NodeListType.LENGTH ) {
      get_current_table( "link_type_changed" ).list_type = (NodeListType)selected;
    }
  }

  //-------------------------------------------------------------
  // Displays the save warning dialog window
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

  //-------------------------------------------------------------
  // Creates a new document and adds it to the notebook
  public void do_new_file() {

    var ot = add_tab( null, TabAddReason.NEW );

    // Set the title to indicate that we have a new document
    update_title( ot );

  }

  //-------------------------------------------------------------
  // Allow the user to open a Outliner file
  public void do_open_file() {

    // Get the file to open from the user
    FileChooserNative dialog = new FileChooserNative( _( "Open File" ), this, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );

    // Create file filters
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

  //-------------------------------------------------------------
  // Opens the file and display it in the table
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
              save_tab_state( "open-file" );
              return( true );
            }
            close_current_tab();
          }
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Perform an undo action
  public void do_undo() {
    var table = get_current_table( "do_undo" );
    if( table.is_node_editable() || table.is_note_editable() ) {
      table.undo_text.undo();
    } else {
      table.undo_buffer.undo();
    }
    table.grab_focus();
  }

  //-------------------------------------------------------------
  // Perform a redo action
  public void do_redo() {
    var table = get_current_table( "do_redo" );
    if( table.is_node_editable() || table.is_note_editable() ) {
      table.undo_text.redo();
    } else {
      table.undo_buffer.redo();
    }
    table.grab_focus();
  }

  //-------------------------------------------------------------
  // Called when the outline table is initially mapped
  private void on_table_mapped() {
    get_current_table().queue_draw();
  }

  //-------------------------------------------------------------
  // Called whenever the theme is changed
  private void theme_changed( OutlineTable ot ) {
    Gtk.Settings? settings = Gtk.Settings.get_default();
    if( settings != null ) {
      settings.gtk_application_prefer_dark_theme = ot.get_theme().prefer_dark;
    }
  }

  //-------------------------------------------------------------
  // Called whenever the undo buffer changes state.  Updates the
  // state of the undo and redo buffer buttons.
  public void do_buffer_changed( UndoBuffer buf ) {
    _undo_btn.set_sensitive( buf.undoable() );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.undo_tooltip(), "<Control>z" ) );
    _redo_btn.set_sensitive( buf.redoable() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.redo_tooltip(), "<Control><Shift>z" ) );
  }

  //-------------------------------------------------------------
  // Allow the user to select a filename to save the document as
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
        var tab_box = (Box)_nb.get_tab_label( page );
        var tab_label = (Label)Utils.get_child_at_index( tab_box, 0 );
        tab_label.label = ot.document.label;
        tab_label.tooltip_text = fname;
        update_title( ot );
        save_tab_state( "save-file" );
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

  //-------------------------------------------------------------
  // Called when the save as button is clicked
  public void do_save_as_file() {
    save_file( get_current_table( "do_save_as_file" ) );
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-n keyboard shortcut
  private void action_new() {
    do_new_file();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-o keyboard shortcut
  private void action_open() {
    do_open_file();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-s keyboard shortcut
  private void action_save() {
    var table = get_current_table( "action_save" );
    if( table.document.is_saved() ) {
      table.document.save();
    } else {
      save_file( table );
    }
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-f keyboard shortcut
  public void do_search() {
    _search_btn.clicked();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-Plus/Equal shortcut
  public void do_zoom_in() {
    _zoom.zoom_in();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-Minus shortcut
  public void do_zoom_out() {
    _zoom.zoom_out();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-0 shortcut
  public void do_zoom_actual() {
    _zoom.zoom_actual();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-q keyboard shortcut
  private void action_quit() {
    destroy();
  }

  //-------------------------------------------------------------
  // Checks the given filename to see if it contains any of the
  // given suffixes.  If a valid suffix is found, return the
  // filename without modification; otherwise, returns the
  // filename with the extension added.
  public string repair_filename( string fname, string[] extensions ) {
    foreach (string ext in extensions) {
      if( fname.has_suffix( ext ) ) {
        return( fname );
      }
    }
    return( fname + extensions[0] );
  }

  //-------------------------------------------------------------
  // Called whenever the properties button is clicked
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

  //-------------------------------------------------------------
  // Hides the header bar
  public void toggle_focus_mode() {

    var enable = _header.visible;

    // Hide the header bar
    if( enable ) {
      get_titlebar().hide();
      fullscreen();
    } else {
      get_titlebar().show();
      unfullscreen();
    }

    _nb.show_tabs = !enable;
    Outliner.settings.set_boolean( "focus-mode", enable );

  }

  //-------------------------------------------------------------
  // Returns the height of a single line label
  public int get_label_height() {
    Requisition min_size, nat_size;
    _stats_chars.get_preferred_size( out min_size, out nat_size );
    return( nat_size.height );
  }

  //-------------------------------------------------------------
  // Generate a notification
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

  //-------------------------------------------------------------
  // SHORTCUT HANDLING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Adds and action for the given command.
  private void set_action_for_command( KeyCommand command ) {

    // Create action to execute
    var action = new SimpleAction( command.to_string(), null );
    action.activate.connect((v) => {
      var func = command.get_func();
      func( get_current_table( "set_action_for_command" ) );
    });
    _actions.add_action( action );

    var shortcut = shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      application.set_accels_for_action( "win.%s".printf( command.to_string() ), { shortcut.get_accelerator() } );
    }

  }

  //-------------------------------------------------------------
  // Appends a command with the given command to the specified menu.
  private void append_menu_item( GLib.Menu menu, KeyCommand command, string label ) {
    menu.append( label, "win.%s".printf( command.to_string() ) );
    set_action_for_command( command );
  }

  //-------------------------------------------------------------
  // Registers a widget when only a tooltip label update
  // is needed.
  public void register_widget_for_tooltip( Gtk.Widget w, KeyCommand command, string label ) {
    var tooltip = new ShortcutTooltip( w, label );
    _shortcut_widgets.set( command, tooltip );
    var shortcut = shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      tooltip.set_tooltip( shortcut );
    }
  }

  //-------------------------------------------------------------
  // Updates registers for shortcuts
  public void register_widget_for_shortcut( Gtk.Widget w, KeyCommand command, string label ) {
    register_widget_for_tooltip( w, command, label );
    set_action_for_command( command );
  }

  //-------------------------------------------------------------
  // Handles any changes to shortcuts.  If a shortcut is used by
  // the main window, update the shortcut and associated tooltips.
  private void shortcut_changed( KeyCommand command, Shortcut? shortcut ) {
    var action = _actions.lookup_action( command.to_string() );
    if( action != null ) {
      var detail_name = "win.%s".printf( command.to_string() );
      if( shortcut == null ) {
        application.set_accels_for_action( detail_name, {} );
      } else {
        application.set_accels_for_action( detail_name, { shortcut.get_accelerator() } );
      }
    }
    if( _shortcut_widgets.has_key( command ) ) {
      _shortcut_widgets.get( command ).set_tooltip( shortcut );
    }
  }

  //-------------------------------------------------------------
  // Returns the shortcut accelerator associated with the given
  // key command.
  private string get_accelerator( KeyCommand command ) {
    var shortcut = shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      return( shortcut.get_accelerator() );
    }
    return( "" );
  }

  //-------------------------------------------------------------
  // Execute command.
  public void execute_command( KeyCommand command ) {
    var func = command.get_func();
    func( get_current_table( "execute_command" ) );
  }

}

