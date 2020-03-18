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

public class ExportRTF : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, OutlineTable table, bool use_ul ) {
    var file = File.new_for_path( fname );
    try {
      var os = file.create( FileCreateFlags.PRIVATE );
      export_main( os, table, use_ul );
    } catch( Error e ) {
      return( false );
    }
    return( true );
  }

  private static void export_main( FileOutputStream os, OutlineTable table, bool use_ul ) {
    try {
      os.write( "{\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard ".data );
      for( int i=0; i<table.root.children.length; i++ ) {
        export_node( os, table.root.children.index( i ), use_ul );
      }
      os.write( "}".data );
    } catch( Error e ) {}
  }

  public static string from_text( FormattedText text ) {
    FormattedText.ExportStartFunc start_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :  return( "\\b" );
        case FormatTag.ITALICS    :  return( "\\i" );
        case FormatTag.UNDERLINE  :  return( "\\ul" );
        case FormatTag.STRIKETHRU :  return( "\\strike" );
        case FormatTag.HEADER     :
          if( start == 0 ) {
            switch( extra ) {
              case "1" :  return( "\\b\\fs40" );
              case "2" :  return( "\\b\\fs34" );
              case "3" :  return( "\\b\\fs29" );
              case "4" :  return( "\\b\\fs25" );
              case "5" :  return( "\\b\\fs23" );
              case "6" :  return( "\\b\\fs21" );
              default  :  return( "\\b\\fs21" );
            }
          }
          break;
        case FormatTag.COLOR      :  return( "\\cf4" );
        case FormatTag.HILITE     :  return( "\\highlight7" );
        case FormatTag.URL        :  return( "\\cs1\\ul\\cf2" );
      }
      return( "" );
    };
    FormattedText.ExportEndFunc end_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :
        case FormatTag.ITALICS    :
        case FormatTag.UNDERLINE  :
        case FormatTag.STRIKETHRU :
        case FormatTag.HEADER     :
        case FormatTag.COLOR      :
        case FormatTag.HILITE     :
        case FormatTag.URL        :
          return( ";}" );
      }
      return( "" );
    };
    FormattedText.ExportEncodeFunc encode_func = (str) => {
      return( str );
      // return( str.replace( @"\", @"\\" ).replace( "{", @"\{" ).replace( "}", @"\}" );
    };
    return( text.export( 0, text.text.char_count(), start_func, end_func, encode_func ) );
  }

  /* Traverses the node tree exporting XML nodes in OPML format */
  private static void export_node( FileOutputStream os, Node node, bool use_ul ) {
    if( node.children.length > 0 ) {
      for( int i=0; i<node.children.length; i++ ) {
        export_node( os, node.children.index( i ), use_ul );
      }
    }
  }

  /*
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
  */

}
