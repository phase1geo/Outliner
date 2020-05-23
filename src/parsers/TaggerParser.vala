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

public class TaggerParser : TextParser {

  private OutlineTable _ot;

  /* Default constructor */
  public TaggerParser( OutlineTable ot ) {
    base( "Tagger" );
    _ot = ot;
    add_regex( "\\s(@(\\S*))", handle_tag );
  }

  private void handle_tag( FormattedText text, MatchInfo match ) {

    var tag = get_text( match, 2 );

    /* Perform a search of matching tags and display them in an auto-completion */
    _ot.show_auto_completion( _ot.tagger.get_matches( tag ) );

    add_tag( text, match, 1, FormatTag.COLOR, "red" );

  }

  public override bool tag_handled( FormatTag tag ) {
    return( tag == FormatTag.TAG );
  }

}
