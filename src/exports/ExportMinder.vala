/*
* Copyright (c) 2020-2025 (https://github.com/phase1geo/Outliner)
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
using Gtk;

public class ExportMinder : Export {

  private static int id = 0;

  //-------------------------------------------------------------
  // Constructor
  public ExportMinder() {
    base( "minder", _( "Minder" ), {".minder"}, true, true, false );
  }

  //-------------------------------------------------------------
  // Adds the settings for exporting.
  public override void add_settings( Grid grid ) {
    var help_text = _( "Minder 1.0 and 2.0 have different, incompatible save formats.\nIf left unset, the Minder 2.x and beyond version will be used." );
    add_setting_bool( "minder-1-x", grid, _( "Save As Minder 1.x Version" ), help_text, false );
  }
 
  //-------------------------------------------------------------
  // Exports this document in Minder 1.x or 2.x format.
  public override bool export( string fname, OutlineTable table ) {
    if( get_bool( "minder-1-x" ) ) {
      return( export_xml( fname, table ) );
    } else {
      return( export_archive( fname, table ) );
    }
  }

  //-------------------------------------------------------------
  // Creates a temporary directory.
  private string? make_tmp_dir() {
    try {
      var temp_dir = DirUtils.make_tmp( "minder-XXXXXX" );
      DirUtils.create( Path.build_filename( temp_dir, "images" ), 0755 );
      return( temp_dir );
    } catch( Error e ) {
      critical( e.message );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Adds the given file to the archive.
  private bool archive_file( Archive.Write archive, string fname ) {

    try {

      var file              = GLib.File.new_for_path( fname );
      var file_info         = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
      var input_stream      = file.read();
      var data_input_stream = new DataInputStream( input_stream );

      // Add an entry to the archive
      var entry = new Archive.Entry();
      entry.set_pathname( file.get_basename() );
      entry.set_size( (Archive.int64_t)file_info.get_size() );
      entry.set_filetype( Archive.FileType.IFREG );
      entry.set_perm( (Archive.FileMode)0644 );

      if( archive.write_header( entry ) != Archive.Result.OK ) {
        critical ("Error writing '%s': %s (%d)", file.get_path (), archive.error_string (), archive.errno ());
        return( false );
      }

      // Add the actual content of the file
      size_t bytes_read;
      uint8[] buffer = new uint8[64];
      while( data_input_stream.read_all( buffer, out bytes_read ) ) {
        if( bytes_read <= 0 ) {
          break;
        }
        archive.write_data( buffer );
      }

    } catch( Error e ) {
      stdout.printf( "ERROR archiving: %s\n", e.message );
      critical( e.message );
      return( false );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Creates the archive with the given name.
  private bool export_archive( string fname, OutlineTable table ) {

    var tmp_dir = make_tmp_dir();
    var map_file = Path.build_filename( tmp_dir, "map.xml" );

    // Save the XML file before we do everything else
    export_xml( map_file, table );

    // Create the tar.gz archive named according the the first argument
    Archive.Write archive = new Archive.Write ();
    archive.add_filter_gzip();
    archive.set_format_pax_restricted();
    archive.open_filename( fname );

    // Add the Minder file to the archive
    archive_file( archive, map_file );

    // Close the archive
    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

    // Delete the temporary directory
    Utils.delete_directory( tmp_dir );

    return( true );

  } 

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name
  private bool export_xml( string fname, OutlineTable table ) {
    id = 0;
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    var tags = new Array<string>();
    root->add_child( export_theme() );
    root->add_child( export_tags( table, tags ) );
    root->add_child( export_nodes( table, tags ) );
    doc->set_root_element( root );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( true );
  }

  //-------------------------------------------------------------
  // Exports the theme.
  private Xml.Node* export_theme() {
    Xml.Node* theme = new Xml.Node( null, "theme" );
    theme->set_prop( "name",  "Default" );
    theme->set_prop( "index", "0" );
    return( theme );
  }

  //-------------------------------------------------------------
  // Generates a random color in string format.
  private string generate_color_string() {
    var rand = new Rand();
    var red   = rand.int_range( 0, 255 );
    var green = rand.int_range( 0, 255 );
    var blue  = rand.int_range( 0, 255 );
    return( "#%02x%02x%02x".printf( red, green, blue ) );
  }

  //-------------------------------------------------------------
  // Exports the tags
  private Xml.Node* export_tags( OutlineTable table, Array<string> tag_array ) {
    Xml.Node* tags = new Xml.Node( null, "tags" );
    table.tagger.populate_tag_array( tag_array );
    for( int i=0; i<tag_array.length; i++ ) {
      Xml.Node* tag = new Xml.Node( null, "tag" );
      tag->set_prop( "name", tag_array.index( i ) );
      tag->set_prop( "color", generate_color_string() );
      tags->add_child( tag );
    }
    return( tags );
  }

  //-------------------------------------------------------------
  // Exports the nodes.
  private Xml.Node* export_nodes( OutlineTable table, Array<string> tags ) {
    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    Xml.Node* root  = export_root_node( table );
    if( table.root.children.length > 0 ) {
      Xml.Node* root_nodes = new Xml.Node( null, "nodes" );
      for( int i=0; i<table.root.children.length; i++ ) {
        var node = table.root.children.index( i );
        if( !node.draw_as_blank() ) {
          root_nodes->add_child( export_node( node, tags ) );
        }
      }
      root->add_child( root_nodes );
    }
    nodes->add_child( root );
    return( nodes );
  }

  //-------------------------------------------------------------
  // Exports the root node
  private Xml.Node* export_root_node( OutlineTable table ) {
    Xml.Node* root = new Xml.Node( null, "node" );
    Xml.Node* name = new Xml.Node( null, "nodename" );
    name->add_content( (table.title != null) ? table.title.text.text : table.document.label );
    export_node_properties( root, null );
    root->add_child( export_node_style() );
    root->add_child( name );
    return( root );
  }

  //-------------------------------------------------------------
  // Exports a single node
  private Xml.Node* export_node( Node node, Array<string> tags ) {
    Xml.Node* n = new Xml.Node( null, "node" );
    export_node_properties( n, node );
    n->add_child( export_node_style() );
    n->add_child( export_node_formatting( node ) );
    n->add_child( export_node_name( node ) );
    n->add_child( export_node_note( node ) );
    n->add_child( export_node_taglist( node, tags ) );
    if( node.children.length > 0 ) {
      Xml.Node* nodes = new Xml.Node( null, "nodes" );
      for( int i=0; i<node.children.length; i++ ) {
        nodes->add_child( export_node( node.children.index( i ), tags ) );
      }
      n->add_child( nodes );
    }
    return( n );
  }

  //-------------------------------------------------------------
  // Exports the node properties
  private void export_node_properties( Xml.Node* n, Node? node ) {
    var next_id = id++;
    n->set_prop( "id", next_id.to_string() );
    n->set_prop( "maxwidth", "200" );
    n->set_prop( "side",     "right" );
    n->set_prop( "fold",     "false" );
    n->set_prop( "layout",   _( "To right" ) );
    if( (node != null) && (node.children.length == 0) && (node.task != NodeTaskMode.NONE) ) {
      n->set_prop( "task", ((node.task == NodeTaskMode.DONE) ? "1" : "0") );
    }
  }

  //-------------------------------------------------------------
  // Exports the node style.
  private Xml.Node* export_node_style() {
    Xml.Node* style = new Xml.Node( null, "style" );
    style->set_prop( "branchmargin",    "100" );
    style->set_prop( "branchradius",    "25" );
    style->set_prop( "linktype",        "curved" );
    style->set_prop( "linkwidth",       "4" );
    style->set_prop( "linkarrow",       "false" );
    style->set_prop( "linkarrowsize",   "2" );
    style->set_prop( "linkdash",        "solid" );
    style->set_prop( "nodeborder",      "underlined" );
    style->set_prop( "nodewidth",       "200" );
    style->set_prop( "nodeborderwidth", "4" );
    style->set_prop( "nodefill",        "false" );
    style->set_prop( "nodemargin",      "8" );
    style->set_prop( "nodepadding",     "6" );
    style->set_prop( "nodefont",        "Sans 11" );
    style->set_prop( "nodetextalign",   "left" );
    style->set_prop( "nodemarkup",      "true" );
    return( style );
  }

  //-------------------------------------------------------------
  // Exports the formatting information for the given node text.
  private Xml.Node* export_node_formatting( Node node ) {
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

  //-------------------------------------------------------------
  // Exports the node name string.
  private Xml.Node* export_node_name( Node node ) {
    Xml.Node* name = new Xml.Node( null, "nodename" );
    var tags = node.name.text.get_extras_for_tag( FormatTag.TAG );
    var text = node.name.text.text;
    var it = tags.map_iterator();
    while( it.next() ) {
      try {
        var re = new Regex( "\\s*@%s\\b".printf( it.get_key() ) );
        text = re.replace( text, text.length, 0, "" );
      } catch( RegexError e ) {}
    }
    name->add_content( text );
    return( name );
  }

  //-------------------------------------------------------------
  // Exports the node note.
  private Xml.Node* export_node_note( Node node ) {
    Xml.Node* note = new Xml.Node( null, "nodenote" );
    note->add_content( node.note.text.text );
    return( note );
  }

  //-------------------------------------------------------------
  // Exports the node taglist.
  private Xml.Node* export_node_taglist( Node node, Array<string> tags ) {
    Xml.Node* taglist = new Xml.Node( null, "taglist" );
    string[]  node_tags = {};
    var format_tags = node.name.text.get_extras_for_tag( FormatTag.TAG );
    var it          = format_tags.map_iterator();
    while( it.next() ) {
      var name = it.get_key();
      for( int i=0; i<tags.length; i++ ) {
        if( tags.index( i ) == name ) {
          node_tags += "%d".printf( i );
          break;
        }
      }
    }
    taglist->set_prop( "list", string.joinv( ",", node_tags ) );
    return( taglist );
  }

  //-------------------------------------------------------------
  // IMPORT
  //-------------------------------------------------------------

  public override bool import( string fname, OutlineTable table ) {

    var tmp_dir = make_tmp_dir();
    if( tmp_dir == null ) {
      return( false );
    }

    Archive.Read archive = new Archive.Read();
    archive.support_filter_gzip();
    archive.support_format_all();

    Archive.ExtractFlags flags;
    flags  = Archive.ExtractFlags.TIME;
    flags |= Archive.ExtractFlags.PERM;
    flags |= Archive.ExtractFlags.ACL;
    flags |= Archive.ExtractFlags.FFLAGS;

    Archive.WriteDisk extractor = new Archive.WriteDisk();
    extractor.set_options( flags );
    extractor.set_standard_lookup();

    /* Open the Minder file for reading */
    if( archive.open_filename( fname, 16384 ) != Archive.Result.OK ) {
      return( import_xml( fname, table ) );
    }

    unowned Archive.Entry entry;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {

      // We will need to modify the entry pathname so the file is written to the
      // proper location.
      if( entry.pathname() == "map.xml" ) {
        entry.set_pathname( GLib.Path.build_filename( tmp_dir, entry.pathname() ) );
      } else {
        continue;
      }

      // Read from the archive and write the files to disk
      if( extractor.write_header( entry ) != Archive.Result.OK ) {
        continue;
      }
      uint8[]         buffer;
      Archive.int64_t offset;

      while( archive.read_data_block( out buffer, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, offset ) != Archive.Result.OK ) {
          break;
        }
      }

    }

    // Close the archive
    if( archive.close () != Archive.Result.OK) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

    // Finally, load the minder file
    var retval = import_xml( Path.build_filename( tmp_dir, "map.xml" ), table );

    // Delete the temporary directory
    Utils.delete_directory( tmp_dir );

    return( retval );

  }

  //-------------------------------------------------------------
  // Reads the contents of an OPML file and creates a new document
  // based on the stored information.
  public bool import_xml( string fname, OutlineTable table ) {

    var tags = new Array<string>();

    // Read in the contents of the Minder file
    var doc = Xml.Parser.read_file( fname, null, (Xml.ParserOption.HUGE| Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      return( false );
    }

    // Load the contents of the file
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "nodes" :  import_nodes( it, table, tags );  break;
          case "tags"  :  import_tags( it, table, tags );   break;
        }
      }
    }

    // Delete the XML document
    delete doc;

    return( true );

  }

  //-------------------------------------------------------------
  // Parses the tags nodes, extracts the tag names, and appends them
  // to the given tags list.
  private void import_tags( Xml.Node* nodes, OutlineTable table, Array<string> tags ) {
    for( Xml.Node* it=nodes->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tag") ) {
        var n = it->get_prop( "name" );
        if( n != null ) {
          var name = n.replace( " ", "-" );
          tags.append_val( name );
          table.tagger.add_tag( name );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Parses the given top-level nodes
  private void import_nodes( Xml.Node* nodes, OutlineTable table, Array<string> tags ) {
    for( Xml.Node* it=nodes->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        table.root.add_child( import_node( it, table, tags ) );
      }
    }
  }

  //-------------------------------------------------------------
  // Parses the given text node and stores it to the CanvasText item
  private void import_node_text( Xml.Node* n, CanvasText ct, Array<UndoTagInfo>? tags ) {

    // Let's convert the text from Markdown
    var html = Utils.markdown_to_html( n->get_content(), "div" );

    // Convert HTML to FormattedText
    if( ExportHTML.to_text( html, ct.text ) ) {

      // Add the tags if there are any
      if( tags != null ) {
        ct.text.apply_tags( tags );
      }

    }

  }

  //-------------------------------------------------------------
  // Parses the given urllink tag and saves the information as a
  // URL
  private void import_text_link( Xml.Node* ul, CanvasText ct, Array<UndoTagInfo> formatting ) {

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

  //-------------------------------------------------------------
  // Parses the node formatting tag
  private void import_node_formatting( Xml.Node* f, CanvasText ct, Array<UndoTagInfo> formatting ) {

    for( Xml.Node* it=f->children; it!= null; it=it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "urllink" :  import_text_link( it, ct, formatting );  break;
        }
      }
    }

  }

  //-------------------------------------------------------------
  // Parses the given taglist XML node.
  private void import_taglist( Xml.Node* n, Node node, OutlineTable table, Array<string> tags ) {
    var tl = n->get_prop( "list" );
    if( tl != null ) {
      var ids = tl.split( "," );
      var tag_str = "";
      foreach( var id in ids ) {
        var int_id = int.parse( id );
        var name   = tags.index( int_id );
        if( (int_id >= 0) && (int_id < tags.length) ) {
          tag_str += " @%s".printf( name );
        }
      }
      if( tag_str != "" ) {
        node.name.text.insert_text( node.name.text.text.length, tag_str );
      }
    }
  }

  //-------------------------------------------------------------
  // Loads the node name XML node.
  private void import_node_name( Xml.Node* n, Node node ) {
    var content = "";
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      content = n->children->get_content().strip();
    }
    if( content != "" ) {
      node.name.text.insert_text( 0, n->children->get_content() );
    } else {
      node.name.load( n );
    }
  }

  //-------------------------------------------------------------
  // Imports all Minder information useful for the node
  private Node import_node( Xml.Node* n, OutlineTable table, Array<string> tags ) {

    var node       = new Node( table );
    var formatting = new Array<UndoTagInfo>();

    var f = n->get_prop( "fold" );
    if( f != null ) {
      node.expanded = !bool.parse( f );
    }

    var t = n->get_prop( "task" );
    if( t != null ) {
      node.task = bool.parse( t ) ? NodeTaskMode.DONE : NodeTaskMode.OPEN;
    }

    /* Parse any children nodes */
    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "formatting" :  import_node_formatting( it, node.name, formatting );  break;
          case "nodename"   :  import_node_name( it, node );                         break;
          case "nodenote"   :  import_node_text( it, node.note, null );              break;
          case "taglist"    :  import_taglist( it, node, table, tags );              break;
          case "nodes" :
            for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                node.add_child( import_node( it2, table, tags ) );
              }
            }
            break;
        }
      }
    }

    return( node );

  }

}
