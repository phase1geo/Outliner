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
using Gdk;

public class ColorPicker : Box {

  private string             _css_class;
  private string             _css_property;
  private ToggleButton       _toggle;
  private ColorChooserWidget _chooser;
  private MenuButton         _select;
  private bool               _ignore_active;

  public signal void color_changed( RGBA? color );

  public ColorPicker( RGBA init_color, string css_class, string css_property ) {

    _css_class    = css_class;
    _css_property = css_property;

    var lbl = new Label( "<span size=\"large\">A</span>" );
    lbl.use_markup = true;

    _toggle        = new ToggleButton();
    _toggle.image  = lbl;
    _toggle.relief = ReliefStyle.NONE;
    _toggle.toggled.connect( handle_toggle );
    _toggle.get_style_context().add_class( css_class );

    _chooser = new ColorChooserWidget();
    _chooser.rgba = init_color;

    var overlay = new Overlay();
    overlay.button_press_event.connect( handle_chooser );
    overlay.add( _chooser );
    overlay.show_all();

    _select = new MenuButton();
    _select.relief = ReliefStyle.NONE;
    _select.get_style_context().add_class( "color_chooser" );

    _select.popover = new Popover( null );
    _select.popover.add( overlay );

    pack_start( _toggle, false, false );
    pack_start( _select, false, false );
    show_all();

    update_css( init_color );

  }

  public void set_toggle_tooltip( string tooltip ) {
    _toggle.set_tooltip_text( tooltip );
  }

  public void set_select_tooltip( string tooltip ) {
    _select.set_tooltip_text( tooltip );
  }

  public void set_active( bool active ) {
    _ignore_active = true;
    _toggle.active = active;
    _ignore_active = false;
  }

  private void update_css( RGBA rgba ) {
    var provider = new CssProvider();
    try {
      var color    = Utils.color_from_rgba( rgba );
      var css_data = ".%s { %s: %s; }".printf( _css_class, _css_property, color );
      provider.load_from_data( css_data );
      StyleContext.add_provider_for_screen(
        Screen.get_default(),
        provider,
        STYLE_PROVIDER_PRIORITY_APPLICATION
      );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to update css: %s\n", e.message );
    }
  }

  private void handle_toggle() {
    if( !_ignore_active ) {
      if( _toggle.active ) {
        color_changed( _chooser.rgba );
      } else {
        color_changed( null );
      }
    }
  }

  private bool handle_chooser( EventButton e ) {
    update_css( _chooser.rgba );
    if( _toggle.active ) {
      color_changed( _chooser.rgba );
    }
    _select.popover.popdown();
    return( true );
  }

}
