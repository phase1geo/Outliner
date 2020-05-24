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
  private HashMap<string,bool> _pre_tags;
  private HashMap<string,bool> _tags;
  private Array<string>        _matches;

  /* Default constructor */
  public Tagger( OutlineTable ot ) {
    _ot      = ot;
    _tags    = new HashMap<string,bool>();
    _matches = new Array<string>();
  }

  /* Loads the tags prior to edits being made */
  public void preedit_load_tags( FormattedText text ) {
    _pre_tags = text.get_extras_for_tag( FormatTag.TAG );
  }

  /* Updates the stored list of tags in use. */
  public void postedit_load_tags( FormattedText text ) {
    var tags = text.get_extras_for_tag( FormatTag.TAG );
    var it   = tags.map_iterator();
    while( it.next() ) {
      if( !_pre_tags.unset( it.get_key() ) && !_tags.has_key( it.get_key() ) ) {
        _tags.@set( it.get_key(), true );
      }
    }
    var pid = _pre_tags.map_iterator();
    while( pid.next() ) {
      _tags.unset( pid.get_key() );
    }
  }

  /* Called whenever the user clicks on a tag */
  public void tag_clicked( string tag ) {
    _ot.filter_nodes( (node) => {
      return( node.name.text.contains_tag( FormatTag.TAG, tag ) );
    });
  }

  /* Gets the list of matching keys */
  public Array<string> get_matches( string partial ) {
    var it = _tags.map_iterator();
    _matches.remove_range( 0, _matches.length );
    while( it.next() ) {
      var key = (string)it.get_key();
      if( (key.length >= partial.length) && (key.substring( 0, partial.length ) == partial) ) {
        _matches.append_val( key );
      }
    }
    return( _matches );
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
