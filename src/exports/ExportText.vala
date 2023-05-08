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

public class ExportText : Export {

  /* Constructor */
  public ExportText() {
    base( "text", _( "PlainText" ), {".txt"}, true, false, false );
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

    try {

      var nodes = table.root.children;
      for( int i=0; i<nodes.length; i++ ) {
        var name  = new FormattedText.copy_clean( table, nodes.index( i ).name.text );
        var title = "- " + name.text.replace( "\n", "\n  " ) + "\n";
        os.write( title.data );
        var children = nodes.index( i ).children;
        for( int j=0; j<children.length; j++ ) {
          export_node( os, table, children.index( j ) );
        }
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  /* Draws the given node and its children to the output stream */
  private void export_node( FileOutputStream os, OutlineTable table, Node node, string prefix = "        " ) {

    try {

      var title = prefix + "- ";
      var name  = new FormattedText.copy_clean( table, node.name.text );

      title += name.text.replace( "\n", "\n%s  ".printf( prefix ) ) + "\n";

      os.write( title.data );

      if( node.note.text.text != "" ) {
        var note = new FormattedText.copy_clean( table, node.note.text );
        var text = prefix + "    " + note.text.replace( "\n", "\n%s    ".printf( prefix ) ) + "\n";
        os.write( text.data );
      }

      var children = node.children;
      for( int i=0; i<children.length; i++ ) {
        export_node( os, table, children.index( i ), prefix + "        " );
      }

    } catch( Error e ) {
      // Handle error
    }

  }

}
