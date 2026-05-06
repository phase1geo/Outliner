/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Outliner)
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

public class LinkEditor : Popover {

  private OutlineTable _ot;
  private Entry        _entry;
  private Button       _apply;
  private string       _url_re = "^(mailto:.+@[a-z0-9-]+\\.[a-z0-9.-]+|[a-zA-Z0-9]+://[a-z0-9-]+\\.[a-z0-9.-]+(?:/|(?:/[][a-zA-Z0-9!#$%&'*+,.:;=?@_~-]+)*))$";
  private CanvasText   _text;
  private bool         _add;

  public signal void edit_cancelled();

  //-------------------------------------------------------------
  // Default constructor
  public LinkEditor( OutlineTable ot ) {

    Object( autohide: false );

    _ot = ot;

    var lbl   = new Label( _( "URL:" ) );
    _entry = new Entry() {
      halign = Align.START,
      width_chars = 50,
      input_purpose = InputPurpose.URL
    };
    _entry.activate.connect(() => {
      _apply.activate();
    });
    _entry.changed.connect( check_entry );

    _apply = new Button.from_icon_name( "object-select-symbolic" ) {
      halign       = Align.START,
      tooltip_text = _( "Apply" )
    };
    _apply.add_css_class( Granite.STYLE_CLASS_CIRCULAR );
    _apply.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    _apply.clicked.connect(() => {
      set_url();
      show_popover( false );
    });

    var cancel = new Button.from_icon_name( "window-close-symbolic" ) {
      halign       = Align.START,
      tooltip_text = _( "Cancel" )
    };
    cancel.add_css_class( Granite.STYLE_CLASS_CIRCULAR );
    cancel.clicked.connect(() => {
      _text.clear_selection();
      show_popover( false );
      edit_cancelled();
    });

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( lbl );
    box.append( _entry );
    box.append( _apply );
    box.append( cancel );

    child = box;

  }

  //-------------------------------------------------------------
  // Shows or hides this popover
  private void show_popover( bool show ) {
    if( show ) {
      Utils.show_popover( this );
      _entry.grab_focus();
    } else {
      unparent();
      Utils.hide_popover( this );
      _ot.grab_focus();
    }
  }

  //-------------------------------------------------------------
  // Sets this popover to point to the start of the text selection. 
  public void point_to_text() {

    var ct = _ot.get_current_text();

    int selstart, selend, cursor;
    ct.get_cursor_info( out cursor, out selstart, out selend );

    double left, top, bottom;
    int line;
    ct.get_char_pos( selstart, out left, out top, out bottom, out line );
    var int_left = (int)left;
    var int_top  = (int)top;
    Gdk.Rectangle rect = {int_left, int_top, 1, 1};

    // Setup popover to be displayable
    set_parent( _ot );
    position    = PositionType.TOP;
    pointing_to = rect;

  }

  //-------------------------------------------------------------
  // Checks the contents of the entry string.  If it is a URL,
  // make the action button active; otherwise, inactivate the
  // action button.
  private void check_entry() {
    _apply.set_sensitive( Regex.match_simple( _url_re, _entry.text ) );
  }

  //-------------------------------------------------------------
  // Sets the URL of the current node's selected text to the value
  // stored in the popover entry.
  private void set_url() {
    if( _add ) {
      if( _ot.markdown ) {
        _ot.markdown_parser.insert_tag( _text, FormatTag.URL, _text.selstart, _text.selend, _ot.undo_text, _entry.text );
      } else {
        _text.add_tag( FormatTag.URL, _entry.text, _ot.undo_text );
      }
    } else {
      _text.replace_tag( FormatTag.URL, _entry.text, _ot.undo_text );
    }
    _ot.changed();
  }

  //-------------------------------------------------------------
  // Called when we want to add a URL to the currently selected
  // text of the given node.
  public void add_edit_url() {

    var text = _ot.get_current_text();
    if( text == null ) return;

    _text = text;

    int selstart, selend, cursor;
    text.get_cursor_info( out cursor, out selstart, out selend );

    // If nothing is selected, we can only edit an existing URL, if one exists.
    if( selstart == selend ) {
      var link = text.text.get_tag_extra_at_index( FormatTag.URL, text.cursor );
      if( link != null ) {
        _add = false;
        _entry.text = link;
        check_entry();
        show_popover( true );
      }

      return;

    } else {

      int start = 0;
      int end   = 0;

      // If an existing URL is fully selected, edit it
      if( text.text.get_tag_pos_at_index( FormatTag.URL, text.selstart, out start, out end ) && (text.selstart == start) && (text.selend == end) ) {
        var link = text.text.get_tag_extra_at_index( FormatTag.URL, text.selstart );
        assert( link != null );
        _add = false;
        _entry.text = link;

      } else {

        _add = true;

        var selected_text = text.get_selected_text();

        if( Regex.match_simple( _url_re, selected_text ) ) {
          _entry.text = text.get_selected_text();

        } else if( OutlinerClipboard.text_pasteable() ) {
          var clipboard = Gdk.Display.get_default().get_clipboard();
          clipboard.read_text_async.begin( null, (obj, res) => {
            try {
              var clip_text = clipboard.read_text_async.end( res );
              if( (clip_text != null) && Regex.match_simple( _url_re, clip_text ) ) {
                _entry.text = clip_text;
                check_entry();
              }
            } catch( Error e ) {} 
          });
        }

      }

      check_entry();
      _ot.hide_format_bar();
      show_popover( true );

    }

  }

}
