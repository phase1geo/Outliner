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
using Gdk;

public class Theme : Object {

  public    string name               { protected set; get; }
  public    string label              { protected set; get; }
  public    RGBA   even               { protected set; get; }
  public    RGBA   odd                { protected set; get; }
  public    RGBA   background         { protected set; get; }
  public    RGBA   foreground         { protected set; get; }
  public    RGBA   root_background    { protected set; get; }
  public    RGBA   root_foreground    { protected set; get; }
  public    RGBA   nodesel_background { protected set; get; }
  public    RGBA   nodesel_foreground { protected set; get; }
  public    RGBA   textsel_background { protected set; get; }
  public    RGBA   textsel_foreground { protected set; get; }
  public    RGBA   text_cursor        { protected set; get; }
  public    RGBA   symbol_color       { protected set; get; }
  public    RGBA   note_color         { protected set; get; }
  public    RGBA   attachable_color   { protected set; get; }
  public    bool   prefer_dark        { protected set; get; }

  public    RGBA   color1             { protected set; get; }
  public    RGBA   color2             { protected set; get; }
  public    RGBA   color3             { protected set; get; }
  public    RGBA   color4             { protected set; get; }
  public    RGBA   hilite1            { protected set; get; }
  public    RGBA   hilite2            { protected set; get; }
  public    RGBA   hilite3            { protected set; get; }
  public    RGBA   hilite4            { protected set; get; }
  public    RGBA   url                { protected set; get; }

  /* Default constructor */
  public Theme() {}

  /* Returns the RGBA color for the given color value */
  protected RGBA get_color( string value ) {

    RGBA c = {1.0, 1.0, 1.0, 1.0};
    c.parse( value );

    return( c );

  }

  /* Returns the CSS provider for this theme */
  public CssProvider get_css_provider() {

    CssProvider provider = new CssProvider();

    try {
      var css_data = "@define-color colorPrimary @ORANGE_700; " +
                     "@define-color textColorPrimary @SILVER_100; " +
                     "@define-color colorAccent @ORANGE_700; " +
                     ".canvas { background: " + background.to_string() + "; }";
      provider.load_from_data( css_data );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to load background color: %s\n", e.message );
    }

    return( provider );

  }

}
