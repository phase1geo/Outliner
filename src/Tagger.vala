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

using Gee;

public class Tagger {

  private OutlineTable         _ot;
  private HashMap<string,bool> _tags;
  private Regex                _re;

  /* Default constructor */
  public Tagger( OutlineTable ot ) {
    _ot   = ot;
    _tags = new HashMap<string,bool>();
    try {
      _re = new Regex( "\\s(@(\\S+))" );
    } catch( RegexError e ) {}
  }

  /*
   Highlights any tags found in the given formatted text and adds the tags to
   the tags array if it doesn't already exist.
  */
  public void parse_text( FormattedText text ) {
    MatchInfo matches;
    var       start = 0;
    while( _re.match( text.text.substring( start ), 0, out matches ) ) {
      int start_pos, end_pos;
      matches.fetch_pos( 1, out start_pos, out end_pos );
      var tag = matches.fetch( 2 );
      text.add_tag( FormatTag.TAG, start_pos, end_pos, tag );
      if( !_tags.has_key( tag ) ) {
        _tags.@set( tag, true );
      }
      start = end_pos;
    }
  }

  /* Called whenever the user clicks on a tag */
  public void tag_clicked( string tag ) {
    // TBD
    stdout.printf( "tag_clicked: %s\n", tag );
  }

  /* Returns the XML version of this class for saving purposes */
  public Xml.Node* save() {
    Xml.Node* tags = new Xml.Node( null, "tags" );
    var it = _tags.map_iterator();
    while( it.next() ) {
      Xml.Node* tag = new Xml.Node( null, "tag" );
      tag->set_prop( "value", (string)it.get_key() );
      tags->add_child( tag );
    }
    return( tags );
  }

  /* Loads the tag information from the XML save file */
  public void load( Xml.Node* tags ) {
    for( Xml.Node* it = tags->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tag") ) {
        var n = it->get_prop( "value" );
        if( n != null ) {
          _tags.@set( n, true );
        }
      }
    }
  }

}
