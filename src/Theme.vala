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

public class Theme : Object {

  public    string name               { protected set; get; }
  public    string label              { protected set; get; }
  public    RGBA   even               { protected set; get; }
  public    RGBA   odd                { protected set; get; }
  public    RGBA   background         { protected set; get; }
  public    RGBA   foreground         { protected set; get; }
  public    RGBA   title_background   { protected set; get; }
  public    RGBA   title_foreground   { protected set; get; }
  public    RGBA   root_background    { protected set; get; }
  public    RGBA   root_foreground    { protected set; get; }
  public    RGBA   nodesel_background { protected set; get; }
  public    RGBA   nodesel_foreground { protected set; get; }
  public    RGBA   textsel_background { protected set; get; }
  public    RGBA   textsel_foreground { protected set; get; }
  public    RGBA   text_cursor        { protected set; get; }
  public    RGBA   symbol_color       { protected set; get; }
  public    RGBA   note_foreground    { protected set; get; }
  public    RGBA   note_background    { protected set; get; }
  public    RGBA   attachable_color   { protected set; get; }
  public    bool   prefer_dark        { protected set; get; }

  public    RGBA   hilite             { protected set; get; }
  public    RGBA   url                { protected set; get; }
  public    RGBA   tag                { protected set; get; }
  public    RGBA   syntax             { protected set; get; }
  public    RGBA   match_foreground   { protected set; get; }
  public    RGBA   match_background   { protected set; get; }
  public    RGBA   markdown_listitem  { protected set; get; }

  /* Default constructor */
  public Theme() {}

  /* Returns the RGBA color for the given color value */
  protected RGBA get_color( string value ) {

    RGBA c = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
    c.parse( value );

    return( c );

  }

  /* Returns the CSS provider for this theme */
  public CssProvider get_css_provider() {

    var provider = new CssProvider();

    try {
      var css_data = "@define-color tab_base_color " + background.to_string() + ";" +
                     ".canvas { background: " + background.to_string() + "; } " +
                     ".color_chooser { padding-right: 0px; padding-left: 0px; margin-right: 0px; margin-left: 0px; }";
      provider.load_from_data( css_data.data );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to load theme: %s\n", e.message );
    }

    return( provider );

  }

}
