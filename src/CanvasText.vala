/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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
using GLib;
using Gdk;
using Cairo;
using Pango;

public class CanvasText : Object {

  /* Member variables */
  private FormattedText  _text;
  private bool           _edit         = false;
  private int            _cursor       = 0;   /* Location of the cursor when editing */
  private int            _column       = 0;   /* Character column to use when moving vertically */
  private Pango.Layout   _pango_layout = null;
  private Pango.Layout   _line_layout  = null;
  private int            _selstart     = 0;
  private int            _selend       = 0;
  private int            _selanchor    = 0;
  private double         _max_width    = 200;
  private double         _width        = 0;
  private double         _height       = 0;

  /* Signals */
  public signal void resized();

  /* Properties */
  public FormattedText text {
    get {
      return( _text );
    }
  }
  public double posx   { get; set; default = 0; }
  public double posy   { get; set; default = 0; }
  public double width  {
    get {
      return( _width );
    }
  }
  public double height {
    get {
      return( _height );
    }
  }
  public double max_width {
    get {
      return( _max_width );
    }
    set {
      if( _max_width != value ) {
        _max_width = value;
        _pango_layout.set_width( (int)value * Pango.SCALE );
      }
    }
  }
  public bool edit {
    get {
      return( _edit );
    }
    set {
      if( _edit != value ) {
        _edit = value;
        update_size( true );
      }
    }
  }
  public int cursor {
    get {
      return( text.text.index_of_nth_char( _cursor ) );
    }
  }

  /* Default constructor */
  public CanvasText( OutlineTable da, double max_width ) {
    _text         = new FormattedText( da.get_theme() );
    _text.changed.connect( text_changed );
    _max_width    = max_width;
    _line_layout  = da.create_pango_layout( "M" );
    _pango_layout = da.create_pango_layout( null );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    update_size( false );
  }

  /* Constructor initializing string */
  public CanvasText.with_text( OutlineTable da, double max_width, string txt ) {
    _text         = new FormattedText.with_text( da.get_theme(), txt );
    _text.changed.connect( text_changed );
    _max_width    = max_width;
    _line_layout  = da.create_pango_layout( "M" );
    _pango_layout = da.create_pango_layout( txt );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    update_size( false );
  }

  /* Copies an existing CanvasText to this CanvasText */
  public void copy( CanvasText ct ) {
    posx       = ct.posx;
    posy       = ct.posy;
    _max_width = ct._max_width;
    _text.copy( ct.text );
    _line_layout.set_font_description( ct._pango_layout.get_font_description() );
    _pango_layout.set_font_description( ct._pango_layout.get_font_description() );
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    update_size( true );
  }

  /* Sets the font description to the given value */
  public void set_font( FontDescription font ) {
    _line_layout.set_font_description( font );
    _pango_layout.set_font_description( font );
    update_size( true );
  }

  public void set_font_size( int size ) {
    var fd = _line_layout.get_font_description();
    fd.set_size( size * Pango.SCALE );
    _line_layout.set_font_description( fd );
    _pango_layout.set_font_description( fd );
    update_size( true );
  }

  /* Returns true if the text is currently wrapped */
  public bool is_wrapped() {
    return( _pango_layout.is_wrapped() );
  }

  /* Returns true if the given cursor coordinates lies within this node */
  public bool is_within( double x, double y ) {
    return( Utils.is_within_bounds( x, y, posx, posy, _width, _height ) );
  }

  /* Saves the current instace into the given XML tree */
  public virtual Xml.Node* save( string title ) {

    Xml.Node* n = new Xml.Node( null, title );

    n->set_prop( "posx",     posx.to_string() );
    n->set_prop( "posy",     posy.to_string() );
    n->set_prop( "maxwidth", _max_width.to_string() );

    n->add_child( _text.save() );

    return( n );

  }

