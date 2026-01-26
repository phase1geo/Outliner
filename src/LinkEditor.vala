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

using Gtk;

public class LinkEditor : Popover {

  private OutlineTable _ot;
  private bool         _add = true;
  private Entry        _entry;
  private Button       _apply;
  private string       _url_re = "^(mailto:.+@[a-z0-9-]+\\.[a-z0-9.-]+|[a-zA-Z0-9]+://[a-z0-9-]+\\.[a-z0-9.-]+(?:/|(?:/[][a-zA-Z0-9!#$%&'*+,.:;=?@_~-]+)*))$";
  private CanvasText   _text;

  public signal void edit_cancelled();

  //-------------------------------------------------------------
  // Default constructor
  public LinkEditor( OutlineTable ot ) {

    Object( autohide: false );

    _ot = ot;

    var ebox  = new Box( Orientation.HORIZONTAL, 5 );
    var lbl   = new Label( _( "URL:" ) );
    _entry = new Entry() {
      halign = Align.FILL,
      width_chars = 50,
      input_purpose = InputPurpose.URL
    };
    _entry.activate.connect(() => {
      _apply.activate();
    });
    _entry.changed.connect( check_entry );

    ebox.append( lbl );
    ebox.append( _entry );

    _apply = new Button.with_label( _( "Apply" ) ) {
      halign = Align.END
    };
    _apply.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    _apply.clicked.connect(() => {
      set_url();
      show_popover( false );
    });

    var cancel = new Button.with_label( _( "Cancel" ) ) {
      halign = Align.END,
      hexpand = true
    };
    cancel.clicked.connect(() => {
      _text.clear_selection();
      show_popover( false );
      edit_cancelled();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    bbox.append( cancel );
    bbox.append( _apply );

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };

    box.append( ebox );
    box.append( bbox );

    child = box;

  }

  //-------------------------------------------------------------
  // Shows or hides this popover
  private void show_popover( bool show ) {
    if( show ) {
      Utils.show_popover( this );
    } else {
      unparent();
      Utils.hide_popover( this );
    }
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
    if( _ot.markdown ) {
      _ot.markdown_parser.insert_tag( _text, FormatTag.URL, _text.selstart, _text.selend, _ot.undo_text, _entry.text );
    } else {
      _text.add_tag( FormatTag.URL, _entry.text, _ot.undo_text );
    }
    _ot.changed();
  }

  //-------------------------------------------------------------
  // Called when we want to add a URL to the currently selected
  // text of the given node.
  public void add_url( CanvasText text ) {

    _text = text;

    int selstart, selend, cursor;
    text.get_cursor_info( out cursor, out selstart, out selend );

    // Check to see if the selected text is already a valid URL
    var selected_text = text.get_selected_text();
    var selected_link = text.text.get_tag_extra_at_index( FormatTag.URL, selstart );
    var use_selected  = (selected_text != null) && Regex.match_simple( _url_re, selected_text );

    _add        = true;
    _entry.text = (selected_link != null) ? selected_link :
                  use_selected            ? selected_text : "";
    _apply.set_sensitive( (selected_link != null) || use_selected );

    show_popover( true );

  }

}
