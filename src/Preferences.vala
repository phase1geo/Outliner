/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

public class Preferences : Gtk.Dialog {

  private MainWindow    _win;
  private GLib.Settings _settings;

  /* Constructor */
  public Preferences( MainWindow win, GLib.Settings settings ) {

    Object(
      border_width: 5,
      deletable: false,
      resizable: false,
      title: _("Preferences"),
      transient_for: win
    );

    _win      = win;
    _settings = settings;

    var stack = new Stack();
    stack.margin        = 6;
    stack.margin_bottom = 18;
    stack.margin_top    = 24;
    stack.add_titled( create_behavior(), "behavior", _( "Behavior" ) );
    stack.add_titled( create_appearance(), "appearance", _( "Appearance" ) );

    var switcher = new StackSwitcher();
    switcher.set_stack( stack );
    switcher.halign = Align.CENTER;

    var box = new Box( Orientation.VERTICAL, 0 );
    box.pack_start( switcher, false, true, 0 );
    box.pack_start( stack,    true,  true, 0 );

    get_content_area().add( box );

    /* Create close button at bottom of window */
    var close_button = new Button.with_label( _( "Close" ) );
    close_button.clicked.connect(() => {
      destroy();
    });

    add_action_widget( close_button, 0 );

  }

  private Grid create_behavior() {

    var grid = new Grid();
    var row  = 0;
    grid.column_spacing = 12;
    grid.row_spacing    = 6;

    grid.attach( make_label( _( "Minimize displayed depth lines" ) ), 0, row );
    grid.attach( make_switch( "minimum-depth-line-display" ), 1, row );
    grid.attach( make_info( _( "Only draws depth lines (when enabled) in cases where a row has a sibling row below it." ) ), 2, 0 );
    row++;

    grid.attach( make_label( _( "Automatically make embedded URLs into links" ) ), 0, row );
    grid.attach( make_switch( "auto-parse-embedded-urls" ), 1, row );
    grid.attach( make_info( _( "Specifies if embedded URLs should be automatically highlighted.") ), 2, row );
    row++;

    grid.attach( make_label( _( "Enable Markdown syntax by default" ) ), 0, row );
    grid.attach( make_switch( "default-markdown-enabled" ), 1, row );
    row++;

    grid.attach( make_label( _( "Enable Unicode input" ) ), 0, row );
    grid.attach( make_switch( "default-unicode-enabled" ), 1, row );
    row++;

    grid.attach( make_label( _( "Enable tag auto-completion" ) ), 0, row );
    grid.attach( make_switch( "enable-tag-auto-completion" ), 1, row );
    row++;

    grid.attach( make_label( _( "Maximum auto-completion items shown" ) ), 0, row );
    grid.attach( make_spinner( "max-auto-completion-items", 1, 15, 1 ), 1, row );
    row++;

    return( grid );

  }

  private Grid create_appearance() {

    var grid = new Grid();
    var row  = 0;
    grid.column_spacing = 12;
    grid.row_spacing    = 6;

#if GRANITE_6_OR_LATER
    grid.attach( make_label( _( "Hide themes not matching visual style" ) ), 0, row );
    grid.attach( make_switch( "hide-themes-not-matching-visual-style" ), 1, row );
    row++;
#endif

    grid.attach( make_label( _( "Default theme" ) ), 0, row );
    grid.attach( make_themes(), 1, row, 2 );
    row++;

    grid.attach( make_label( _( "Title font" ) ), 0, row );
    grid.attach( make_font( FontTarget.TITLE, "default-title-font-family", "default-title-font-size" ), 1, row );
    row++;

    grid.attach( make_label( _( "Row font" ) ), 0, row );
    grid.attach( make_font( FontTarget.NAME, "default-row-font-family", "default-row-font-size" ), 1, row );
    row++;

    grid.attach( make_label( _( "Note font" ) ), 0, row );
    grid.attach( make_font( FontTarget.NOTE, "default-note-font-family", "default-note-font-size" ), 1, row );
    row++;

    grid.attach( make_label( _( "Position checkboxes on right" ) ), 0, row );
    grid.attach( make_switch( "checkboxes-on-right" ), 1, row );
    row++;

    grid.attach( make_label( _( "Enable blank rows by default" ) ), 0, row );
    grid.attach( make_switch( "enable-blank-rows" ), 1, row );
    row++;

    grid.attach( make_label( _( "Enable row auto-sizing by default" ) ), 0, row );
    grid.attach( make_switch( "enable-auto-sizing" ), 1, row );
    grid.attach( make_info( _( "Automatically size row fonts based on row depth." ) ), 2, row );
    row++;

    grid.attach( make_label( _( "Auto-size rows up to depth" ) ), 0, row );
    grid.attach( make_spinner( "auto-sizing-depth", 1, 6, 1 ), 1, row );
    row++;

    return( grid );

  }

  /* Creates label */
  private Label make_label( string label ) {
    var w = new Label( label );
    w.halign = Align.END;
    margin_start = 12;
    return( w );
  }

  /* Creates switch */
  private Switch make_switch( string setting ) {
    var w = new Switch();
    w.halign = Align.START;
    w.valign = Align.CENTER;
    _settings.bind( setting, w, "active", SettingsBindFlags.DEFAULT );
    return( w );
  }

  /* Creates spinner */
  private SpinButton make_spinner( string setting, int min_value, int max_value, int step ) {
    var w = new SpinButton.with_range( min_value, max_value, step );
    _settings.bind( setting, w, "value", SettingsBindFlags.DEFAULT );
    return( w );
  }

  /* Creates an information image */
  private Image make_info( string detail ) {
    var w = new Image.from_icon_name( "dialog-information-symbolic", IconSize.MENU );
    w.halign       = Align.START;
    w.tooltip_text = detail;
    return( w );
  }

  /* Creates a font button */
  private FontButton make_font( FontTarget target, string family_setting, string size_setting ) {
    var btn = new FontButton();
    btn.show_style = false;
    btn.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    btn.set_font( _settings.get_string( family_setting ) + " " + _settings.get_int( size_setting ).to_string() );
    btn.font_set.connect(() => {
      var table = _win.get_current_table();
      table.change_font( target, btn.get_font_family().get_name(), (btn.get_font_size() / Pango.SCALE) );
      _settings.set_string( family_setting, btn.get_font_family().get_name() );
      _settings.set_int( size_setting, (btn.get_font_size() / Pango.SCALE) );
    });
    return( btn );
  }

  /* Creates the theme menu button */
  private MenuButton make_themes() {

    var mb  = new MenuButton();
    var mnu = new Gtk.Menu();

    mb.label = _win.themes.get_theme( _settings.get_string( "default-theme" ) ).label;
    mb.popup = mnu;

    /* Get the available theme names */
    var names = new Array<string>();
    _win.themes.names( ref names );

    for( int i=0; i<names.length; i++ ) {
      var name = names.index( i );
      var lbl  = _win.themes.get_theme( name ).label;
      var item = new Gtk.MenuItem.with_label( lbl );
      item.activate.connect(() => {
        _settings.set_string( "default-theme", name );
        mb.label = lbl;
      });
      mnu.add( item );
    }

    mnu.show_all();

    return( mb );

  }

}
