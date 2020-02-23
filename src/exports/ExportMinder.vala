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

public class ExportMinder : Object {

  private static int id = 0;

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, OutlineTable table ) {
    id = 0;
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    root->add_child( export_theme() );
    root->add_child( export_drawarea() );
    root->add_child( export_nodes( table ) );
    doc->set_root_element( root );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( true );
  }

  private static Xml.Node* export_theme() {
    Xml.Node* theme = new Xml.Node( null, "theme" );
    theme->set_prop( "name",  "Default" );
    theme->set_prop( "index", "0" );
    return( theme );
  }

  private static Xml.Node* export_drawarea() {
    Xml.Node* da = new Xml.Node( null, "drawarea" );
    da->set_prop( "x", "0.0" );
    da->set_prop( "y", "0.0" );
    da->set_prop( "scale", "1" );
    return( da );
  }

  private static Xml.Node* export_nodes( OutlineTable table ) {
    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    Xml.Node* root  = export_root_node( table );
    if( table.root.children.length > 0 ) {
      Xml.Node* root_nodes = new Xml.Node( null, "nodes" );
      for( int i=0; i<table.root.children.length; i++ ) {
        var node = table.root.children.index( i );
        root_nodes->add_child( export_node( node ) );
      }
      root->add_child( root_nodes );
    }
    nodes->add_child( root );
    return( nodes );
  }

  private static Xml.Node* export_root_node( OutlineTable table ) {
    Xml.Node* root = new Xml.Node( null, "node" );
    Xml.Node* name = new Xml.Node( null, "nodename" );
    name->add_content( table.document.label );
    export_node_properties( root );
    root->add_child( export_node_style() );
    root->add_child( name );
    return( root );
  }

  private static Xml.Node* export_node( Node node ) {
    Xml.Node* n = new Xml.Node( null, "node" );
    export_node_properties( n );
    n->add_child( export_node_style() );
    n->add_child( export_node_formatting( node ) );
    n->add_child( export_node_name( node ) );
    n->add_child( export_node_note( node ) );
    if( node.children.length > 0 ) {
      Xml.Node* nodes = new Xml.Node( null, "nodes" );
      for( int i=0; i<node.children.length; i++ ) {
        nodes->add_child( export_node( node.children.index( i ) ) );
      }
      n->add_child( nodes );
    }
    return( n );
  }

  private static void export_node_properties( Xml.Node* node ) {
    var next_id = id++;
    node->set_prop( "id", next_id.to_string() );
    // node->set_prop( "posx",     "0" );
    // node->set_prop( "poxy",     "0" );
    node->set_prop( "maxwidth", "200" );
    // node->set_prop( "width",    "200" );
    // node->set_prop( "height",   "50" );
    node->set_prop( "side",     "right" );
    node->set_prop( "fold",     "false" );
    // node->set_prop( "treesize", "500" );
    node->set_prop( "layout",   _( "To right" ) );
  }

  private static Xml.Node* export_node_style() {
    Xml.Node* style = new Xml.Node( null, "style" );
    style->set_prop( "linktype",        "curved" );
    style->set_prop( "linkwidth",       "4" );
    style->set_prop( "linkarrow",       "false" );
    style->set_prop( "linkdash",        "solid" );
    style->set_prop( "nodeborder",      "underlined" );
    style->set_prop( "nodewidth",       "200" );
    style->set_prop( "nodeborderwidth", "4" );
    style->set_prop( "nodefill",        "false" );
    style->set_prop( "nodemargin",      "8" );
    style->set_prop( "nodepadding",     "6" );
    style->set_prop( "nodefont",        "Sans 11" );
    style->set_prop( "nodemarkup",      "true" );
    return( style );
  }

  private static Xml.Node* export_node_formatting( Node node ) {
    Xml.Node* formatting = new Xml.Node( null, "formatting" );
    var       text       = node.name.text;
    var       end        = text.text.char_count();
    if( text.is_tag_applied_in_range( FormatTag.URL, 0, end ) ) {
      var tags = text.get_tags_in_range( 0, end );
      for( int i=0; i<tags.length; i++ ) {
        var tag = tags.index( i );
        if( tag.tag == FormatTag.URL ) {
          Xml.Node* urllink = new Xml.Node( null, "urllink" );
          urllink->set_prop( "url",      tag.extra );
          urllink->set_prop( "spos",     tag.start.to_string() );
          urllink->set_prop( "epos",     tag.end.to_string() );
          urllink->set_prop( "embedded", "false" );
          urllink->set_prop( "ignore",   "false" );
          formatting->add_child( urllink );
        }
      }
    }
    return( formatting );
  }

  private static Xml.Node* export_node_name( Node node ) {
    Xml.Node* name = new Xml.Node( null, "nodename" );
    name->add_content( node.name.text.text );
    return( name );
  }

  private static Xml.Node* export_node_note( Node node ) {
    Xml.Node* note = new Xml.Node( null, "nodenote" );
    note->add_content( node.note.text.text );
    return( note );
  }

  /**********************************************************************/

  /*
   Reads the contents of an OPML file and creates a new document based on
   the stored information.
  */
  public static bool import( string fname, OutlineTable table ) {

    /* Read in the contents of the Minder file */
    var doc = Xml.Parser.parse_file( fname );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "nodes") ) {
        import_nodes( it, table );
      }
    }

    /* Delete the XML document */
    delete doc;

    return( true );

  }

  /* Parses the given top-level nodes */
  private static void import_nodes( Xml.Node* nodes, OutlineTable table ) {
    for( Xml.Node* it=nodes->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        table.root.add_child( import_node( it, table ) );
      }
    }
  }

  /* Parses the given text node and stores it to the CanvasText item */
  private static void import_node_text( Xml.Node* n, CanvasText ct, Array<UndoTagInfo>? tags ) {

    /* Let's convert the text from Markdown */
    var html = Utils.markdown_to_html( n->get_content(), "div" );

    stdout.printf( "html: %s\n", html );

    /* Convert HTML to FormattedText */
    if( ExportHTML.to_text( html, ct.text ) ) {

      /* Add the tags if there are any */
      if( tags != null ) {
        ct.text.apply_tags( tags );
      }

    }

  }

  /* Parses the given urllink tag and saves the information as a URL */
  private static void import_text_link( Xml.Node* ul, CanvasText ct, Array<UndoTagInfo> formatting ) {

    var url   = "";
    var start = -1;
    var end   = -1;

    var u = ul->get_prop( "url" );
    if( u != null ) {
      url = u;
    }

    var s = ul->get_prop( "spos" );
    if( s != null ) {
      start = int.parse( s );
    }

    var e = ul->get_prop( "epos" );
    if( e != null ) {
      end = int.parse( e );
    }

    if( (url != "") && (start != -1) && (end != -1) ) {
      formatting.append_val( new UndoTagInfo( FormatTag.URL, start, end, url ) );
    }

  }

  /* Parses the node formatting tag */
  private static void import_node_formatting( Xml.Node* f, CanvasText ct, Array<UndoTagInfo> formatting ) {

    for( Xml.Node* it=f->children; it!= null; it=it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "urllink" :  import_text_link( it, ct, formatting );  break;
        }
      }
    }

  }

  /* Imports all Minder information useful for the node */
  private static Node import_node( Xml.Node* n, OutlineTable table ) {

    var node       = new Node( table );
    var formatting = new Array<UndoTagInfo>();

    var f = n->get_prop( "fold" );
    if( f != null ) {
      node.expanded = !bool.parse( f );
    }

    /* Parse any children nodes */
    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "formatting" :  import_node_formatting( it, node.name, formatting );  break;
          case "nodename"   :  import_node_text( it, node.name, formatting );        break;
          case "nodenote"   :  import_node_text( it, node.note, null );              break;
          case "nodes" :
            for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                node.add_child( import_node( it2, table ) );
              }
            }
            break;
        }
      }
    }

    return( node );

  }

}
