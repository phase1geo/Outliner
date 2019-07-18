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

public class FormatBar : Box {

  private OutlineTable _table;
  private ToggleButton _bold;
  private ToggleButton _italics;
  private ToggleButton _underline;
  private ToggleButton _strike;

  /* Construct the formatting bar */
  public FormatBar( OutlineTable table ) {

    Object( orientation:Orientation.HORIZONTAL, spacing:0 );

    _table = table;

    _bold = new ToggleButton();
    _bold.image  = new Image.from_icon_name( "format-text-bold-symbolic", IconSize.SMALL_TOOLBAR );
    _bold.relief = ReliefStyle.NONE;
    _bold.set_tooltip_markup( Utils.tooltip_with_accel( _( "Bold" ), "Ctrl + B" ) );
    _bold.toggled.connect( handle_bold );

    _italics = new ToggleButton();
    _italics.image  = new Image.from_icon_name( "format-text-italic-symbolic", IconSize.SMALL_TOOLBAR );
    _italics.relief = ReliefStyle.NONE;
    _italics.set_tooltip_markup( Utils.tooltip_with_accel( _( "Italic" ), "Ctrl + I" ) );
    _italics.toggled.connect( handle_italics );

    _underline = new ToggleButton();
    _underline.image  = new Image.from_icon_name( "format-text-underline-symbolic", IconSize.SMALL_TOOLBAR );
    _underline.relief = ReliefStyle.NONE;
    _underline.set_tooltip_text( _( "Underline" ) );
    _underline.toggled.connect( handle_underline );

    _strike = new ToggleButton();
    _strike.image  = new Image.from_icon_name( "format-text-strikethrough-symbolic", IconSize.SMALL_TOOLBAR );
    _strike.relief = ReliefStyle.NONE;
    _strike.set_tooltip_text( _( "Strikethrough" ) );
    _strike.toggled.connect( handle_strikethru );

    pack_start( _bold,      false, false, 0 );
    pack_start( _italics,   false, false, 0 );
    pack_start( _underline, false, false, 0 );
    pack_start( _strike,    false, false, 0 );

    show_all();

  }

  private void format_text( FormatTag tag ) {
    if( _table.selected.mode == NodeMode.EDITABLE ) {
      _table.selected.name.add_tag( tag );
    } else {
      _table.selected.note.add_tag( tag );
    }
  }

  private void handle_bold() {
    format_text( FormatTag.BOLD );
  }

  private void handle_italics() {
    format_text( FormatTag.ITALICS );
  }

  private void handle_underline() {
    format_text( FormatTag.UNDERLINE );
  }

  private void handle_strikethru() {
    format_text( FormatTag.STRIKETHRU );
  }

}
