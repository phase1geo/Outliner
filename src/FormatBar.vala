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

public class FormatBar : Gtk.Popover {

  private OutlineTable _table;
  private Button       _copy;
  private Button       _cut;
  private ToggleButton _bold;
  private ToggleButton _italics;
  private ToggleButton _underline;
  private ToggleButton _strike;
  private ToggleButton _code;
  private ToggleButton _super;
  private ToggleButton _sub;
  private MenuButton   _header;
  private ColorPicker  _hilite;
  private ColorPicker  _color;
  private ToggleButton _link;
  private bool         _ignore_active = false;
  private LinkEditor   _link_editor;
  private Button       _clear;

  /* Construct the formatting bar */
  public FormatBar( OutlineTable table ) {

    _table = table;

    _link_editor = new LinkEditor( table );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    _copy = new Button.from_icon_name( "edit-copy-symbolic" ) {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Copy" ), "<Control>c" )
    };
    _copy.clicked.connect( handle_copy );

    _cut = new Button.from_icon_name( "edit-cut-symbolic" ) {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Cut" ), "<Control>x" )
    };
    _cut.clicked.connect( handle_cut );

    _bold = new ToggleButton() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Bold" ), "<Control>b" )
    };
    add_markup( _bold, true, "<b>B</b>" );
    _bold.toggled.connect( handle_bold );

