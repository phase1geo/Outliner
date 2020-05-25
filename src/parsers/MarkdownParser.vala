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

public class MarkdownParser : TextParser {

  private OutlineTable _ot;

  /* Default constructor */
  public MarkdownParser( OutlineTable ot ) {
    base( "Markdown" );

    _ot = ot;

    /* Header */
    add_regex( "^(#{1,6})[^#].*$", highlight_header );

    /* Lists */
    add_regex( "^\\s*(\\*|\\+|\\-|[0-9]+\\.)\\s", (text, match) => {
      add_tag( text, match, 1, FormatTag.COLOR, _ot.get_theme().markdown_listitem.to_string() );
    });

    /* Code */
    add_regex( "`[^`]+`", (text, match) => {
      add_tag( text, match, 0, FormatTag.CODE );
    });

    /* Bold */
    add_regex( "\\*\\*[^* \\t].*?(?<!\\\\|\\*| |\\t)\\*\\*", highlight_bold );
    add_regex( "__[^_ \\t].*?(?<!\\\\|_| |\\t)__", highlight_bold );

    /* Italics */
    add_regex( "(?<!_)_[^_ \t].*?(?<!\\\\|_| |\\t)_(?!_)", highlight_italics );
    add_regex( "(?<!\\*)\\*[^* \t].*?(?<!\\\\|\\*| |\\t)\\*(?!\\*)", highlight_italics );

    /* Links */
    add_regex( "(\\[)(.+?)(\\]\\s*\\((\\S+).*\\))", highlight_url1 );
    add_regex( "(<)((mailto:)?[a-z0-9.-]+@[-a-z0-9]+(\\.[-a-z0-9]+)*\\.[a-z]+)(>)", highlight_url2 );
    add_regex( "(<)((https?|ftp):[^'\">\\s]+)(>)", highlight_url3 );

  }

  private void make_grey( FormattedText text, MatchInfo match, int paren ) {
    add_tag( text, match, paren, FormatTag.COLOR, _ot.get_theme().markdown_grey.to_string() );
  }

  private void highlight_header( FormattedText text, MatchInfo match ) {
    add_tag( text, match, 0, FormatTag.HEADER, get_text( match, 1 ).length.to_string() );
  }

  private void highlight_bold( FormattedText text, MatchInfo match ) {
    add_tag( text, match, 0, FormatTag.BOLD );
  }

  private void highlight_italics( FormattedText text, MatchInfo match ) {
    add_tag( text, match, 0, FormatTag.ITALICS );
  }

  private void highlight_url1( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    make_grey( text, match, 3 );
    add_tag( text, match, 2, FormatTag.URL, get_text( match, 4 ) );
  }

  private void highlight_url2( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    make_grey( text, match, 5 );
    add_tag( text, match, 2, FormatTag.URL, get_text( match, 2 ) );
  }

  private void highlight_url3( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    make_grey( text, match, 4 );
    add_tag( text, match, 2, FormatTag.URL, get_text( match, 2 ) );
  }

  /* Returns true if the associated tag should enable the associated FormatBar button */
  public override bool tag_handled( FormatTag tag ) {
    switch( tag ) {
      case FormatTag.HEADER  :
      case FormatTag.CODE    :
      case FormatTag.BOLD    :
      case FormatTag.ITALICS :
      case FormatTag.URL     :  return( true );
      default                :  return( false );
    }
  }

  /* This is called when the associated FormatBar button is clicked */
  public override void insert_tag( FormattedText text, FormatTag tag, int start_pos, int end_pos, string? extra ) {
    switch( tag ) {
      case FormatTag.HEADER  :  insert_header( text, start_pos, extra );  break;
      case FormatTag.CODE    :  insert_surround( text, "`", start_pos, end_pos );  break;
      case FormatTag.BOLD    :  insert_surround( text, "**", start_pos, end_pos );  break;
      case FormatTag.ITALICS :  insert_surround( text, "_", start_pos, end_pos );  break;
      case FormatTag.URL     :  insert_link( text, start_pos, end_pos, extra );  break;
    }
  }

  private void insert_header( FormattedText text, int start_pos, string extra ) {
    var nl     = text.text.slice( 0, start_pos ).last_index_of( "\n" );
    var num    = int.parse( extra );
    var hashes = "";
    for( int i=0; i<num; i++ ) {
      hashes += "#";
    }
    if( nl == -1 ) {
      text.insert_text( 0, "%s ".printf( hashes ) );
    } else {
      text.replace_text( nl, 1, "\n%s ".printf( hashes ) );
    }
  }

  private void insert_surround( FormattedText text, string surround, int start_pos, int end_pos ) {
    text.insert_text( end_pos, surround );
    text.insert_text( start_pos, surround );
  }

  private void insert_link( FormattedText text, int start_pos, int end_pos, string url ) {
    text.insert_text( end_pos, "](%s)".printf( url ) );
    text.insert_text( start_pos, "[" );
  }

}
