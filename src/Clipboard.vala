/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

using Gtk;
using GLib;
using Gdk;

public class OutlinerClipboard {

  const string NODES_TARGET_NAME = "x-application/outliner-nodes";
  const string FTEXT_TARGET_NAME = "x-application/outliner-text";

  /* Copies the selected text to the clipboard */
  public static void copy_text( string ftxt, string txt ) {

    /* Inform the clipboard */
    var clipboard = Display.get_default().get_clipboard();
    clipboard.set_text( txt );

    var bytes    = new Bytes( ftxt.data );
    var provider = new ContentProvider.for_bytes( FTEXT_TARGET_NAME, bytes );
    clipboard.set_content( provider );

  }

  /* Copies the current selected node list to the clipboard */
  public static void copy_nodes( OutlineTable ot ) {

    Array<Node> nodes;

    /* Store the data to copy */
    ot.get_nodes_for_clipboard( out nodes );

    if( nodes.length > 0 ) {

      var clipboard = Display.get_default().get_clipboard();
      var ntxt      = ot.serialize_node_for_copy( nodes.index( 0 ) );
      var bytes     = new Bytes( ntxt.data );
      var provider  = new ContentProvider.for_bytes( NODES_TARGET_NAME, bytes );
      clipboard.set_content( provider );

    }

  }

  /* Returns true if there are any nodes pasteable in the clipboard */
  public static bool node_pasteable() {

    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_mime_type( NODES_TARGET_NAME ) );

  }

  /* Called to paste current item in clipboard to the given DrawArea */
  public static void paste( OutlineTable table, bool shift ) {

    var clipboard = Display.get_default().get_clipboard();

    try {
      if( clipboard.get_formats().contain_mime_type( NODES_TARGET_NAME ) ) {
        clipboard.read_async.begin( { NODES_TARGET_NAME }, 0, null, (obj, res) => {
          string str;
          var stream = clipboard.read_async.end( res, out str );
          var contents = Utils.read_stream( stream );
          table.paste_node( contents, shift );
        });
      } else if( clipboard.get_formats().contain_mime_type( FTEXT_TARGET_NAME ) ) {
        clipboard.read_async.begin( { FTEXT_TARGET_NAME }, 0, null, (obj, res) => {
          string str;
          var stream = clipboard.read_async.end( res, out str );
          var contents = Utils.read_stream( stream );
          table.paste_formatted_text( contents, shift );
        });
      } else if( clipboard.get_formats().contain_gtype( Type.STRING ) ) {
        clipboard.read_text_async.begin( null, (obj, res) => {
          var text = clipboard.read_text_async.end( res );
          table.paste_text( text, shift );
        });
      }
    } catch( Error e ) {}

  }

}
