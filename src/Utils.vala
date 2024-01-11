/*
* Copyright (c) 2020 (https://github.com/phase1geo/Minder)
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
using Gdk;
using Cairo;

public class Utils {

  /* Returns true if the specified version is older than this version */
  public static bool is_version_older( string other_version ) {
    var my_parts    = Outliner.version.split( "." );
    var other_parts = other_version.split( "." );
    for( int i=0; i<my_parts.length; i++ ) {
      if( int.parse( other_parts[i] ) < int.parse( my_parts[i] ) ) {
        return( true );
      }
    }
    return( false );
  }

  /*
   Helper function for converting an RGBA color value to a stringified color
   that can be used by a markup parser.
  */
  public static string color_from_rgba( RGBA rgba ) {
    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );
  }

  /* Sets the context source color to the given color value */
  public static void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /*
   Sets the context source color to the given color value overriding the
   alpha value with the given value.
  */
  public static void set_context_color_with_alpha( Context ctx, RGBA color, double alpha ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, alpha );
  }

  /*
   Checks the given string to see if it is a match to the given pattern.  If
   it is, the matching portion of the string appended to the list of matches.
  */
  /*
  public static void match_string( string pattern, string value, string type, Node? node, ref Gtk.ListStore matches ) {
    int index = value.casefold().index_of( pattern );
    if( index != -1 ) {
      TreeIter it;
      int    start_index = (index > 20) ? (index - 20) : 0;
      string prefix      = (index > 20) ? "…"        : "";
      string str         = prefix +
                           value.substring( start_index, (index - start_index) ) + "<u>" +
                           value.substring( index, pattern.length ) + "</u>" +
                           value.substring( (index + pattern.length), -1 );
      matches.append( out it );
      matches.set( it, 0, type, 1, str, 2, node, 3, conn, -1 );
    }
  }
  */

  /* Returns true if the given coordinates are within the specified bounds */
  public static bool is_within_bounds( double x, double y, double bx, double by, double bw, double bh ) {
    return( (bx <= x) && (x < (bx + bw)) && (by <= y) && (y < (by + bh)) );
  }

  /* Returns a string that is suitable to use as an inspector title */
  public static string make_title( string str ) {
    return( "<b>" + str + "</b>" );
  }

  /* Returns a string that is used to display a tooltip with displayed accelerator */
  public static string tooltip_with_accel( string tooltip, string accel ) {
    string[] accels = {accel};
    return( Granite.markup_accel_tooltip( accels, tooltip ) );
  }

  /* Opens the given URL in the proper external default application */
  public static void open_url( string url ) {
    try {
      AppInfo.launch_default_for_uri( url, null );
    } catch( GLib.Error e ) {}
  }

  /* Converts the given Markdown into HTML */
  public static string markdown_to_html( string md, string tag ) {
    string html;
    var    flags = 0x47607004;
    var    mkd   = new Markdown.Document.gfm_format( md.data, flags );
    mkd.compile( flags );
    mkd.get_document( out html );
    return( "<" + tag + ">" + html + "</" + tag + ">" );
  }

  /* Returns the line height of the first line of the given pango layout */
  public static double get_line_height( Pango.Layout layout ) {
    int height;
    var line = layout.get_line_readonly( 0 );
    if( line == null ) {
      int width;
      layout.get_size( out width, out height );
    } else {
      Pango.Rectangle ink_rect, log_rect;
      line.get_extents( out ink_rect, out log_rect );
      height = log_rect.height;
    }
    return( height / Pango.SCALE );
  }

  /* Searches for the beginning or ending word */
  public static int find_word( string str, int cursor, bool wordstart ) {
    try {
      MatchInfo match_info;
      var substr = wordstart ? str.substring( 0, cursor ) : str.substring( cursor );
      var re = new Regex( wordstart ? ".*(\\W\\w|[\\w\\s][^\\w\\s])" : "(\\w\\W|[^\\w\\s][\\w\\s])" );
      if( re.match( substr, 0, out match_info ) ) {
        int start_pos, end_pos;
        match_info.fetch_pos( 1, out start_pos, out end_pos );
        return( wordstart ? (start_pos + 1) : (cursor + start_pos + 1) );
      }
    } catch( RegexError e ) {}
    return( -1 );
  }

  /* Returns the rootname of the given filename */
  public static string rootname( string filename ) {
    var basename = GLib.Path.get_basename( filename );
    var parts    = basename.split( "." );
    if( parts.length > 2 ) {
      return( string.joinv( ".", parts[0:parts.length-1] ) );
    } else {
      return( parts[0] );
    }
  }

  /* Show the specified popover */
  public static void show_popover( Popover popover ) {
#if GTK322
    popover.popup();
#else
    popover.show();
#endif
  }

  /* Hide the specified popover */
  public static void hide_popover( Popover popover ) {
#if GTK322
    popover.popdown();
#else
    popover.hide();
#endif
  }

  public static void set_chooser_folder( FileChooser chooser ) {
    var dir = Outliner.settings.get_string( "last-directory" );
    if( dir != "" ) {
      chooser.set_current_folder( dir );
    }
  }

  public static void store_chooser_folder( string file, bool is_dir ) {
    var dir = is_dir ? file : GLib.Path.get_dirname( file );
    Outliner.settings.set_string( "last-directory", dir );
  }

}
