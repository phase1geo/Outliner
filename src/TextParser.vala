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

public struct TextParserElem {
  int       paren;
  FormatTag tag;
  string    extra;
}

public class TextParserRegex {

  struct TextParserTag {
    FormatTag tag;
    string    extra;
  }

  private Regex            _re;
  private TextParserTag?[] _tags;

  /* Default constructor */
  public TextParserRegex( string re, TextParserElem[] list ) {

    /* Make sure that the regular expression parses properly */
    try {
      _re = new Regex( re );
    } catch( RegexError e ) {
      stdout.printf( "Parser regex error (re: %s, error: %s)\n", re, e.message );
      return;
    }

    /* Allocate memory */
    _tags = {null, null, null, null, null, null, null, null, null, null};

    /* Add the arguments */
    foreach( TextParserElem elem in list ) {
      add_tag( elem.paren, elem.tag, elem.extra );
    }

  }

  /* Adds the given tag to this parser */
  private void add_tag( int paren, FormatTag tag, string extra ) {
    TextParserTag ttag = { tag, extra };
    _tags[paren] = ttag;
  }

  /* Parses the given text for this regular expression */
  public void parse( FormattedText text ) {
    MatchInfo matches;
    var       start = 0;
    try {
      while( _re.match_full( text.text, -1, start, 0, out matches ) ) {
        stdout.printf( "Matched pattern: %s\n", _re.get_pattern() );
        for( int i=0; i<10; i++ ) {
          if( _tags[i] != null ) {
            int start_pos, end_pos;
            matches.fetch_pos( i, out start_pos, out end_pos );
            if( _tags[i].tag == FormatTag.URL ) {
              text.add_tag( _tags[i].tag, start_pos, end_pos, matches.fetch( i ) );
            } else {
              text.add_tag( _tags[i].tag, start_pos, end_pos, _tags[i].extra );
            }
            start = end_pos;
          }
        }
      }
    } catch( RegexError e ) {}
  }

}

public class TextParser {


  private Array<TextParserRegex> _res;

  /* Default constructor */
  public TextParser() {
    _res = new Array<TextParserRegex>();
  }

  /* Adds a regular expression to this parser */
  public void add_regex( TextParserRegex re ) {
    _res.append_val( re );
  }

  /* Called to parse the text within the given FormattedText element */
  public virtual void parse( FormattedText text ) {
    for( int i=0; i<_res.length; i++ ) {
      _res.index( i ).parse( text );
    }
  }

}