    _italics = new ToggleButton() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Italic" ), "<Control>i" )
    };
    add_markup( _italics, true, "<i>I</i>" );
    _italics.toggled.connect( handle_italics );

    _underline = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Underline" )
    };
    add_markup( _underline, true, "<u>U</u>" );
    _underline.toggled.connect( handle_underline );

    _strike = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Strikethrough" )
    };
    add_markup( _strike, true, "<s>S</s>" );
    _strike.toggled.connect( handle_strikethru );

    _code = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Code Block" )
    };
    add_markup( _code, true, "{ }" );
    _code.toggled.connect( handle_code );

    _super = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Superscript" )
    };
    add_markup( _super, true, "A<sup>x</sup>" );
    _super.toggled.connect( handle_superscript );

    _sub = new ToggleButton() {
      has_frame = false,
      tooltip_text = _( "Subscript" )
    };
    add_markup( _sub, true, "A<sub>x</sub>" );
    _sub.toggled.connect( handle_subscript );

    var header_menu = new GLib.Menu();
    for( int i=0; i<7; i++ ) {
      header_menu.append( ((i == 0) ? _( "None" ) : "<H%d>".printf( i )), "format.handle_header('%d')".printf( i ) );
    }

    _header = new MenuButton() {
      has_frame    = false,
      tooltip_text = _( "Header" ),
      menu_model   = header_menu
    };
    add_markup( _header, false, "H<i>x</i>" );

    _hilite = new ColorPicker( get_hilite_color(), ColorPickerType.HCOLOR ) {
      toggle_tooltip = _( "Apply Highlight Color" ),
      select_tooltip = _( "Change Highlight Color" )
    };
    _hilite.color_changed.connect( handle_hilite );

    _color = new ColorPicker( get_font_color(), ColorPickerType.FCOLOR ) {
      toggle_tooltip = _( "Apply Font Color" ),
      select_tooltip = _( "Change Font Color" )
    };
    _color.color_changed.connect( handle_color );

    _link = new ToggleButton() {
      icon_name    = "insert-link-symbolic",
      has_frame    = false,
      tooltip_text = _( "Link" )
    };
    _link.toggled.connect( handle_link );

    _clear = new Button.from_icon_name( "edit-clear-symbolic" ) {
      has_frame    = false,
      tooltip_text = _( "Clear all formatting" )
    };
    _clear.clicked.connect( handle_clear );

    var spacer = "    ";

    box.append( _copy );
    box.append( _cut );
    if( !table.markdown ) {
      box.append( new Separator( Orientation.VERTICAL ) );
      box.append( _bold );
      box.append( _italics );
      box.append( _underline );
      box.append( _strike );
      box.append( new Separator( Orientation.VERTICAL ) );
      box.append( _code );
      box.append( _header );
      box.append( _link );
      box.append( new Separator( Orientation.VERTICAL ) );
      box.append( _super );
      box.append( _sub );
      box.append( new Separator( Orientation.VERTICAL ) );
      box.append( new Label( spacer ) );
      box.append( _hilite );
      box.append( new Label( spacer ) );
      box.append( _color );
      box.append( new Separator( Orientation.VERTICAL ) );
      box.append( _clear );
    }

    child = box;

    initialize();

  }

  private void add_markup( Widget w, bool is_button, string markup ) {
    var lbl = new Label( "<span size=\"large\">" + markup + "</span>" ) {
      use_markup = true
    };
    if( is_button ) {
      var btn = (Button)w;
      btn.child = lbl;
    } else {
      var mb = (MenuButton)w;
      mb.child = lbl;
    }
  }

  private RGBA get_hilite_color() {
    if( _table.hilite_color == null ) {
      return( _table.get_theme().hilite );
    } else {
      RGBA color = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
      color.parse( _table.hilite_color );
      return( color );
    }
  }

  private RGBA get_font_color() {
    if( _table.font_color == null ) {
      return( _table.get_theme().foreground );
    } else {
      RGBA color = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
      color.parse( _table.font_color );
      return( color );
    }
  }

  private void close() {
    Utils.hide_popover( this );
  }

  private void format_text( FormatTag tag, string? extra=null ) {
    var ct = (_table.selected.mode == NodeMode.EDITABLE) ? _table.selected.name : _table.selected.note;
    ct.add_tag( tag, extra, _table.undo_text );
    _table.queue_draw();
    _table.changed();
    _table.grab_focus();
  }

  private void unformat_text( FormatTag tag ) {
    if( _table.selected.mode == NodeMode.EDITABLE ) {
      _table.selected.name.remove_tag( tag, _table.undo_text );
    } else {
      _table.selected.note.remove_tag( tag, _table.undo_text );
    }
    _table.queue_draw();
    _table.changed();
    _table.grab_focus();
  }

  /* Copies the selected text to the clipboard */
  private void handle_copy() {
    _table.do_copy();
    close();
  }

  /* Cuts the selected text to the clipboard */
  private void handle_cut() {
    _table.do_cut();
    close();
  }

  /* Toggles the bold status of the currently selected text */
  private void handle_bold() {
    if( !_ignore_active ) {
      if( _bold.active ) {
        format_text( FormatTag.BOLD );
      } else {
        unformat_text( FormatTag.BOLD );
      }
    }
  }

  /* Toggles the italics status of the currently selected text */
  private void handle_italics() {
    if( !_ignore_active ) {
      if( _italics.active ) {
        format_text( FormatTag.ITALICS );
      } else {
        unformat_text( FormatTag.ITALICS );
      }
    }
  }

  /* Toggles the underline status of the currently selected text */
  private void handle_underline() {
    if( !_ignore_active ) {
      if( _underline.active ) {
        format_text( FormatTag.UNDERLINE );
      } else {
        unformat_text( FormatTag.UNDERLINE );
      }
    }
  }

  /* Toggles the strikethru status of the currently selected text */
  private void handle_strikethru() {
    if( !_ignore_active ) {
      if( _strike.active ) {
        format_text( FormatTag.STRIKETHRU );
      } else {
        unformat_text( FormatTag.STRIKETHRU );
      }
    }
  }

  /* Toggles the code status of the currently selected text */
  private void handle_code() {
    if( !_ignore_active ) {
      if( _code.active ) {
        format_text( FormatTag.CODE );
      } else {
        unformat_text( FormatTag.CODE );
      }
    }
  }

  /* Toggles the superscript status of the currently selected text */
  private void handle_superscript() {
    if( !_ignore_active ) {
      if( _super.active ) {
        format_text( FormatTag.SUPER );
      } else {
        unformat_text( FormatTag.SUPER );
      }
    }
  }

  /* Toggles the superscript status of the currently selected text */
  private void handle_subscript() {
    if( !_ignore_active ) {
      if( _sub.active ) {
        format_text( FormatTag.SUB );
      } else {
        unformat_text( FormatTag.SUB );
      }
    }
  }

  /* Toggles the header status of the currently selected text */
  private void handle_header( int level ) {
    if( !_ignore_active ) {
      if( level > 0 ) {
        format_text( FormatTag.HEADER, level.to_string() );
      } else {
        unformat_text( FormatTag.HEADER );
      }
    }
  }

  /* Toggles the highlight status of the currently selected text */
  private void handle_hilite( RGBA? rgba ) {
    if( !_ignore_active ) {
      if( rgba != null ) {
        _table.hilite_color = Utils.color_from_rgba( rgba );
        format_text( FormatTag.HILITE, _table.hilite_color );
      } else {
        unformat_text( FormatTag.HILITE );
      }
    }
  }

  /* Toggles the foreground color of the currently selected text */
  private void handle_color( RGBA? rgba ) {
    if( !_ignore_active ) {
      if( rgba != null ) {
        _table.font_color = Utils.color_from_rgba( rgba );
        format_text( FormatTag.COLOR, _table.font_color );
      } else {
        unformat_text( FormatTag.COLOR );
      }
    }
  }

  /* Creates a link out of the currently selected text */
  private void handle_link() {
    if( !_ignore_active ) {
      if( _link.active ) {
        if( _table.selected.mode == NodeMode.EDITABLE ) {
          _link_editor.add_url( _table.selected.name );
        } else {
          _link_editor.add_url( _table.selected.note );
        }
        _table.queue_draw();
        _table.changed();
      } else {
        unformat_text( FormatTag.URL );
      }
    }
  }

  /* Clears all tags from selected text */
  private void handle_clear() {
    var ct = (_table.selected.mode == NodeMode.EDITABLE) ? _table.selected.name : _table.selected.note;
    ct.remove_all_tags( _table.undo_text );
    _ignore_active = true;
    _bold.set_active( false );
    _italics.set_active( false );
    _underline.set_active( false );
    _strike.set_active( false );
    _code.set_active( false );
    _super.set_active( false );
    _sub.set_active( false );
    _hilite.set_active( false );
    _color.set_active( false );
    _link.set_active( false );
    activate_header( 0 );
    _ignore_active = false;
    _table.queue_draw();
    _table.changed();
    _table.grab_focus();
  }

  /* Sets the active status of the given toggle button */
  private void set_toggle_button( CanvasText text, FormatTag tag, ToggleButton btn ) {
    btn.set_active( text.text.is_tag_applied_in_range( tag, text.selstart, text.selend ) );
  }

  /* Sets the active status of the given color picker */
  private void set_color_picker( CanvasText text, FormatTag tag, ColorPicker cp ) {
    cp.set_active( text.text.is_tag_applied_in_range( tag, text.selstart, text.selend ) );
  }

  /* Sets the active status of the header menubutton */
  private void activate_header( int index ) {
    /* TODO
    var buttons = _header.popup.get_children();
    var button  = (CheckMenuItem)buttons.nth_data( index );
    button.set_active( true );
    */
  }

  /* Sets the active status of the correct header radio menu item */
  private void set_header( CanvasText text ) {
    var header  = text.text.get_first_extra_in_range( FormatTag.HEADER, text.selstart, text.selend );
    if( header == null ) {
      activate_header( 0 );
    } else {
      switch( header ) {
        case "1" :  activate_header( 1 );  break;
        case "2" :  activate_header( 2 );  break;
        case "3" :  activate_header( 3 );  break;
        case "4" :  activate_header( 4 );  break;
        case "5" :  activate_header( 5 );  break;
        case "6" :  activate_header( 6 );  break;
      }
    }
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
    set_toggle_button( text, FormatTag.CODE,       _code );
    set_toggle_button( text, FormatTag.SUPER,      _super );
    set_toggle_button( text, FormatTag.SUB,        _sub );
    set_color_picker(  text, FormatTag.HILITE,     _hilite );
    set_color_picker(  text, FormatTag.COLOR,      _color );
    set_toggle_button( text, FormatTag.URL,        _link );
    set_header( text );
    _ignore_active = false;
  }

  /*
   Updates the state of the format bar based on which tags are applied at the
   current cursor position.
  */
  public void initialize() {
    if( _table.selected.mode == NodeMode.EDITABLE ) {
      update_from_text( _table.selected.name );
    } else {
      update_from_text( _table.selected.note );
    }
  }

}
