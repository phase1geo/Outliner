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

public class FormatBar : Box {

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
  private Button       _clear;
  private SimpleAction _header_action;

  public signal void close_requested();

  //-------------------------------------------------------------
  // Construct the formatting bar
  public FormatBar( OutlineTable table ) {

    Object( orientation: Orientation.HORIZONTAL, spacing: 0, margin_start: 5, margin_end: 5, margin_top: 5, margin_bottom: 5 );

    _table = table;

    _copy = new Button.from_icon_name( "edit-copy-symbolic" ) {
      has_frame = false,
      tooltip_markup = get_tooltip_markup( _( "Copy" ), KeyCommand.EDIT_COPY )
    };
    _copy.clicked.connect( handle_copy );

    _cut = new Button.from_icon_name( "edit-cut-symbolic" ) {
      has_frame = false,
      tooltip_markup = get_tooltip_markup( _( "Cut" ), KeyCommand.EDIT_CUT )
    };
    _cut.clicked.connect( handle_cut );

    _bold = new ToggleButton() {
      has_frame = false,
      tooltip_markup = get_tooltip_markup( _( "Bold" ), KeyCommand.EDIT_BOLD )
    };
    add_markup( _bold, true, "<b>B</b>" );
    _bold.toggled.connect( handle_bold );

    _italics = new ToggleButton() {
      has_frame = false,
      tooltip_markup = get_tooltip_markup( _( "Italic" ), KeyCommand.EDIT_ITALICS )
    };
    add_markup( _italics, true, "<i>I</i>" );
    _italics.toggled.connect( handle_italics );

    _underline = new ToggleButton() {
      has_frame = false,
      tooltip_text = get_tooltip_markup( _( "Underline" ), KeyCommand.EDIT_UNDERLINE )
    };
    add_markup( _underline, true, "<u>U</u>" );
    _underline.toggled.connect( handle_underline );

    _strike = new ToggleButton() {
      has_frame = false,
      tooltip_text = get_tooltip_markup( _( "Strikethrough" ), KeyCommand.EDIT_STRIKETHRU )
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
      header_menu.append_item( new GLib.MenuItem( ((i == 0) ? _( "None" ) : "<H%d>".printf( i )), "format.action_header('%d')".printf( i ) ) );
    }

    _header = new MenuButton() {
      has_frame    = false,
      tooltip_text = _( "Header" ),
      menu_model   = header_menu
    };
    var menu_popover = (_header.popover as Gtk.PopoverMenu);
    if( menu_popover != null ) {
      menu_popover.cascade_popdown = false;
    }
    add_markup( _header, false, "H<i>x</i>" );

    _hilite = new ColorPicker( get_hilite_color(), table.get_theme().background, table.get_theme().foreground, ColorPickerType.HCOLOR ) {
      toggle_tooltip = _( "Apply Highlight Color" ),
      select_tooltip = _( "Change Highlight Color" )
    };
    _hilite.color_changed.connect( handle_hilite );

    _color = new ColorPicker( get_font_color(), table.get_theme().background, table.get_theme().foreground, ColorPickerType.FCOLOR ) {
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

    append( _copy );
    append( _cut );
    if( !table.markdown ) {
      append( new Separator( Orientation.VERTICAL ) );
      append( _bold );
      append( _italics );
      append( _underline );
      append( _strike );
      append( new Separator( Orientation.VERTICAL ) );
      append( _code );
      append( _header );
      append( _link );
      append( new Separator( Orientation.VERTICAL ) );
      append( _super );
      append( _sub );
      append( new Separator( Orientation.VERTICAL ) );
      // box.append( new Label( spacer ) );
      append( _hilite );
      // box.append( new Label( spacer ) );
      append( _color );
      append( new Separator( Orientation.VERTICAL ) );
      append( _clear );
    }

    // Create the action group
    var group = new SimpleActionGroup();
    insert_action_group( "format", group );

    _header_action = new SimpleAction.stateful( "action_header", VariantType.STRING, new Variant.string( "0" ) );
    _header_action.activate.connect((p) => {
      if( p != null ) {
        _header_action.set_state( p );
        handle_header( int.parse( p.get_string() ) );
      }
    });

    group.add_action( _header_action );

    // Initialize the format bar
    initialize();

  }

  //-------------------------------------------------------------
  // Returns the tooltip to show for the given command.
  private string get_tooltip_markup( string lbl, KeyCommand command ) {
    var shortcut = _table.win.shortcuts.get_shortcut( command );
    return( (shortcut == null) ? lbl : Utils.tooltip_with_accel( lbl, shortcut.get_accelerator() ) );
  }

  //-------------------------------------------------------------
  // Adds the given markup to the specified widget for display purposes.
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

  //-------------------------------------------------------------
  // Returns the highlight color that the outline table is currently
  // using.
  private RGBA get_hilite_color() {
    if( _table.hilite_color == null ) {
      return( _table.get_theme().hilite );
    } else {
      RGBA color = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
      color.parse( _table.hilite_color );
      return( color );
    }
  }

  //-------------------------------------------------------------
  // Returns the font that the outline table is currently using.
  private RGBA get_font_color() {
    if( _table.font_color == null ) {
      return( _table.get_theme().foreground );
    } else {
      RGBA color = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
      color.parse( _table.font_color );
      return( color );
    }
  }

  //-------------------------------------------------------------
  // Closes this popover.
  public void close() {
    destroy();
  }

  //-------------------------------------------------------------
  // Formats the selected text with the given tag and extra information.
  private void format_text( FormatTag tag, string? extra=null ) {
    var ct = (_table.selected.mode == NodeMode.EDITABLE) ? _table.selected.name : _table.selected.note;
    ct.add_tag( tag, extra, _table.undo_text );
    _table.queue_draw();
    _table.changed();
    _table.grab_focus();
  }

  //-------------------------------------------------------------
  // Removes formatting for the given tag from the selected text.
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

  //-------------------------------------------------------------
  // Copies the selected text to the clipboard
  private void handle_copy() {
    _table.do_copy();
    close_requested();
  }

  //-------------------------------------------------------------
  // Cuts the selected text to the clipboard
  private void handle_cut() {
    _table.do_cut();
    close_requested();
  }

  //-------------------------------------------------------------
  // Toggles the bold status of the currently selected text
  private void handle_bold() {
    if( !_ignore_active ) {
      if( _bold.active ) {
        format_text( FormatTag.BOLD );
      } else {
        unformat_text( FormatTag.BOLD );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the italics status of the currently selected text
  private void handle_italics() {
    if( !_ignore_active ) {
      if( _italics.active ) {
        format_text( FormatTag.ITALICS );
      } else {
        unformat_text( FormatTag.ITALICS );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the underline status of the currently selected text
  private void handle_underline() {
    if( !_ignore_active ) {
      if( _underline.active ) {
        format_text( FormatTag.UNDERLINE );
      } else {
        unformat_text( FormatTag.UNDERLINE );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the strikethru status of the currently selected text
  private void handle_strikethru() {
    if( !_ignore_active ) {
      if( _strike.active ) {
        format_text( FormatTag.STRIKETHRU );
      } else {
        unformat_text( FormatTag.STRIKETHRU );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the code status of the currently selected text
  private void handle_code() {
    if( !_ignore_active ) {
      if( _code.active ) {
        format_text( FormatTag.CODE );
      } else {
        unformat_text( FormatTag.CODE );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the superscript status of the currently selected text
  private void handle_superscript() {
    if( !_ignore_active ) {
      if( _super.active ) {
        format_text( FormatTag.SUPER );
      } else {
        unformat_text( FormatTag.SUPER );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the superscript status of the currently selected text
  private void handle_subscript() {
    if( !_ignore_active ) {
      if( _sub.active ) {
        format_text( FormatTag.SUB );
      } else {
        unformat_text( FormatTag.SUB );
      }
    }
  }

  //-------------------------------------------------------------
  // Handles the header menu items.
  private void action_header( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var level = variant.get_int32();
      handle_header( level );
    }
  }

  //-------------------------------------------------------------
  // Toggles the header status of the currently selected text
  private void handle_header( int level ) {
    if( !_ignore_active ) {
      if( level > 0 ) {
        format_text( FormatTag.HEADER, level.to_string() );
      } else {
        unformat_text( FormatTag.HEADER );
      }
    }
  }

  //-------------------------------------------------------------
  // Toggles the highlight status of the currently selected text
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

  //-------------------------------------------------------------
  // Toggles the foreground color of the currently selected text
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

  //-------------------------------------------------------------
  // Creates a link out of the currently selected text
  private void handle_link() {
    if( !_ignore_active ) {
      if( _link.active ) {
        KeyCommand.edit_url_add_edit( _table );
      } else {
        unformat_text( FormatTag.URL );
      }
      update_link_tooltip();
    }
  }

  //-------------------------------------------------------------
  // Clears all tags from selected text
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
    update_link_tooltip();
    activate_header( 0 );
    _ignore_active = false;
    _table.queue_draw();
    _table.changed();
    _table.grab_focus();
  }

  //-------------------------------------------------------------
  // Sets the active status of the given toggle button
  private void set_toggle_button( CanvasText text, FormatTag tag, ToggleButton btn ) {
    btn.set_active( text.text.is_tag_applied_in_range( tag, text.selstart, text.selend ) );
  }

  //-------------------------------------------------------------
  // Sets the active status of the given color picker
  private void set_color_picker( CanvasText text, FormatTag tag, ColorPicker cp ) {
    cp.set_active( text.text.is_tag_applied_in_range( tag, text.selstart, text.selend ) );
  }

  //-------------------------------------------------------------
  // Sets the active status of the header menubutton
  private void activate_header( int index ) {
    var variant = new Variant.string( "%d".printf( index ) );
    _header_action.set_state( variant );
  }

  //-------------------------------------------------------------
  // Sets the active status of the correct header radio menu item
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

  //-------------------------------------------------------------
  // Updates the link button tooltip based on the button active state.
  private void update_link_tooltip() {
    var command = _link.active ? KeyCommand.EDIT_URL_REMOVE : KeyCommand.EDIT_URL_ADD_EDIT;
    _link.tooltip_markup = get_tooltip_markup( _( "Link" ), command );
  }

  //-------------------------------------------------------------
  // Updates the state of the format bar based on the state of the
  // current text.
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
    update_link_tooltip();
    set_header( text );
    _ignore_active = false;
  }

  //-------------------------------------------------------------
  // Updates the state of the format bar based on which tags are
  // applied at the current cursor position.
  public void initialize() {
    if( _table.selected.mode == NodeMode.EDITABLE ) {
      update_from_text( _table.selected.name );
    } else {
      update_from_text( _table.selected.note );
    }
  }

}
