/*
* Copyright (c) 2019 (https://github.com/phase1geo/Outliner)
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

using Pango;
using Gdk;

public enum FormatTag {
  BOLD = 0,
  ITALICS,
  UNDERLINE,
  STRIKETHRU,
  COLOR1,
  COLOR2,
  COLOR3,
  COLOR4,
  HILITE1,
  HILITE2,
  HILITE3,
  HILITE4,
  URL,
  SELECT,
  LENGTH;

  public string to_string() {
    switch( this ) {
      case BOLD       :  return( "bold" );
      case ITALICS    :  return( "italics" );
      case UNDERLINE  :  return( "underline" );
      case STRIKETHRU :  return( "strikethru" );
      case COLOR1     :  return( "color1" );
      case COLOR2     :  return( "color2" );
      case COLOR3     :  return( "color3" );
      case COLOR4     :  return( "color4" );
      case HILITE1    :  return( "hilite1" );
      case HILITE2    :  return( "hilite2" );
      case HILITE3    :  return( "hilite3" );
      case HILITE4    :  return( "hilite4" );
      case URL        :  return( "url" );
    }
    return( "bold" );
  }

  public static FormatTag from_string( string str ) {
    switch( str ) {
      case "bold"       :  return( BOLD );
      case "italics"    :  return( ITALICS );
      case "underline"  :  return( UNDERLINE );
      case "strikethru" :  return( STRIKETHRU );
      case "color1"     :  return( COLOR1 );
      case "color2"     :  return( COLOR2 );
      case "color3"     :  return( COLOR3 );
      case "color4"     :  return( COLOR4 );
      case "hilite1"    :  return( HILITE1 );
      case "hilite2"    :  return( HILITE2 );
      case "hilite3"    :  return( HILITE3 );
      case "hilite4"    :  return( HILITE4 );
      case "url"        :  return( URL );
    }
    return( BOLD );
  }

}

public class FormattedText {

  private class TagInfo {

    private class FormattedRange {
      public int start { get; set; default = 0; }
      public int end   { get; set; default = 0; }
      public FormattedRange( int s, int e ) {
        start = s;
        end   = e;
      }
      public bool combine( int s, int e ) {
        bool changed = false;
        if( (s <= end) && (e > end) ) {
          end     = e;
          changed = true;
        }
        if( (s < start) && (e >= start) ) {
          start   = s;
          changed = true;
        }
        return( changed );
      }
    }

    private Array<FormattedRange> _info;

    public TagInfo() {
      _info = new Array<FormattedRange>();
    }

    /* Returns true if this info array is empty */
    public bool is_empty() {
      return( _info.length == 0 );
    }

    public void adjust( int index, int length ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (info.start <= index) && (index < info.end) ) {
          info.end += length;
          return;
        }
      }
    }

    /* Adds the given range from this format type */
    public void add_tag( int start, int end ) {
      for( int i=0; i<_info.length; i++ ) {
        if( _info.index( i ).combine( start, end ) ) {
          return;
        }
      }
      _info.append_val( new FormattedRange( start, end ) );
    }

    /* Removes the given range from this format type */
    public void remove_tag( int start, int end ) {
      for( uint i=(_info.length - 1); i>=0; i-- ) {
        var info = _info.index( i );
        if( (start < info.end) && (end > info.end) ) {
          if( start < info.start ) {
            _info.remove_index( i );
            continue;
          } else {
            info.end = start;
          }
        }
        if( (end > info.start) && (start < info.start) ) {
          info.start = end;
        }
      }
    }

    /* Returns true if the given index contains this tag */
    public bool is_applied_at_index( int index ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (info.start <= index) && (index < info.end) ) {
          return( true );
        }
      }
      return( false );
    }

    /* Inserts all of the attributes for this tag */
    public void get_attributes( int tag_index, ref AttrList attrs, TagAttrs[] tag ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        for( int j=0; j<tag[tag_index].attrs.length; j++ ) {
          var attr = tag[tag_index].attrs.index( j ).copy();
          attr.start_index = info.start;
          attr.end_index   = info.end;
          attrs.change( (owned)attr );
        }
      }
    }

    /* Returns the list of ranges this tag is associated with */
    public string get_ranges() {
      var ranges = "";
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        ranges += " %d %d".printf( info.start, info.end );
      }
      return( ranges.chug() );
    }

    /* Stores the given range information to this class */
    public void store_ranges( string? str ) {
      if( str == null ) return;
      string[] ranges = str.split( " " );
      for( int i=0; i<ranges.length; i+=2 ) {
        _info.append_val( new FormattedRange( int.parse( ranges[i+0] ), int.parse( ranges[i+1] ) ) );
      }
    }

  }

  private class TagAttrs {
    public Array<Pango.Attribute> attrs;
    public TagAttrs() {
      attrs = new Array<Pango.Attribute>();
    }
  }

  private class BoldInfo : TagAttrs {
    public BoldInfo() {
      attrs.append_val( attr_weight_new( Weight.BOLD ) );
    }
  }

  private class ItalicsInfo : TagAttrs {
    public ItalicsInfo() {
      attrs.append_val( attr_style_new( Style.ITALIC ) );
    }
  }

  private class UnderlineInfo : TagAttrs {
    public UnderlineInfo() {
      attrs.append_val( attr_underline_new( Underline.SINGLE ) );
    }
  }

  private class StrikeThruInfo : TagAttrs {
    public StrikeThruInfo() {
      attrs.append_val( attr_strikethrough_new( true ) );
    }
  }

  private class ColorInfo : TagAttrs {
    public ColorInfo( RGBA color ) {
      set_color( color );
    }
    private void set_color( RGBA color ) {
      attrs.append_val( attr_foreground_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) ) );
    }
    public void update_color( RGBA color ) {
      attrs.remove_index( 0 );
      set_color( color );
    }
  }

  private class HighlightInfo : TagAttrs {
    public HighlightInfo( RGBA color ) {
      set_color( color );
    }
    private void set_color( RGBA color ) {
      attrs.append_val( attr_background_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) ) );
      attrs.append_val( attr_background_alpha_new( (uint16)(65536 / 2) ) );
    }
    public void update_color( RGBA color ) {
      attrs.remove_range( 0, 2 );
      set_color( color );
    }
  }

  private class UrlInfo : TagAttrs {
    public UrlInfo( RGBA color ) {
      set_color( color );
    }
    private void set_color( RGBA color ) {
      attrs.append_val( attr_foreground_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) ) );
      attrs.append_val( attr_underline_new( Underline.SINGLE ) );
    }
    public void update_color( RGBA color ) {
      attrs.remove_range( 0, 2 );
      set_color( color );
    }

  }

  private class SelectInfo : TagAttrs {
    public SelectInfo( RGBA f, RGBA b ) {
      set_color( f, b );
    }
    private void set_color( RGBA f, RGBA b ) {
      attrs.append_val( attr_foreground_new( (uint16)(f.red * 65535), (uint16)(f.green * 65535), (uint16)(f.blue * 65535) ) );
      attrs.append_val( attr_background_new( (uint16)(b.red * 65535), (uint16)(b.green * 65535), (uint16)(b.blue * 65535) ) );
    }
    public void update_color( RGBA f, RGBA b ) {
      attrs.remove_range( 0, 2 );
      set_color( f, b );
    }
  }

  private static TagAttrs[] _attr_tags = null;
  private TagInfo[]         _formats   = new TagInfo[FormatTag.LENGTH];
  private string            _text      = "";

  public string text {
    get {
      return( _text );
    }
  }

  public FormattedText( Theme theme ) {
    if( _attr_tags == null ) {
      _attr_tags = new TagAttrs[FormatTag.LENGTH];
      _attr_tags[FormatTag.BOLD]       = new BoldInfo();
      _attr_tags[FormatTag.ITALICS]    = new ItalicsInfo();
      _attr_tags[FormatTag.UNDERLINE]  = new UnderlineInfo();
      _attr_tags[FormatTag.STRIKETHRU] = new StrikeThruInfo();
      _attr_tags[FormatTag.COLOR1]     = new ColorInfo( theme.color1 );
      _attr_tags[FormatTag.COLOR2]     = new ColorInfo( theme.color2 );
      _attr_tags[FormatTag.COLOR3]     = new ColorInfo( theme.color3 );
      _attr_tags[FormatTag.COLOR4]     = new ColorInfo( theme.color4 );
      _attr_tags[FormatTag.HILITE1]    = new HighlightInfo( theme.hilite1 );
      _attr_tags[FormatTag.HILITE2]    = new HighlightInfo( theme.hilite2 );
      _attr_tags[FormatTag.HILITE3]    = new HighlightInfo( theme.hilite3 );
      _attr_tags[FormatTag.HILITE4]    = new HighlightInfo( theme.hilite4 );
      _attr_tags[FormatTag.URL]        = new UrlInfo( theme.url );
      _attr_tags[FormatTag.SELECT]     = new SelectInfo( theme.textsel_foreground, theme.textsel_background );
    }
    for( int i=0; i<FormatTag.LENGTH; i++ ) {
      _formats[i] = new TagInfo();
    }
  }

  public static void set_theme( Theme theme ) {
    (_attr_tags[FormatTag.COLOR1] as ColorInfo).update_color( theme.color1 );
    (_attr_tags[FormatTag.COLOR2] as ColorInfo).update_color( theme.color2 );
    (_attr_tags[FormatTag.COLOR3] as ColorInfo).update_color( theme.color3 );
    (_attr_tags[FormatTag.COLOR4] as ColorInfo).update_color( theme.color4 );
    (_attr_tags[FormatTag.HILITE1] as HighlightInfo).update_color( theme.hilite1 );
    (_attr_tags[FormatTag.HILITE2] as HighlightInfo).update_color( theme.hilite2 );
    (_attr_tags[FormatTag.HILITE3] as HighlightInfo).update_color( theme.hilite3 );
    (_attr_tags[FormatTag.HILITE4] as HighlightInfo).update_color( theme.hilite4 );
    (_attr_tags[FormatTag.URL] as UrlInfo).update_color( theme.url );
    (_attr_tags[FormatTag.SELECT] as SelectInfo).update_color( theme.textsel_foreground, theme.textsel_background );
  }

  /* Inserts a string into the given text */
  public void insert_text( string str, int index ) {
    _text = _text.splice( index, index, str );
    foreach( TagInfo f in _formats) {
      f.adjust( index, str.length );
    }
  }

  /* Removes characters from the current text, starting at the given index */
  public void remove_text( int index, int chars ) {
    _text = _text.splice( index, (index + chars) );
    foreach( TagInfo f in _formats ) {
      f.remove_tag( index, (index + chars) );
    }
  }

  /* Adds the given tag */
  public void add_tag( FormatTag tag, int start, int end ) {
    _formats[tag].add_tag( start, end );
  }

  /* Removes the given tag */
  public void remove_tag( FormatTag tag, int start, int end ) {
    _formats[tag].remove_tag( start, end );
  }

  /* Removes all formatting from the text */
  public void remove_all( int start, int end ) {
    foreach( TagInfo f in _formats ) {
      f.remove_tag( start, end );
    }
  }

  /* Returns true if the given tag is applied at the given index */
  public bool is_tag_applied_at_index( FormatTag tag, int index ) {
    return( _formats[tag].is_applied_at_index( index ) );
  }

  /* Returns true if at least one tag is applied to the text */
  public bool tags_exist() {
    foreach( TagInfo f in _formats ) {
      if( !f.is_empty() ) {
        return( true );
      }
    }
    return( false );
  }

  /*
   Returns the Pango attribute list to apply to the Pango layout.  This
   method should only be called if tags_exist returns true.
  */
  public AttrList get_attributes() {
    var attrs = new AttrList();
    for( int i=0; i<FormatTag.LENGTH; i++ ) {
      _formats[i].get_attributes( i, ref attrs, _attr_tags );
    }
    return( attrs );
  }

  /* Saves the text as the given XML node */
  public Xml.Node* save() {
    Xml.Node* n = new Xml.Node( null, "text" );
    n->new_prop( "str", text );
    for( int i=0; i<(FormatTag.LENGTH - 1); i++ ) {
      if( !_formats[i].is_empty() ) {
        Xml.Node* f   = new Xml.Node( null, "format" );
        var       tag = (FormatTag)i;
        f->new_prop( "type", tag.to_string() );
        f->new_prop( "ranges", _formats[i].get_ranges() );
        n->add_child( f );
      }
    }
    return( n );
  }

  /* Loads the given XML information */
  public void load( Xml.Node* n ) {
    string? t = n->get_prop( "str" );
    if( t != null ) {
      _text = t;
    }
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "format") ) {
        string? type = it->get_prop( "type" );
        if( type != null ) {
          _formats[FormatTag.from_string( type )].store_ranges( n->get_prop( "ranges" ) );
        }
      }
    }
  }

}
