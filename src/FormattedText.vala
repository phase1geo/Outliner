using Gdk;

public enum FormattedTag {
  BOLD = 0,
  ITALICS,
  UNDERLINE,
  STRIKETHROUGH,
  COLOR,
  HILITE,
  SELECT
}

public class FormattedType {
  public FormattedTag tag { get; private set; }
  public FormattedType( FormattedTag t ) { tag = t; }
  public virtual string start_tag() { return( "" ); }
  public virtual string end_tag() { return( "" ); }
  public virtual bool matches( FormattedType type ) { return( type.tag == tag ); }
}

public class BoldType : FormattedType {
  public BoldType() { base( FormattedTag.BOLD ); }
  public override string start_tag() { return( "<b>" ); }
  public override string end_tag() { return( "</b>" ); }
}

public class ItalicsType : FormattedType {
  public ItalicsType() { base( FormattedTag.ITALICS ); }
  public override string start_tag() { return( "<i>" ); }
  public override string end_tag() { return( "</i>" ); }
}

public class UnderlineType : FormattedType {
  public UnderlineType() { base( FormattedTag.UNDERLINE ); }
  public override string start_tag() { return( "<u>" ); }
  public override string end_tag() { return( "</u>" ); }
}

public class StrikethroughType : FormattedType {
  public StrikethroughType() { base( FormattedTag.STRIKETHROUGH ); }
  public override string start_tag() { return( "<s>" ); }
  public override string end_tag() { return( "</s>" ); }
}

public class ColorType : FormattedType {
  private string _color;
  public ColorType( string color ) {
    base( FormattedTag.COLOR );
    _color = color;
  }
  public override string start_tag() { return( "<span foreground='%s'>".printf( _color ) ); }
  public override string end_tag() { return( "</span>" ); }
  public override bool matches( FormattedType type ) { return( base.matches( type ) && ((type as ColorType)._color == _color) ); }
}

public class HighlightType : FormattedType {
  private string _color;
  public HighlightType( string color ) {
    base( FormattedTag.HILITE );
    _color = color;
  }
  public override string start_tag() { return( "<span background='%s'>".printf( _color ) ); }
  public override string end_tag() { return( "</span>" ); }
  public override bool matches( FormattedType type ) { return( base.matches( type ) && ((type as HighlightType)._color == _color) ); }
}

public class SelectedType : FormattedType {
  private string _foreground;
  private string _background;
  public SelectedType( string foreground, string background ) {
    base( FormattedTag.SELECT );
    _foreground = foreground;
    _background = background;
  }
  public override string start_tag() { return( "<span foreground='%s' background='%s'>".printf( _foreground, _background ) ); }
  public override string end_tag() { return( "</span>" ); }
}

public class FormattedText {

  private class Chunk {
    public string               text   { get; set; default = ""; }
    public Array<FormattedType> stags  { get; set; default = new Array<FormattedType>(); }
    public Array<FormattedType> etags  { get; set; default = new Array<FormattedType>(); }
    public int                  length { get { return( text.length ); } }

    public Chunk() {}

    public bool is_within( int index ) {
      return( index < text.length );
    }
    public bool contains_start_tag( FormattedType tag ) {
      for( int i=0; i<stags.length; i++ ) {
        if( stags.index( i ).matches( tag ) ) return( true );
      }
      return( false );
    }
    public bool contains_end_tag( FormattedType tag ) {
      for( int i=0; i<etags.length; i++ ) {
        if( etags.index( i ).matches( tag ) ) return( true );
      }
      return( false );
    }
    public bool insert( string str, int index ) {
      if( !is_within( index ) ) return( false );
      text = text.splice( index, index, str );
      return( true );
    }
    public bool delete( int index ) {
      if( !is_within( index ) ) return( false );
      text = text.splice( index, (index + 1) );
      return( true );
    }
    public bool delete_range( int s, int e ) {
      if( is_within( s ) ) {
        if( is_within( e ) ) {
          text = text.splice( s, e );
          return( true );
        } else {
          text = text.splice( s, text.length );
        }
      } else {
        if( is_within( e ) ) {
          text = text.splice( 0, e );
          return( true );
        }
      }
      return( false );
    }
    public bool is_empty() {
      return( text.length == 0 );
    }
    public string get_markup() {
      var str = "";
      for( int i=0; i<stags.length; i++ ) {
        str += stags.index( i ).start_tag();
      }
      str += text;
      for( int i=0; i<etags.length; i++ ) {
        str += etags.index( i ).end_tag();
      }
      return( str );
    }
  }

  private Array<Chunk> _chunks;

  public FormattedText() {
    _chunks = new Array<Chunk>();
    _chunks.append_val( new Chunk() );
  }

  public void insert_text( string str, int index ) {
    Chunk chunk = _chunks.index( 0 );
    for( int i=0; i<_chunks.length; i++ ) {
      chunk = _chunks.index( i );
      if( chunk.insert( str, index ) ) return;
      index -= chunk.length;
    }
    chunk.text += str;
  }

  public void delete( int index ) {
    for( int i=0; i<_chunks.length; i++ ) {
      if( _chunks.index( i ).delete( index ) ) return;
      index -= _chunks.index( i ).length;
    }
  }

