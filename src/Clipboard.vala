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
  static Atom  NODES_ATOM        = Atom.intern_static_string( NODES_TARGET_NAME );
  static Atom  FTEXT_ATOM        = Atom.intern_static_string( FTEXT_TARGET_NAME );

  private static OutlineTable? table = null;
  private static Array<Node>?  nodes = null;
  private static string?       ftext = null;
  private static string?       text  = null;
  private static bool          set_internally = false;

  enum Target {
    STRING,
    FTEXT,
    NODES
  }

  const TargetEntry[] text_target_list = {
    { "text/plain",      0, Target.STRING },
    { "STRING",          0, Target.STRING },
    { FTEXT_TARGET_NAME, 0, Target.FTEXT }
  };

  const TargetEntry[] node_target_list = {
    { "text/plain",      0, Target.STRING },
    { "STRING",          0, Target.STRING },
    { NODES_TARGET_NAME, 0, Target.NODES }
  };

  public static void set_with_data( Clipboard clipboard, SelectionData selection_data, uint info, void* user_data_or_owner) {
    switch( info ) {
      case Target.STRING :
        if( text != null ) {
          selection_data.set_text( text, -1 );
        } else if( (nodes != null) && (nodes.length == 1) ) {
          selection_data.set_text( nodes.index( 0 ).name.text.text, -1 );
        }
        break;
      case Target.FTEXT :
        if( ftext != null ) {
          selection_data.@set( FTEXT_ATOM, 0, ftext.data );
        }
        break;
      case Target.NODES :
        if( (nodes != null) && (nodes.length > 0) ) {
          var text = table.serialize_node_for_copy( nodes.index( 0 ) );
          selection_data.@set( NODES_ATOM, 0, text.data );
        }
        break;
    }
  }

  /* Clears the class structure */
  public static void clear_data( Clipboard clipboard, void* user_data_or_owner ) {
    if( !set_internally ) {
      table = null;
      nodes = null;
      ftext = null;
      text  = null;
    }
    set_internally = false;
  }

  /* Copies the selected text to the clipboard */
  public static void copy_text( string ftxt, string txt ) {

    /* Store the data to copy */
    ftext          = ftxt;
    text           = txt;
    set_internally = true;

    /* Inform the clipboard */
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    clipboard.set_with_data( text_target_list, set_with_data, clear_data, null );

  }

  /* Copies the current selected node list to the clipboard */
  public static void copy_nodes( OutlineTable ot ) {

    /* Store the data to copy */
    table = ot;
    table.get_nodes_for_clipboard( out nodes );

    if( nodes.length > 0 ) {
      ftext = ot.serialize_text_for_copy( nodes.index( 0 ).name );
      text  = nodes.index( 0 ).name.text.text;
    }

    set_internally = true;

    /* Inform the clipboard */
    var clipboard = Gtk.Clipboard.get_default( Gdk.Display.get_default() );
    clipboard.set_with_data( node_target_list, set_with_data, clear_data, null );

  }

  /* Returns true if there are any nodes pasteable in the clipboard */
  public static bool node_pasteable() {
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    return( clipboard.wait_is_target_available( NODES_ATOM ) );
  }

  /* Called to paste current item in clipboard to the given DrawArea */
  public static void paste( OutlineTable table, bool shift ) {

    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );

    Atom[] targets;
    clipboard.wait_for_targets( out targets );

    Atom? nodes_atom = null;
    Atom? ftext_atom = null;
    Atom? text_atom  = null;

    /* Get the list of targets that we will support */
    foreach( var target in targets ) {
      switch( target.name() ) {
        case NODES_TARGET_NAME :  nodes_atom = target;  break;
        case FTEXT_TARGET_NAME :  ftext_atom = target;  break;
        case "text/plain"      :
        case "STRING"          :  text_atom  = target;  break;
      }
    }

    /* If we need to handle a node, do it here */
    if( nodes_atom != null ) {
      clipboard.request_contents( nodes_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        table.paste_node( data, shift );
      });

    /* If we need to handle formatted text, do it here */
    } else if( ftext_atom != null ) {
      clipboard.request_contents( ftext_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        table.paste_formatted_text( data, shift );
      });

    /* If we need to handle pasting text, do it here */
    } else if( text_atom != null ) {
      clipboard.request_contents( text_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        table.paste_text( data, shift );
      });
    }

  }

}
