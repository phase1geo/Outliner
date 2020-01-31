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

using GLib;

public class ExportHTML : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, OutlineTable table, bool use_ul ) {
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* html = new Xml.Node( null, "html" );
    html->add_child( export_head( Path.get_basename( fname ) ) );
    html->add_child( export_body( table, use_ul ) );
    doc->set_root_element( html );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( true );
  }

  /* Generates the header for the document */
  private static Xml.Node* export_head( string? title ) {
    Xml.Node* head = new Xml.Node( null, "head" );
    head->new_text_child( null, "title", (title ?? "Outline") );
    return( head );
  }

  /* Generates the body for the document */
  private static Xml.Node* export_body( OutlineTable table, bool use_ul ) {
    Xml.Node* body = new Xml.Node( null, "body" );
    Xml.Node* list = new Xml.Node( null, (use_ul ? "ul" : "ol") );
    if( use_ul ) {
      list->set_prop( "style", "list-style-type:disc;" );
    } else {
      list->set_prop( "type", "I" );
    }
    for( int i=0; i<table.root.children.length; i++ ) {
      list->add_child( export_node( table.root.children.index( i ), use_ul ) );
    }
    body->add_child( list );
    return( body );
  }

  private static Xml.Node* make_div( string div_class, FormattedText text ) {
    var      html = "<div class=\"" + div_class + "\">" + text.htmlize() + "</div>";
    Xml.Doc* doc  = Xml.Parser.parse_memory( html, html.length );
    var      node = doc->get_root_element()->copy( 1 );
    delete doc;
    return( node );
  }

  /* Traverses the node tree exporting XML nodes in OPML format */
  private static Xml.Node* export_node( Node node, bool use_ul ) {
    string    ul_syms[3] = {"disc", "circle", "square"};
    string    ol_syms[5] = {"I", "A", "1", "a", "i"};
    Xml.Node* li         = new Xml.Node( null, "li" );
    li->add_child( make_div( "text", node.name.text ) );
    if( node.note.text.text != "" ) {
      li->add_child( make_div( "note", node.note.text ) );
    }
    if( node.children.length > 0 ) {
      Xml.Node* list = new Xml.Node( null, (use_ul ? "ul" : "ol") );
      if( use_ul ) {
        int sym_index = node.depth % 3;
        list->set_prop( "style", "list-style-type:%s".printf( ul_syms[sym_index] ) );
      } else {
        int sym_index = (node.depth >= 5) ? (((node.depth - 5) % 2) + 3) : (node.depth % 5);
        list->set_prop( "type", ol_syms[sym_index] );
      }
      li->add_child( list );
      for( int i=0; i<node.children.length; i++ ) {
        list->add_child( export_node( node.children.index( i ), use_ul ) );
      }
    }
    return( li );
  }

}
