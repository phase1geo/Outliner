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

public class ThemeSolarizedDark : Theme {

  /* Create the theme colors */
  public ThemeSolarizedDark() {

    name  = "solarized_dark";
    label = _( "Solarized Dark" );

    /* Generate the non-link colors */
    even               = get_color( "#002B36" );
    odd                = get_color( "#002B36" );
    background         = get_color( "#002B36" );  // Done
    foreground         = get_color( "#93A1A1" );  // Done
    root_background    = get_color( "#d4d4d4" );
    root_foreground    = get_color( "#000000" );
    nodesel_background = get_color( "#8cd5ff" );  // Done
    nodesel_foreground = get_color( "#000000" );  // Done
    textsel_background = get_color( "#64baff" );  // Done
    textsel_foreground = get_color( "White" );  // Done
    text_cursor        = get_color( "#93A1A1" );  // Done
    symbol_color       = get_color( "#B58900" );
    note_foreground    = get_color( "#f37329" );
    note_background    = get_color( "#001b26" );
    attachable_color   = get_color( "#6C71C4" );
    url                = get_color( "Orange" );
    tag                = get_color( "Red" );
    hilite             = get_color( "Green" );
    syntax             = get_color( "grey" );
    match_foreground   = get_color( "Black" );
    match_background   = get_color( "Gold" );
    markdown_listitem  = get_color( "red" );
    prefer_dark        = true;

  }

}