  /* Loads the file contents into this instance */
  public virtual void load( Xml.Node* n ) {

    string? x = n->get_prop( "posx" );
    if( x != null ) {
      posx = double.parse( x );
    }

    string? y = n->get_prop( "posy" );
    if( y != null ) {
      posy = double.parse( y );
    }

    string? mw = n->get_prop( "maxwidth" );
    if( mw != null ) {
      _max_width = double.parse( mw );
      _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    }

    /* Load the text and formatting */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "text" ) )  {
        _text.load( it );
        update_size( false );
      }
    }

  }

  /* Returns the height of a single line of text */
  public double get_line_height() {
    int width, height;
    _line_layout.get_size( out width, out height );
    return( height / Pango.SCALE );
  }

  /* Called whenever the text changes */
  private void text_changed() {
    update_size( true );
  }

  /*
   Updates the width and height based on the current text.
  */
  public void update_size( bool call_resized = true ) {
    if( _pango_layout != null ) {
      int text_width, text_height;
      _pango_layout.set_text( _text.text, -1 );
      _pango_layout.set_attributes( _text.get_attributes() );
      _pango_layout.get_size( out text_width, out text_height );
      _width  = (text_width  / Pango.SCALE);
      _height = (text_height / Pango.SCALE);
      if( call_resized ) {
        resized();
      }
    }
  }

  /* Resizes the node width by the given amount */
  public virtual void resize( double diff ) {
    _max_width += diff;
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    update_size( true );
  }

  /* Updates the column value */
  private void update_column() {
    int line;
    var cpos = text.text.index_of_nth_char( _cursor );
    _pango_layout.index_to_line_x( cpos, false, out line, out _column );
  }

  /* Sets the cursor from the given mouse coordinates */
  public void set_cursor_at_char( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - posx) * Pango.SCALE;
    int adjusted_y = (int)(y - posy) * Pango.SCALE;
    if( _pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      var cindex = text.text.char_count( cursor + trailing );
      if( motion ) {
        if( cindex > _selanchor ) {
          _selend = cindex;
           _text.replace_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
        } else if( cindex < _selanchor ) {
          _selstart = cindex;
           _text.replace_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
        } else {
          if( _selstart != _selend ) {
            _text.remove_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
          }
          _selstart = cindex;
          _selend   = cindex;
        }
      } else {
        if( _selstart != _selend ) {
          _text.remove_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
        }
        _selstart  = cindex;
        _selend    = cindex;
        _selanchor = cindex;
      }
      _cursor = _selend;
      update_column();
    }
  }

  /* Selects the word at the current x/y position in the text */
  public void set_cursor_at_word( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - posx) * Pango.SCALE;
    int adjusted_y = (int)(y - posy) * Pango.SCALE;
    if( _pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      cursor += trailing;
      var word_start = text.text.substring( 0, cursor ).last_index_of( " " );
      var word_end   = text.text.index_of( " ", cursor );
      if( word_start == -1 ) {
        _selstart = 0;
      } else {
        var windex = text.text.char_count( word_start );
        if( !motion || (windex < _selanchor) ) {
          _selstart = windex + 1;
        }
      }
      if( word_end == -1 ) {
        _selend = text.text.char_count();
      } else {
        var windex = text.text.char_count( word_end );
        if( !motion || (windex > _selanchor) ) {
          _selend = windex;
        }
      }
      _cursor = _selend;
      _text.replace_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
      update_column();
    }
  }

  /* Called after the cursor has been moved, clears the selection */
  public void clear_selection() {
    if( _selstart != _selend ) {
      _text.remove_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
    }
    _selstart = _selend = _cursor;
  }

  /*
   Called after the cursor has been moved, adjusts the selection
   to include the cursor.
  */
  private void adjust_selection( int last_cursor ) {
    if( last_cursor == _selstart ) {
      if( _cursor <= _selend ) {
        _selstart = _cursor;
      } else {
        _selend = _cursor;
      }
    } else {
      if( _cursor >= _selstart ) {
        _selend = _cursor;
      } else {
        _selstart = _cursor;
      }
    }
    _text.replace_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
  }

  /* Deselects all of the text */
  public void set_cursor_none() {
    clear_selection();
  }

  /* Selects all of the text and places the cursor at the end of the name string */
  public void set_cursor_all( bool motion ) {
    if( !motion ) {
      _selstart  = 0;
      _selend    = text.text.char_count();
      _selanchor = _selend;
      _cursor    = _selend;
      if( _selstart == _selend ) {
        _text.remove_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
      } else {
        _text.replace_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ) );
      }
    }
  }

  /* Adjusts the cursor by the given amount of characters */
  private void cursor_by_char( int dir ) {
    var last = text.text.char_count();
    _cursor += dir;
    if( _cursor < 0 ) {
      _cursor = 0;
    } else if( _cursor > last ) {
      _cursor = last;
    }
    update_column();
  }

  /* Move the cursor in the given direction */
  public void move_cursor( int dir ) {
    cursor_by_char( dir );
    clear_selection();
  }

  /* Adjusts the selection by the given cursor */
  public void selection_by_char( int dir ) {
    var last_cursor = _cursor;
    cursor_by_char( dir );
    adjust_selection( last_cursor );
  }

  /* Moves the cursor up/down the text by a line */
  private void cursor_by_line( int dir ) {
    int line, x;
    var cpos = text.text.index_of_nth_char( _cursor );
    _pango_layout.index_to_line_x( cpos, false, out line, out x );
    line += dir;
    if( line < 0 ) {
      _cursor = 0;
    } else if( line >= _pango_layout.get_line_count() ) {
      _cursor = text.text.char_count();
    } else {
      int index, trailing;
      var line_layout = _pango_layout.get_line( line );
      line_layout.x_to_index( _column, out index, out trailing );
      _cursor = text.text.char_count( index + trailing );
    }
  }

  /*
   Moves the cursor in the given vertical direction, clearing the
   selection.
  */
  public void move_cursor_vertically( int dir ) {
    cursor_by_line( dir );
    clear_selection();
  }

  /* Adjusts the selection in the vertical direction */
  public void selection_vertically( int dir ) {
    var last_cursor = _cursor;
    cursor_by_line( dir );
    adjust_selection( last_cursor );
  }

  /* Moves the cursor to the beginning of the name */
  public void move_cursor_to_start() {
    _cursor = 0;
    clear_selection();
  }

  /* Moves the cursor to the end of the name */
  public void move_cursor_to_end() {
    _cursor = text.text.char_count();
    clear_selection();
  }

  /* Causes the selection to continue from the start of the text */
  public void selection_to_start() {
    if( _selstart == _selend ) {
      _selstart = 0;
      _selend   = _cursor;
      _cursor   = 0;
    } else {
      _selstart = 0;
      _cursor   = 0;
    }
  }

  /* Causes the selection to continue to the end of the text */
  public void selection_to_end() {
    if( _selstart == _selend ) {
      _selstart = _cursor;
      _selend   = text.text.char_count();
      _cursor   = text.text.char_count();
    } else {
      _selend = text.text.char_count();
      _cursor = text.text.char_count();
    }
  }

  /* Finds the next/previous word boundary */
  private int find_word( int start, int dir ) {
    bool alnum_found = false;
    if( dir == 1 ) {
      for( int i=start; i<text.text.char_count(); i++ ) {
        int index = text.text.index_of_nth_char( i );
        if( text.text.get_char( index ).isalnum() ) {
          alnum_found = true;
        } else if( alnum_found ) {
          return( i );
        }
      }
      return( text.text.char_count() );
    } else {
      for( int i=(start - 1); i>=0; i-- ) {
        int index = text.text.index_of_nth_char( i );
        if( text.text.get_char( index ).isalnum() ) {
          alnum_found = true;
        } else if( alnum_found ) {
          return( i + 1 );
        }
      }
      return( 0 );
    }
  }

  /* Moves the cursor to the next or previous word beginning */
  public void move_cursor_by_word( int dir ) {
    _cursor = find_word( _cursor, dir );
    _selend = _selstart;
  }

  /* Change the selection by a word in the given direction */
  public void selection_by_word( int dir ) {
    if( _cursor == _selstart ) {
      _cursor = find_word( _cursor, dir );
      if( _cursor <= _selend ) {
        _selstart = _cursor;
      } else {
        _selstart = _selend;
        _selend   = _cursor;
      }
    } else {
      _cursor = find_word( _cursor, dir );
      if( _cursor >= _selstart ) {
        _selend = _cursor;
      } else {
        _selend   = _selstart;
        _selstart = _cursor;
      }
    }
  }

  /* Handles a backspace key event */
  public void backspace() {
    if( _cursor > 0 ) {
      if( _selstart != _selend ) {
        var spos = text.text.index_of_nth_char( _selstart );
        var epos = text.text.index_of_nth_char( _selend );
        text.remove_text( spos, ((epos - spos) + 1) );
        _cursor  = _selstart;
        _selend  = _selstart;
      } else {
        var spos = text.text.index_of_nth_char( _cursor - 1 );
        text.remove_text( spos, 1 );
        _cursor--;
      }
    }
  }

  /* Handles a delete key event */
  public void delete() {
    if( _cursor < text.text.length ) {
      if( _selstart != _selend ) {
        var spos = text.text.index_of_nth_char( _selstart );
        var epos = text.text.index_of_nth_char( _selend );
        text.remove_text( spos, ((epos - spos) + 1) );
        _cursor = _selstart;
        _selend = _selstart;
      } else {
        var spos = text.text.index_of_nth_char( _cursor );
        text.remove_text( spos, 1 );
      }
    }
  }

  /* Inserts the given string at the current cursor position and adjusts cursor */
  public void insert( string s ) {
    var slen = s.char_count();
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      text.replace_text( spos, ((epos - epos) + 1), s );
      _cursor = _selstart + slen;
      _selend = _selstart;
    } else {
      var cpos = text.text.index_of_nth_char( _cursor );
      text.insert_text( cpos, s );
      _cursor += slen;
    }
  }

  /*
   Returns the currently selected text or, if no text is currently selected,
   returns null.
  */
  public string? get_selected_text() {
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      return( text.text.slice( spos, epos ) );
    }
    return( null );
  }

  /* Returns the current cursor position */
  public void get_cursor_pos( out int x, out int ytop, out int ybot ) {
    var index = text.text.index_of_nth_char( _cursor );
    var rect  = _pango_layout.index_to_pos( index );
    x    = (int)(posx + (rect.x / Pango.SCALE));
    ytop = (int)(posy + (rect.y / Pango.SCALE));
    ybot = ytop + (int)(rect.height / Pango.SCALE);
  }

  /* Add tag to selected area */
  public void add_tag( FormatTag tag ) {
    var spos = text.text.index_of_nth_char( _selstart );
    var epos = text.text.index_of_nth_char( _selend );
    text.add_tag( tag, spos, epos );
  }

  /* Removes the specified tag for the selected range */
  public void remove_tag( FormatTag tag ) {
    var spos = text.text.index_of_nth_char( _selstart );
    var epos = text.text.index_of_nth_char( _selend );
    text.remove_tag( tag, spos, epos );
  }

  /* Removes the specified tag for the selected range */
  public void remove_all_tags() {
    var spos = text.text.index_of_nth_char( _selstart );
    var epos = text.text.index_of_nth_char( _selend );
    text.remove_all_tags( spos, epos );
  }

  /* Draws the node font to the screen */
  public void draw( Cairo.Context ctx, Theme theme, RGBA fg, double alpha ) {

    /* Output the text */
    ctx.move_to( posx, posy );
    Utils.set_context_color_with_alpha( ctx, fg, alpha );
    Pango.cairo_show_layout( ctx, _pango_layout );
    ctx.new_path();

    /* Draw the insertion cursor if we are in the 'editable' state */
    if( edit ) {
      var cpos = text.text.index_of_nth_char( _cursor );
      var rect = _pango_layout.index_to_pos( cpos );
      Utils.set_context_color_with_alpha( ctx, theme.text_cursor, alpha );
      double ix, iy;
      ix = posx + (rect.x / Pango.SCALE) - 1;
      iy = posy + (rect.y / Pango.SCALE);
      ctx.rectangle( ix, iy, 1, (rect.height / Pango.SCALE) );
      ctx.fill();
    }

  }

}
