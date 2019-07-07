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
using GLib;

public class Themes : Object {

  private Array<Theme> _themes;

  /* Default constructor */
  public Themes() {

    /* Allocate memory for the themes array */
    _themes = new Array<Theme>();

    /* Create the themes */
    var default_theme         = new ThemeDefault();
    var dark_theme            = new ThemeDark();
    var solarized_light_theme = new ThemeSolarizedLight();
    var solarized_dark_theme  = new ThemeSolarizedDark();

    /* Add the themes to the list */
    _themes.append_val( default_theme );
    _themes.append_val( dark_theme );
    _themes.append_val( solarized_light_theme );
    _themes.append_val( solarized_dark_theme );

  }

  /* Returns a list of theme names */
  public void names( ref Array<string> names ) {
    for( int i=0; i<_themes.length; i++ ) {
      names.append_val( _themes.index( i ).name );
    }
  }

  /* Returns the theme associated with the given name */
  public Theme get_theme( string name ) {
    for( int i=0; i<_themes.length; i++ ) {
      if( name == _themes.index( i ).name ) {
        return( _themes.index( i ) );
      }
    }
    return( _themes.index( 0 ) );
  }

  /* Adds the theme CSS to the screen */
  public void add_css() {
    var provider = new Gtk.CssProvider ();
    var css      = "";
    for( int i=0; i<_themes.length; i++ ) {
      css += "." + _themes.index( i ).name + " radio { background: " + _themes.index( i ).background.to_string() + "; color: " + _themes.index( i ).foreground.to_string() + "; } ";
    }
    try {
      provider.load_from_data( css );
      Gtk.StyleContext.add_provider_for_screen( Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to load theme CSS: %s\n", e.message );
    }
  }

}
