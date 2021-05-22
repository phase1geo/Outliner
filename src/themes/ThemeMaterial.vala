/*
* Copyright (c) 2020 (https://github.com/phase1geo/Minder)
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

using Gdk;
using Gtk;

public class ThemeMaterial : Theme {

  /* Create the theme colors */
  public ThemeMaterial() {

    name  = "material";
    label = _( "Material" );

    /* Generate the non-link colors */
    even               = get_color( "#ffffff" );
    odd                = get_color( "#cccccc" );
    background         = get_color( "#121212" );
    foreground         = get_color( "#eeeee" );
    root_background    = get_color( "#d4d4d4" );
    root_foreground    = get_color( "Black" );
    nodesel_background = get_color( "#444444" );
    nodesel_foreground = get_color( "Black" );
    textsel_background = get_color( "#64baff" );
    textsel_foreground = get_color( "White" );
    text_cursor        = get_color( "White" );
    symbol_color       = get_color( "#000000" );
    note_foreground    = get_color( "Grey" );
    note_background    = get_color( "#262626" );
    attachable_color   = get_color( "#9bdb4d" );
    url                = get_color( "Blue" );
    tag                = get_color( "#c00000" );
    hilite             = get_color( "#3689e6" );
    syntax             = get_color( "grey" );
    match_foreground   = get_color( "Black" );
    match_background   = get_color( "Gold" );
    markdown_listitem  = get_color( "red" );
    prefer_dark        = true;

  }

}
