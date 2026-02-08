/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Outliner)
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

public enum ColorPickerType {
  HCOLOR,
  FCOLOR;

  public string get_css_class() {
    switch( this ) {
      case HCOLOR :  return( "hcolor" );
      case FCOLOR :  return( "fcolor" );
      default     :  assert_not_reached();
    }
  }

  public void set_image( ToggleButton btn ) {
    switch( this ) {
      case HCOLOR :
        btn.icon_name = "format-text-highlight";
        break;
      case FCOLOR :  {
        var lbl = new Label( "<span size=\"large\">A</span>" ) {
          use_markup = true
        };
        btn.child = lbl;
        break;
      }
      default     :  assert_not_reached();
    }
  }

}

public class ColorPicker : Box {

  private ColorPickerType    _type;
  private ToggleButton       _toggle;
  private ColorChooserWidget _chooser;
  private MenuButton         _select;
  private bool               _ignore_active;
  private RGBA               _bg_color;
  private RGBA               _fg_color;

  public string toggle_tooltip {
    get {
      return( _toggle.get_tooltip_text() );
    }
    set {
      _toggle.set_tooltip_text( value );
    }
  }

  public string select_tooltip {
    get {
      return( _select.get_tooltip_text() );
    }
    set {
      _select.set_tooltip_text( value );
    }
  }

  public signal void color_changed( RGBA? color );

  //-------------------------------------------------------------
  // Default constructor.
  public ColorPicker( RGBA init_color, RGBA bg_color, RGBA fg_color, ColorPickerType type ) {

    _type     = type;
    _bg_color = bg_color;
    _fg_color = fg_color;

    _toggle = new ToggleButton() {
      has_frame = false
    };
    _toggle.toggled.connect( handle_toggle );
    _toggle.get_style_context().add_class( type.get_css_class() );

    type.set_image( _toggle );

    _chooser = new ColorChooserWidget() {
      rgba          = init_color,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    var click_controller = new GestureClick();
    var overlay = new Overlay() {
      child = _chooser
    };
    overlay.add_controller( click_controller );

    click_controller.pressed.connect( handle_chooser );

    _select = new MenuButton() {
      has_frame = false
    };
    _select.get_style_context().add_class( "color_chooser" );

    _select.popover = new Popover() {
      child = overlay
    };

    append( _toggle );
    append( _select );

    update_css( init_color );

  }

  //-------------------------------------------------------------
  // Activates or deactivates main button.
  public void set_active( bool active ) {
    _ignore_active = true;
    _toggle.active = active;
    update_css( _chooser.rgba );
    _ignore_active = false;
  }

  //-------------------------------------------------------------
  // Updates the CSS used to display the main toggle button.
  private void update_css( RGBA rgba ) {
    var provider = new CssProvider();
    try {
      var css_data = "";
      if( !_toggle.active ) {
        css_data = "background: %s; color: %s;".printf( Utils.color_from_rgba( _bg_color ), Utils.color_from_rgba( _fg_color ) );
      } else if( _type == ColorPickerType.FCOLOR ) {
        css_data = "background: %s; color: %s;".printf( Utils.color_from_rgba( _bg_color ), Utils.color_from_rgba( rgba ) );
      } else {
        var a = 1.0;
        var r = (rgba.red   * 0.5) + (_bg_color.red   * 0.5);
        var g = (rgba.green * 0.5) + (_bg_color.green * 0.5);
        var b = (rgba.blue  * 0.5) + (_bg_color.blue  * 0.5);
        RGBA bg = {(float)r, (float)g, (float)b, (float)a};
        css_data = "background: %s;".printf( Utils.color_from_rgba( bg ) );
      }
      css_data = ".%s { %s }".printf( _type.get_css_class(), css_data );
      provider.load_from_data( css_data.data );
      StyleContext.add_provider_for_display(
        Display.get_default(),
        provider,
        STYLE_PROVIDER_PRIORITY_APPLICATION
      );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to update css: %s\n", e.message );
    }
  }

  //-------------------------------------------------------------
  // Handles a change to the main toggle button.
  private void handle_toggle() {
    if( !_ignore_active ) {
      update_css( _chooser.rgba );
      if( _toggle.active ) {
        color_changed( _chooser.rgba );
      } else {
        color_changed( null );
      }
    }
  }

  //-------------------------------------------------------------
  // Handles a change to the color chooser widget.
  private void handle_chooser( int n_press, double x, double y ) {
    set_active( true );
    color_changed( _chooser.rgba );
    _select.active = false; // popover.popup();
  }

}
