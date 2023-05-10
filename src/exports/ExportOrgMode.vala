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
using Gtk;

public class ExportOrgMode : Export {

  /* Constructor */
  public ExportOrgMode() {
    base( "org-mode", _( "Org-Mode" ), {".org"}, true, false, false );
  }

  /* Add settings for Org Mode */
  public override void add_settings( Grid grid ) {
    add_setting_bool( "indent-mode", grid, _( "Indent Mode" ), _( "Export using indentation spaces" ), true );
  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {
    var value = get_bool( "indent-mode" );
    node->set_prop( "indent-mode", value.to_string() );
  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {
    var q = node->get_prop( "indent-mode" );
    if( q != null ) {
      var value = bool.parse( q );
      set_bool( "indent-mode", value );
    }
  }

  private string sprefix() {
    return( get_bool( "indent-mode" ) ? "  " : "*" );
  }

  private string wrap( string prefix ) {
    return( get_bool( "indent-mode" ) ? (prefix + " ") : "" );
  }

  private string linestart( string prefix ) {
    return( get_bool( "indent-mode" ) ? (prefix + "  ") : "" );
  }

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, OutlineTable table ) {
    var  file   = File.new_for_path( fname );
    bool retval = true;
    try {
      var os = file.replace( null, false, FileCreateFlags.NONE );
      export_top_nodes( os, table );
    } catch( Error e ) {
      retval = false;
    }
    return( retval );
  }

  /* Draws each of the top-level nodes */
  private void export_top_nodes( FileOutputStream os, OutlineTable table ) {
    if( table.title != null ) {
      var title = "* " + table.title.text.text + "\n\n";
      os.write( title.data );
    }
    var nodes = table.root.children;
    for( int i=0; i<nodes.length; i++ ) {
      export_node( os, table, nodes.index( i ), sprefix() );
    }
  }

  public static string from_text( FormattedText text ) {
    ExportUtils.ExportStartFunc start_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :  return( "*");
        case FormatTag.ITALICS    :  return( "/" );
        case FormatTag.UNDERLINE  :  return( "_" );
        case FormatTag.STRIKETHRU :  return( "+" );
        case FormatTag.CODE       :  return( "~" );
        case FormatTag.URL        :  return( "[[%s][".printf( extra ) );
        default                   :  return( "" );
      }
    };
    ExportUtils.ExportEndFunc end_func = (tag, start, extra) => {
      switch( tag ) {
        case FormatTag.BOLD       :  return( "*" );
        case FormatTag.ITALICS    :  return( "/" );
        case FormatTag.UNDERLINE  :  return( "_" );
        case FormatTag.STRIKETHRU :  return( "+" );
        case FormatTag.CODE       :  return( "~" );
        case FormatTag.URL        :  return( "]]" );
        default                   :  return( "" );
      }
    };
    ExportUtils.ExportEncodeFunc encode_func = (str) => {
      return( str.replace( "*", "\\*" ).replace( "_", "\\_" ).replace( "~", "\\~" ).replace( "+", "\\+" ) );
    };
    return( ExportUtils.export( text, start_func, end_func, encode_func ) );
  }

  /* Draws the given node and its children to the output stream */
  private void export_node( FileOutputStream os, OutlineTable table, Node node, string prefix = "  " ) {

    try {

      string title = prefix + "* ";

      switch( node.task ) {
        case NodeTaskMode.DONE  :  title += "[x] ";  break;
        case NodeTaskMode.OPEN  :  title += "[ ] ";  break;
        case NodeTaskMode.DOING :  title += "[-] ";  break;
      }

      var name = new FormattedText.copy_clean( table, node.name.text );
      title += from_text( name ).replace( "\n", wrap( prefix ) ) + "\n";

      os.write( title.data );

      if( node.note.text.text != "" ) {
        var note = new FormattedText.copy_clean( table, node.note.text );
        var str  = "\n" + linestart( prefix ) + from_text( note ).replace( "\n", "\n" + linestart( prefix ) ) + "\n";
        os.write( str.data );
      }

      os.write( "\n".data );

      var children = node.children;
      for( int i=0; i<children.length; i++ ) {
        export_node( os, table, children.index( i ), prefix + sprefix() );
      }

    } catch( Error e ) {
      // Handle error
    }

  }

  //----------------------------------------------------------------------------

  /* Imports an Org-Mode file and display it in the given outline table */
  public override bool import( string fname, OutlineTable table ) {

    return( false );

  }

}
