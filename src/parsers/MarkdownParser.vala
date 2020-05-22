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

  /* Default constructor */
  public MarkdownParser() {

    /* Header */
    add_regex( new TextParserRegex( "^#[^#].*$",      {{0, FormatTag.HEADER, "1"}} ) );
    add_regex( new TextParserRegex( "^##[^#].*$",     {{0, FormatTag.HEADER, "2"}} ) );
    add_regex( new TextParserRegex( "^###[^#].*$",    {{0, FormatTag.HEADER, "3"}} ) );
    add_regex( new TextParserRegex( "^####[^#].*$",   {{0, FormatTag.HEADER, "4"}} ) );
    add_regex( new TextParserRegex( "^#####[^#].*$",  {{0, FormatTag.HEADER, "5"}} ) );
    add_regex( new TextParserRegex( "^######[^#].*$", {{0, FormatTag.HEADER, "6"}} ) );

    /* Lists */
    add_regex( new TextParserRegex( "^\\s*(\\*|\\+|\\-|[0-9]+\\.)\\s", {{1, FormatTag.COLOR, "red"}} ) );

    /* Code */
    add_regex( new TextParserRegex( "`[^`]+`", {{0, FormatTag.CODE, ""}} ) );

    /* Bold */
    add_regex( new TextParserRegex( "\\*\\*[^*]+\\*\\*", {{0, FormatTag.BOLD, ""}} ) );
    add_regex( new TextParserRegex( "__[^_]+__", {{0, FormatTag.BOLD, ""}} ) );

    /* Italics */
    add_regex( new TextParserRegex( "(^|[^\\*])(\\*[^\\*]+\\*)($|[^\\*])", {{2, FormatTag.ITALICS, ""}} ) );
    add_regex( new TextParserRegex( "(^|[^_])(_[^_]+_)($|[^_])", {{2, FormatTag.ITALICS, ""}} ) );

    /* Links */
    add_regex( new TextParserRegex( "(\\[.*?\\]\\s*\\()(\\S+).*(\\))",
      {{1, FormatTag.COLOR, "grey"}, {2, FormatTag.URL, ""}, {3, FormatTag.COLOR, "grey"}} ) );
    add_regex( new TextParserRegex( "<((mailto:)?[a-z0-9.-]+@[-a-z0-9]+(\\.[-a-z0-9]+)*\\.[a-z]+)>",
      {{1, FormatTag.URL, ""}} ) );
    add_regex( new TextParserRegex( "<((https?|ftp):[^'\">\\s]+)>",
      {{1, FormatTag.URL, ""}} ) );

  }

}
