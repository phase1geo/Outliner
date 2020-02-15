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

  public static string from_text( FormattedText text, int start, int end ) {
    FormattedText.ExportStartFunc start_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :  return( "<b>");
        case FormatTag.ITALICS    :  return( "<i>" );
        case FormatTag.UNDERLINE  :  return( "<u>" );
        case FormatTag.STRIKETHRU :  return( "<del>" );
        case FormatTag.HEADER     :  return( "<h%s>".printf( extra ) );
        case FormatTag.COLOR      :  return( "<span style=\"color:%s;\">".printf( extra ) );
        case FormatTag.HILITE     :  return( "<span style=\"background-color:%s;\">".printf( extra ) );
        case FormatTag.URL        :  return( "<a href=\"%s\">".printf( extra ) );
      }
      return( "" );
    };
    FormattedText.ExportEndFunc end_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :  return( "</b>" );
        case FormatTag.ITALICS    :  return( "</i>" );
        case FormatTag.UNDERLINE  :  return( "</u>" );
        case FormatTag.STRIKETHRU :  return( "</del>" );
        case FormatTag.HEADER     :  return( "</h%s>".printf( extra ) );
        case FormatTag.COLOR      :  return( "</span>" );
        case FormatTag.HILITE     :  return( "</span>" );
        case FormatTag.URL        :  return( "</a>" );
      }
      return( "" );
    };
    FormattedText.ExportEncodeFunc encode_func = (str) => {
      return( str.replace( "&", "&amp;" ).replace( "<", "&lt;" ).replace( ">", "&gt;" ) );
    };
    return( text.export( start, end, start_func, end_func, encode_func ) );
  }

  private static Xml.Node* make_div( string div_class, FormattedText text ) {
    var      html = "<div class=\"" + div_class + "\">" + from_text( text, 0, text.text.char_count() ) + "</div>";
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

  /****************************************************************************/

  /* Parses the given style string for tag information */
  private static void parse_style( string style, int start, int end, FormattedText text ) {
    var opts = style.split( ";" );
    foreach( unowned string opt in opts ) {
      var key_value = opt.split( ":" );
      if( key_value.length == 2 ) {
        switch( key_value[0] ) {
          case "color"            :  text.add_tag( FormatTag.COLOR,  start, end, key_value[1] );  break;
          case "background-color" :  text.add_tag( FormatTag.HILITE, start, end, key_value[1] );  break;
        }
      }
    }
  }

  /* Parses the given element for tag information */
  private static void parse_element( Xml.Node* node, string str, FormattedText text ) {
    var end   = text.text.char_count();
    var start = end - str.char_count();
    switch( node->name.down() ) {
      case "a"    :
        var url = node->get_prop( "href" );
        text.add_tag( FormatTag.URL, start, end, url );
        break;
      case "span" :
        var style = node->get_prop( "style" );
        if( style != null ) {
          parse_style( style, start, end, text );
        }
        break;
      case "h1"  :  text.add_tag( FormatTag.HEADER,     start, end, "1" );  break;
      case "h2"  :  text.add_tag( FormatTag.HEADER,     start, end, "2" );  break;
      case "h3"  :  text.add_tag( FormatTag.HEADER,     start, end, "3" );  break;
      case "h4"  :  text.add_tag( FormatTag.HEADER,     start, end, "4" );  break;
      case "h5"  :  text.add_tag( FormatTag.HEADER,     start, end, "5" );  break;
      case "h6"  :  text.add_tag( FormatTag.HEADER,     start, end, "6" );  break;
      case "b"   :  text.add_tag( FormatTag.BOLD,       start, end );  break;
      case "i"   :  text.add_tag( FormatTag.ITALICS,    start, end );  break;
      case "u"   :  text.add_tag( FormatTag.UNDERLINE,  start, end );  break;
      case "del" :  text.add_tag( FormatTag.STRIKETHRU, start, end );  break;
    }
  }

  /* Parses the given HTML node for text and tag information */
  private static string parse_xml_node( Xml.Node* node, FormattedText text ) {
    var str = "";
    for( Xml.Node* it=node->children; it!=null; it=it->next ) {
      str += parse_xml_node( it, text );
    }
    switch( node->type ) {
      case Xml.ElementType.ELEMENT_NODE       :
        parse_element( node, str, text );
        break;
      case Xml.ElementType.CDATA_SECTION_NODE :
      case Xml.ElementType.TEXT_NODE          :
        str += node->get_content();
        text.insert_text( text.text.char_count(), node->get_content() );
        break;
    }
    return( str );
  }

  /* Converts the given HTML string to the given formatted text */
  public static bool to_text( string str, FormattedText text ) {
    var doc  = Xml.Parser.parse_memory( str, str.length );
    if( doc == null ) {
      return( false );
    }
    var root = doc->get_root_element();
    parse_xml_node( root, text );
    delete doc;
    return( true );
  }

}
