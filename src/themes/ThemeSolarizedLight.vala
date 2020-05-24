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

public class ThemeSolarizedLight : Theme {

  /* Create the theme colors */
  public ThemeSolarizedLight() {

    name  = "solarized_light";
    label = _( "Solarized Light" );

    /* Generate the non-link colors */
    even               = get_color( "#FDF6E3" );
    odd                = get_color( "#FDF6E3" );
    background         = get_color( "#FDF6E3" );
    foreground         = get_color( "#586E75" );
    root_background    = get_color( "#839496" );
    root_foreground    = get_color( "#FDF6E3" );
    nodesel_background = get_color( "#8cd5ff" );
    nodesel_foreground = get_color( "#555555" );
    textsel_background = get_color( "#64baff" );
    textsel_foreground = get_color( "White" );
    text_cursor        = get_color( "#586E75" );
    symbol_color       = get_color( "#B58900" );
    note_foreground    = get_color( "#268BD2" );
    note_background    = get_color( "#cbc5b6" );  // Background color with value of 50
    attachable_color   = get_color( "#9bdb4d" );
    url                = get_color( "Blue" );
    tag                = get_color( "Red" );
    hilite             = get_color( "yellow" );
    match_foreground   = get_color( "Black" );
    match_background   = get_color( "Gold" );
    markdown_grey      = get_color( "grey" );
    markdown_listitem  = get_color( "red" );
    prefer_dark        = false;

  }

}
