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
    for( int i=0; i<table.root.children.length; i++ ) {
      var node = table.root.children.index( i );
      nodes->add_child( export_node( node ) );
    }
    return( nodes );
  }

  private static Xml.Node* export_node( Node node ) {
    Xml.Node* n = new Xml.Node( null, "node" );
    var       next_id = id++;
    n->set_prop( "id", next_id.to_string() );
    n->set_prop( "posx", "0" );
    n->set_prop( "poxy", "0" );
    n->set_prop( "maxwidth", "200" );
    n->set_prop( "width", "200" );
    n->set_prop( "height", "50" );
    n->set_prop( "side", "left" );
    n->set_prop( "fold", "false" );
    n->set_prop( "treesize", "500" );
    n->set_prop( "layout", "To left" );
    n->add_child( export_node_style( node ) );
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

  private static Xml.Node* export_node_style( Node node ) {
    Xml.Node* style = new Xml.Node( null, "style" );
    style->set_prop( "linktype", "curved" );
    style->set_prop( "linkwidth", "4" );
    style->set_prop( "linkarrow", "false" );
    style->set_prop( "linkdash", "solid" );
    style->set_prop( "nodeborder", "underlined" );
    style->set_prop( "nodewidth", "200" );
    style->set_prop( "nodeborderwidth", "4" );
    style->set_prop( "nodefill", "false" );
    style->set_prop( "nodemargin", "8" );
    style->set_prop( "nodepadding", "6" );
    style->set_prop( "nodefont", "Sans 11" );
    style->set_prop( "nodemarkup", "true" );
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

    /* Read in the contents of the OPML file */
    var doc = Xml.Parser.parse_file( fname );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        Array<int>? expand_state = null;
        switch( it->name ) {
          case "head" :
            import_header( it, ref expand_state );
            break;
          case "body" :
            import_body( table, it, ref expand_state );
            break;
        }
      }
    }

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Parses the OPML head block for information that we will use */
  private static void import_header( Xml.Node* n, ref Array<int>? expand_state ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "expansionState") ) {
        if( (it->children != null) && (it->children->type == Xml.ElementType.TEXT_NODE) ) {
          expand_state = new Array<int>();
          string[] values = n->children->get_content().split( "," );
          foreach (string val in values) {
            int intval = int.parse( val );
            expand_state.append_val( intval );
          }
        }
      }
    }
  }

  /* Imports the OPML data, creating a mind map */
  public static void import_body( OutlineTable table, Xml.Node* n, ref Array<int>? expand_state) {

    /* Clear the existing nodes */
    table.root.children.remove_range( 0, table.root.children.length );

    /* Load the contents of the file */
    var i = 0;
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "outline") ) {
        table.root.add_child( import_node( table, it, ref expand_state ), i++ );
      }
    }

  }

  /* Main method for importing an OPML <outline> into a node */
  public static Node import_node( OutlineTable table, Xml.Node* n, ref Array<int>? expand_state ) {

    Node node = new Node( table );

    /* Get the node name */
    string? t = n->get_prop( "text" );
    if( t != null ) {
      node.name.text.set_text( t );
    }

    /* Get the task information */
    string? c = n->get_prop( "checked" );
    if( c != null ) {
    /*
      _task_count = 1;
      _task_done  = bool.parse( t ) ? 1 : 0;
      propagate_task_info_up( _task_count, _task_done );
    */
    }

    /* Get the note information */
    string? o = n->get_prop( "note" );
    if( o != null ) {
      node.note.text.set_text( o );
    }

    /* Figure out if this node is folded */
    if( expand_state != null ) {
      node.expanded = false;
      for( int i=0; i<expand_state.length; i++ ) {
        if( expand_state.index( i ) == node.id ) {
          node.expanded = true;
          expand_state.remove_index( i );
          break;
        }
      }
    }

    /* Parse the child nodes */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "outline") ) {
        var child = import_node( table, it, ref expand_state );
        node.add_child( child );
      }
    }

    return( node );

  }


}
