public enum FormattedType {
  BOLD = 0,
  ITALICS,
  ULINE,
  STRIKE;

  public string tag() {
    switch( this ) {
      case BOLD    :  return( "b" );
      case ITALICS :  return( "i" );
      case ULINE   :  return( "u" );
      case STRIKE  :  return( "s" );
    }
    return( "b" );
  }
}

public class FormattedText {

  private class Chunk {
    public string               text  { get; set; default = ""; }
    public int                  start { get; set; default = 0; }
    public Array<FormattedType> stags { get; set; default = new Array<FormattedType>(); }
    public Array<FormattedType> etags { get; set; default = new Array<FormattedType>(); }
    public Chunk() {}
    public bool is_within( int index ) {
      return( (start <= index) && (index < (start + text.length)) );
    }
    public bool contains_type( FormattedType type ) {
      for( int i=0; i<stags.length; i++ ) {
        if( stags.index( i ) == type ) return( true );
      }
      return( false );
    }
    public bool insert( string str, int index ) {
      if( !is_within( index ) ) return( false );
      int offset = index - start;
      text = text.splice( offset, offset, str );
      return( true );
    }
    public bool delete( int index ) {
      if( !is_within( index ) ) return( false );
      int offset = index - start;
      text = text.splice( offset, (offset + 1) );
      return( true );
    }
    public bool delete_range( ref int s, int e ) {
      if( is_within( s ) ) {
        if( is_within( e ) ) {
          text = text.splice( (s - start), (e - start) );
          return( true );
        } else {
          text = text.splice( (s - start), (text.length - 1) );
          s   += (text.length - s);
          return( s == e );
        }
      } else {
        if( is_within( e ) ) {
          text = text.splice( 0, ((e - 1) - start) );
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
        str += "<" + stags.index( i ).tag() + ">";
      }
      str += text;
      for( int i=0; i<etags.length; i++ ) {
        str += "</" + etags.index( i ).tag() + ">";
      }
      return( str );
    }
  }

  private Array<Chunk> _chunks;

  public uint num_chunks() {
    return( _chunks.length );
  }

  public FormattedText() {
    _chunks = new Array<Chunk>();
    _chunks.append_val( new Chunk() );
  }

  public void insert_text( string str, int index ) {
    for( int i=0; i<_chunks.length; i++ ) {
      if( _chunks.index( i ).insert( str, index ) ) return;
    }
    _chunks.index( _chunks.length - 1 ).text += str;
  }

  public void delete( int index ) {
    for( int i=0; i<_chunks.length; i++ ) {
      if( _chunks.index( i ).delete( index ) ) return;
    }
  }

  public void delete_range( int start, int end ) {
    int last_start = start;
    int i          = 0;
    while( i < _chunks.length ) {
      if( _chunks.index( i ).delete_range( ref start, end ) ) {
        return;
      } else if( (start != last_start) && _chunks.index( i ).is_empty() ) {
        _chunks.remove_index( i ); 
      } else {
        i++;
      }
      last_start = start;
    }
  }

  private void dump() {

    for( int i=0; i<_chunks.length; i++ ) {
      var stags = "";
      var etags = "";
      for( int j=0; j<_chunks.index( i ).stags.length; j++ ) {
        stags += _chunks.index( i ).stags.index( j ).tag();
      }
      for( int j=0; j<_chunks.index( i ).etags.length; j++ ) {
        etags += _chunks.index( i ).etags.index( j ).tag();
      }
      stdout.printf( "%d:  %d %s %s %s\n", i, _chunks.index( i ).start, stags, _chunks.index( i ).text, etags );
    }

  }

  private void add_within_chunk( Chunk chunk, int chunk_index, FormattedType type, int start, int end ) {

    /* If the current chunk already has the given type applied, we don't need to do anything else */
    if( chunk.contains_type( type ) ) return;

    /* Create new chunk */
    var new_chunk1   = new Chunk();
    new_chunk1.text  = chunk.text.substring( (start - chunk.start), (end - chunk.start) );
    new_chunk1.start = start - chunk.start;
    new_chunk1.stags.append_val( type );
    new_chunk1.etags.append_val( type );
    _chunks.insert_val( (chunk_index + 1), new_chunk1 );

    /* Split the current chunk */
    var new_chunk2   = new Chunk();
    new_chunk2.text  = chunk.text.substring( (end - chunk.start), (chunk.text.length - (end - chunk.start)) );
    if( new_chunk2.text.length > 0 ) {
      new_chunk2.start = end - chunk.start;
      for( int i=0; i<chunk.etags.length; i++ ) {
        new_chunk2.etags.append_val( chunk.etags.index( i ) );
      }
      _chunks.insert_val( (chunk_index + 2), new_chunk2 );
    }

    /* Clean up chunk */
    chunk.text = chunk.text.substring( 0, (start - chunk.start) );
    if( (chunk.text.length == 0) && (chunk.stags.length == 0) ) {
      _chunks.remove_index( chunk_index );
    } else {
      chunk.etags.remove_range( 0, chunk.etags.length );
    }

  }

  private void add_start_chunk( Chunk chunk, ref int chunk_index, FormattedType type, int start ) {

    /* Create the new chunk and insert it into the list of chunks */
    var new_chunk = new Chunk();
    new_chunk.text  = chunk.text.substring( start - chunk.start );
    new_chunk.start = start - chunk.start;
    new_chunk.stags.append_val( type );
    new_chunk.etags.append_val( type );
    for( int i=0; i<chunk.etags.length; i++ ) {
      new_chunk.etags.append_val( chunk.etags.index( i ) );
    }
    _chunks.insert_val( (chunk_index + 1), new_chunk );

    /* Update the original chunk */
    chunk.text = chunk.text.splice( (start - chunk.start), chunk.text.length );
    chunk.etags.remove_range( 0, chunk.etags.length );
    if( chunk.text.length == 0 ) {
      _chunks.remove_index( chunk_index );
    }

    chunk_index++;

  }

  private void add_end_chunk( Chunk chunk, int chunk_index, FormattedType type, int end ) {

    /* Create the new chunk and insert it into the list of chunks */
    var new_chunk = new Chunk();
    new_chunk.text  = chunk.text.substring( 0, (end - chunk.start) );
    new_chunk.start = chunk.start;
    new_chunk.stags.append_val( type );
    new_chunk.etags.prepend_val( type );
    for( int j=0; j<chunk.stags.length; j++ ) {
      new_chunk.stags.append_val( chunk.stags.index( j ) );
    }
    stdout.printf( "  new_chunk: %s\n", new_chunk.get_markup() );
    _chunks.insert_val( chunk_index, new_chunk );

    /* Update the original chunk */
    chunk.text  = chunk.text.splice( 0, (end - chunk.start) );
    chunk.start = end - chunk.start;
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
    int  i = 0;
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
      i++;
    }
  }

  public void remove_format( int start, int end ) {
    /* TBD */
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

