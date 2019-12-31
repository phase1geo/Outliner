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
  private ColorButton  _hilite;
  private ToggleButton _link;
  private bool         _ignore_active = false;

  /* Construct the formatting bar */
  public FormatBar( OutlineTable table ) {

    Object( orientation:Orientation.HORIZONTAL, spacing:0 );

    _table = table;

    Gdk.RGBA init_hiliter = {1.0, 1.0, 1.0, 1.0};
    init_hiliter.parse( "Yellow" );

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

    _hilite = new ColorButton.with_rgba( init_hiliter );
    //_hilite.image = new Image.from_icon_name( "format-text-highlight", IconSize.SMALL_TOOLBAR );
    _hilite.relief = ReliefStyle.NONE;
    _hilite.set_tooltip_text( _( "Highlight" ) );
    _hilite.color_set.connect( handle_highlighter );

    _link = new ToggleButton();
    _link.image = new Image.from_icon_name( "insert-link-symbolic", IconSize.SMALL_TOOLBAR );
    _link.relief = ReliefStyle.NONE;
    _link.set_tooltip_text( _( "Link" ) );
    _link.toggled.connect( handle_link );

    pack_start( _bold,      false, false, 0 );
    pack_start( _italics,   false, false, 0 );
    pack_start( _underline, false, false, 0 );
    pack_start( _strike,    false, false, 0 );
    pack_start( _hilite,    false, false, 0 );
    pack_start( _link,      false, false, 0 );

    show_all();

  }

  /* TBD - This method may no longer be necessary */
  public void set_theme( Theme theme ) {
  }

  private void format_text( FormatTag tag, string? extra=null ) {
    if( _table.selected.mode == NodeMode.EDITABLE ) {
      _table.selected.name.add_tag( tag, extra );
    } else {
      _table.selected.note.add_tag( tag, extra );
    }
    _table.queue_draw();
    _table.changed();
  }

  private void unformat_text( FormatTag tag ) {
    if( _table.selected.mode == NodeMode.EDITABLE ) {
      _table.selected.name.remove_tag( tag );
    } else {
      _table.selected.note.remove_tag( tag );
    }
    _table.queue_draw();
    _table.changed();
  }

  private void handle_bold() {
    if( !_ignore_active ) {
      if( _bold.active ) {
        format_text( FormatTag.BOLD );
      } else {
        unformat_text( FormatTag.BOLD );
      }
    }
  }

  private void handle_italics() {
    if( !_ignore_active ) {
      if( _italics.active ) {
        format_text( FormatTag.ITALICS );
      } else {
        unformat_text( FormatTag.ITALICS );
      }
    }
  }

  private void handle_underline() {
    if( !_ignore_active ) {
      if( _underline.active ) {
        format_text( FormatTag.UNDERLINE );
      } else {
        unformat_text( FormatTag.UNDERLINE );
      }
    }
  }

  private void handle_strikethru() {
    if( !_ignore_active ) {
      if( _strike.active ) {
        format_text( FormatTag.STRIKETHRU );
      } else {
        unformat_text( FormatTag.STRIKETHRU );
      }
    }
  }

  private void handle_highlighter() {
    format_text( FormatTag.HILITE, Utils.color_from_rgba( _hilite.rgba ) );
    /* TBD - We need to create/detect the "no color" selection and call unformat_text if set */
  }

  private void handle_link() {
    if( !_ignore_active ) {
      if( _link.active ) {
        format_text( FormatTag.URL );
      } else {
        unformat_text( FormatTag.URL );
      }
    }
  }

  /* Returns true if the given tag button should be active */
  private void set_toggle_button( CanvasText? text, FormatTag tag, ToggleButton btn ) {
    if( text == null ) {
      btn.set_sensitive( false );
      btn.set_active( false );
    } else if( text.is_selected() ) {
      btn.set_sensitive( true );
      btn.set_active( text.text.is_tag_applied_in_range( tag, text.selstart, text.selend ) );
    } else {
      btn.set_sensitive( false );
    }
  }

  private void set_color_button( CanvasText? text, FormatTag tag, Button btn ) {
    btn.set_sensitive( (text != null) && text.is_selected() );
  }

  /*
   Updates the state of the format bar based on the state of the current
   text.
  */
  private void update_from_text( CanvasText? text ) {
    _ignore_active = true;
    set_toggle_button( text, FormatTag.BOLD,       _bold );
    set_toggle_button( text, FormatTag.ITALICS,    _italics );
    set_toggle_button( text, FormatTag.UNDERLINE,  _underline );
    set_toggle_button( text, FormatTag.STRIKETHRU, _strike );
    set_color_button(  text, FormatTag.HILITE,     _hilite );
    set_toggle_button( text, FormatTag.URL,        _link );
    _ignore_active = false;
  }

  /*
   Updates the state of the format bar based on which tags are applied at the
   current cursor position.
  */
  public void update_state() {
    if( _table.selected == null ) {
      update_from_text( null );
    } else if( _table.selected.mode == NodeMode.EDITABLE ) {
      update_from_text( _table.selected.name );
    } else {
      update_from_text( _table.selected.note );
    }
  }

}
