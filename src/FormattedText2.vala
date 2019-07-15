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
  LENGTH
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

    private   Array<FormattedRange> _info;
    protected Array<Attribute>      _attrs;

    public TagInfo() {
      _info  = new Array<FormattedRange>();
      _attrs = new Array<Attribute>();
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
    public void get_attributes( ref AttrList attrs ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        for( int j=0; j<_attrs.length; j++ ) {
          var attr = _attrs.index( j ).copy();
          attr.start_index = info.start;
          attr.end_index   = info.end;
          attrs.insert( attr );
        }
      }
    }

  }

  private class BoldInfo : TagInfo {
    public BoldInfo() {
      _attrs.append_val( attr_weight_new( Weight.BOLD ) );
    }
  }

  private class ItalicsInfo : TagInfo {
    public ItalicsInfo() {
      _attrs.append_val( attr_style_new( Style.ITALIC ) );
    }
  }

  private class UnderlineInfo : TagInfo {
    public UnderlineInfo() {
      _attrs.append_val( attr_underline_new( Underline.SINGLE ) );
    }
  }

  private class StrikeThruInfo : TagInfo {
    public StrikeThruInfo() {
      _attrs.append_val( attr_strikethrough_new( true ) );
    }
  }

  private class ColorInfo : TagInfo {
    public ColorInfo( RGBA color ) {
      _attrs.append_val( attr_foreground_new( (uint16)(color.red * 255), (uint16)(color.green * 255), (uint16)(color.blue * 255) ) );
    }
    public void set_color( RGBA color ) {
      _attrs.remove_index( 0 );
      _attrs.append_val( attr_foreground_new( (uint16)(color.red * 255), (uint16)(color.green * 255), (uint16)(color.blue * 255) ) );
    }
  }

  private class HighlightInfo : TagInfo {
    public HighlightInfo( RGBA color ) {
      _attrs.append_val( attr_background_new( (uint16)(color.red * 255), (uint16)(color.green * 255), (uint16)(color.blue * 255) ) );
      _attrs.append_val( attr_background_alpha_new( (uint16)(color.alpha * 255) ) );
    }
    public void set_color( RGBA color ) {
      _attrs.remove_range( 0, 2 );
      _attrs.append_val( attr_background_new( (uint16)(color.red * 255), (uint16)(color.green * 255), (uint16)(color.blue * 255) ) );
      _attrs.append_val( attr_background_alpha_new( (uint16)(color.alpha * 255) ) );
    }
  }

  private class UrlInfo : TagInfo {
    public UrlInfo( RGBA color ) {
      _attrs.append_val( attr_foreground_new( (uint16)(color.red * 255), (uint16)(color.green * 255), (uint16)(color.blue * 255) ) );
      _attrs.append_val( attr_underline_new( Underline.SINGLE ) );
    }
    public void set_color( RGBA color ) {
      _attrs.remove_range( 0, 2 );
      _attrs.append_val( attr_foreground_new( (uint16)(color.red * 255), (uint16)(color.green * 255), (uint16)(color.blue * 255) ) );
      _attrs.append_val( attr_underline_new( Underline.SINGLE ) );
    }
  }

  private class SelectInfo : TagInfo {
    public SelectInfo( RGBA f, RGBA b ) {
      _attrs.append_val( attr_foreground_new( (uint16)(f.red * 255), (uint16)(f.green * 255), (uint16)(f.blue * 255) ) );
      _attrs.append_val( attr_background_new( (uint16)(b.red * 255), (uint16)(b.green * 255), (uint16)(b.blue * 255) ) );
    }
    public void set_color( RGBA f, RGBA b ) {
      _attrs.remove_range( 0, 2 );
      _attrs.append_val( attr_foreground_new( (uint16)(f.red * 255), (uint16)(f.green * 255), (uint16)(f.blue * 255) ) );
      _attrs.append_val( attr_background_new( (uint16)(b.red * 255), (uint16)(b.green * 255), (uint16)(b.blue * 255) ) );
    }
  }

  private TagInfo[] _formats = new TagInfo[FormatTag.LENGTH];
  private string    _text;

  public string text {
    get {
      return( _text );
    }
  }

  public FormattedText( Theme theme ) {
    _formats[FormatTag.BOLD]       = new BoldInfo();
    _formats[FormatTag.ITALICS]    = new ItalicsInfo();
    _formats[FormatTag.UNDERLINE]  = new UnderlineInfo();
    _formats[FormatTag.STRIKETHRU] = new StrikeThruInfo();
    _formats[FormatTag.COLOR1]     = new ColorInfo( theme.color1 );
    _formats[FormatTag.COLOR2]     = new ColorInfo( theme.color2 );
    _formats[FormatTag.COLOR3]     = new ColorInfo( theme.color3 );
    _formats[FormatTag.COLOR4]     = new ColorInfo( theme.color4 );
    _formats[FormatTag.HILITE1]    = new HighlightInfo( theme.hilite1 );
    _formats[FormatTag.HILITE2]    = new HighlightInfo( theme.hilite2 );
    _formats[FormatTag.HILITE3]    = new HighlightInfo( theme.hilite3 );
    _formats[FormatTag.HILITE4]    = new HighlightInfo( theme.hilite4 );
    _formats[FormatTag.URL]        = new UrlInfo( theme.url );
    _formats[FormatTag.SELECT]     = new SelectInfo( theme.textsel_foreground, theme.textsel_background );
  }

  public void set_theme( Theme theme ) {
    (_formats[FormatTag.COLOR1] as ColorInfo).set_color( theme.color1 );
    (_formats[FormatTag.COLOR2] as ColorInfo).set_color( theme.color2 );
    (_formats[FormatTag.COLOR3] as ColorInfo).set_color( theme.color3 );
    (_formats[FormatTag.COLOR4] as ColorInfo).set_color( theme.color4 );
    (_formats[FormatTag.HILITE1] as HighlightInfo).set_color( theme.hilite1 );
    (_formats[FormatTag.HILITE2] as HighlightInfo).set_color( theme.hilite2 );
    (_formats[FormatTag.HILITE3] as HighlightInfo).set_color( theme.hilite3 );
    (_formats[FormatTag.HILITE4] as HighlightInfo).set_color( theme.hilite4 );
    (_formats[FormatTag.URL] as UrlInfo).set_color( theme.url );
    (_formats[FormatTag.SELECT] as SelectInfo).set_color( theme.textsel_foreground, theme.textsel_background );
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
    foreach( TagInfo f in _formats ) {
      f.get_attributes( ref attrs );
    }
    return( attrs );
  }

}