  public void delete_range( int start, int end ) {
    int i = 0;
    while( i < _chunks.length ) {
      var chunk = _chunks.index( i );
      if( chunk.delete_range( start, end ) ) {
        return;
      } else if( chunk.is_empty() ) {
        _chunks.remove_index( i ); 
      } else {
        start -= chunk.length;
        end   -= chunk.length;
        i++;
      }
    }
  }

  private void dump() {

    for( int i=0; i<_chunks.length; i++ ) {
      var stags = "";
      var etags = "";
      var chunk = _chunks.index( i );
      for( int j=0; j<chunk.stags.length; j++ ) {
        stags += chunk.stags.index( j ).start_tag();
      }
      for( int j=0; j<chunk.etags.length; j++ ) {
        etags += chunk.etags.index( j ).end_tag();
      }
      stdout.printf( "%d:  %s %s %s\n", i, stags, chunk.text, etags );
    }

  }

  private void add_within_chunk( Chunk chunk, int chunk_index, FormattedType type, int start, int end ) {

    /* If the current chunk already has the given type applied, we don't need to do anything else */
    if( chunk.contains_start_tag( type ) ) return;

    /* Create new chunk */
    var new_chunk1  = new Chunk();
    new_chunk1.text = chunk.text.substring( start, end );
    new_chunk1.stags.append_val( type );
    new_chunk1.etags.append_val( type );
    _chunks.insert_val( (chunk_index + 1), new_chunk1 );

    /* Split the current chunk */
    var new_chunk2   = new Chunk();
    new_chunk2.text  = chunk.text.substring( end );
    if( new_chunk2.text.length > 0 ) {
      for( int i=0; i<chunk.etags.length; i++ ) {
        new_chunk2.etags.append_val( chunk.etags.index( i ) );
      }
      _chunks.insert_val( (chunk_index + 2), new_chunk2 );
    }

    /* Clean up chunk */
    chunk.text = chunk.text.substring( 0, start );
    if( (chunk.text.length == 0) && (chunk.stags.length == 0) ) {
      _chunks.remove_index( chunk_index );
    } else {
      chunk.etags.remove_range( 0, chunk.etags.length );
    }

  }

  private void add_start_chunk( Chunk chunk, ref int chunk_index, FormattedType type, int start ) {

    /* Create the new chunk and insert it into the list of chunks */
    var new_chunk = new Chunk();
    new_chunk.text  = chunk.text.substring( start );
    new_chunk.stags.append_val( type );
    new_chunk.etags.append_val( type );
    for( int i=0; i<chunk.etags.length; i++ ) {
      new_chunk.etags.append_val( chunk.etags.index( i ) );
    }
    _chunks.insert_val( (chunk_index + 1), new_chunk );

    /* Update the original chunk */
    chunk.text = chunk.text.splice( start, chunk.length );
    chunk.etags.remove_range( 0, chunk.etags.length );
    if( chunk.text.length == 0 ) {
      _chunks.remove_index( chunk_index );
    }

    chunk_index++;

  }

  private void add_end_chunk( Chunk chunk, int chunk_index, FormattedType type, int end ) {

    /* Create the new chunk and insert it into the list of chunks */
    var new_chunk = new Chunk();
    new_chunk.text  = chunk.text.substring( 0, end );
    new_chunk.stags.append_val( type );
    new_chunk.etags.prepend_val( type );
    for( int j=0; j<chunk.stags.length; j++ ) {
      new_chunk.stags.append_val( chunk.stags.index( j ) );
    }
    _chunks.insert_val( chunk_index, new_chunk );

    /* Update the original chunk */
    chunk.text = chunk.text.splice( 0, end );
    if( new_chunk.etags.index( 0 ) == chunk.stags.index( 0 ) ) {
      chunk.stags.remove_index( 0 );
    }

  }

  private void add_between_chunk( Chunk chunk, int chunk_index, FormattedType type ) {

    chunk.stags.append_val( type );
    chunk.etags.prepend_val( type );

  }

  /* Adds the formatting */
  public void add_format_range( FormattedType type, int start, int end ) {
    int  i           = 0;
    bool start_found = false;
    while( i < _chunks.length ) {
      var chunk = _chunks.index( i );

      /* If the start index is with the current chunk, update the chunk */
      if( chunk.is_within( start ) ) {

        /* If both the start and end indices are within the current chunk, update the chunk and be done */
        if( chunk.is_within( end ) ) {
          add_within_chunk( chunk, i, type, start, end );
          return;

        /* Otherwise, the chunk only contains the starting portion of the formatted text */
        } else {
          add_start_chunk( chunk, ref i, type, start );
          start_found = true;
        }

      /* If the chunk contains the end of the formatted text (but not the start), update the chunk */
      } else if( chunk.is_within( end ) ) {
        add_end_chunk( chunk, i, type, end );
        return;

      /* If this chunk is somewhere between the starting and ending indices, update the chunk accordingly */
      } else if( start_found ) {
        add_between_chunk( chunk, i, type );
      }
      start -= chunk.length;
      end   -= chunk.length;
      i++;
    }
  }

  public void remove_format( int start, int end ) {
    /* TBD */
  }

  /* Returns the raw text without formatting applied */
  public string get_text() {
    string str = "";
    for( int i=0; i<_chunks.length; i++ ) {
      str += _chunks.index( i ).text;
    }
    return( str );
  }

  /* Returns the markup string for the stored text */
  public string get_markup() {
    string str = "";
    for( int i=0; i<_chunks.length; i++ ) {
      str += _chunks.index( i ).get_markup();
    }
    return( str );
  }

}

