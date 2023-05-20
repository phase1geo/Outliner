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

public class UnicodeParser : TextParser {

  private OutlineTable _ot;

  /* Default constructor */
  public UnicodeParser( OutlineTable ot ) {

    base( "Unicode", 3 );

    _ot = ot;

    add_regex( "\\\\([a-zA-Z0-9_\\^\\(\\){}!+-=~:\\`'\".<>-]*)", handle_code );
    add_regex( "\\s", handle_nocode );

  }

  /* Highlights the given tag */
  private void handle_code( FormattedText text, MatchInfo match, int cursor ) {

    var tag = get_text( match, 0 );

    /* Highlight the tag */
    add_tag( text, match, 0, FormatTag.TAG, tag );

    /* If the FormattedText item matches the currently edited */
    if( (_ot.selected != null) && (_ot.selected.name.text == text) ) {

      int start, end;
      match.fetch_pos( 0, out start, out end );

      /* If the cursor is at the end of the tag, display the auto-completer */
      if( (start <= cursor) && (cursor <= end) ) {
        _ot.show_auto_completion( _ot.win.unicoder.get_matches( tag ), start, end );
      }

    }

  }

  /* Handles hiding the auto-completion window */
  private void handle_nocode( FormattedText text, MatchInfo match, int cursor ) {
    if( (_ot.selected != null) && (_ot.selected.name.text == text) ) {
      int start, end;
      match.fetch_pos( 0, out start, out end );
      if( cursor == end ) {
        _ot.hide_auto_completion();
      }
    }
  }

  public override bool tag_handled( FormatTag tag ) {
    return( tag == FormatTag.TAG );
  }

}
