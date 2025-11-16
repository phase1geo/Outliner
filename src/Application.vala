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

using Gtk;
using GLib;

public class Outliner : Gtk.Application {

  public  static string        version = "2.0.0";
  public  static GLib.Settings settings;
  private        MainWindow    appwin;

  //-------------------------------------------------------------
  // Constructor
  public Outliner () {

    Object( application_id: "com.github.phase1geo.outliner", flags: ApplicationFlags.HANDLES_COMMAND_LINE );

    Intl.setlocale( LocaleCategory.ALL, "" );
    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );

    startup.connect( start_application );
    command_line.connect( handle_command_line );

  }

  //-------------------------------------------------------------
  // Begins execution of the application
  private void start_application() {

    // Initialize the settings
    settings = new GLib.Settings( "com.github.phase1geo.outliner" );

    // Add the application-specific icons
    weak IconTheme default_theme = IconTheme.get_for_display( Gdk.Display.get_default() );
    default_theme.add_resource_path( "/com/github/phase1geo/outliner" );

    // Add the application CSS
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource( "/com/github/phase1geo/outliner/css/style.css" );
    StyleContext.add_provider_for_display( Gdk.Display.get_default(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    // Create the main window
    appwin = new MainWindow( this );

    // Load the tab information
    appwin.load_tab_state();

  }

  //-------------------------------------------------------------
  // Called when the command-line argument handler exits.
  private int end_cl( ApplicationCommandLine cl, int status ) {
    // If we are the primary instance, exit now
    if( !cl.get_is_remote() ) {
      Process.exit( status );
    } else {
      cl.set_exit_status( status );
      cl.done();
    }
    return( status );
  }

  //-------------------------------------------------------------
  // Parse the command-line arguments
  private int handle_command_line( ApplicationCommandLine cl ) {

    var show_version = false;
    var show_help    = false;
    var new_file     = false;

    var context = new OptionContext( "[files]" );
    var options = new OptionEntry[4];
    var args    = cl.get_arguments();

    // Create the command-line options
    options[0] = {"version", 0, 0, OptionArg.NONE, ref show_version, "Display version number", null};
    options[1] = {"help", 0, 0, OptionArg.NONE, ref show_help, "Display this help information", null};
    options[2] = {"new", 'n', 0, OptionArg.NONE, ref new_file, "Starts Outliner with a new file", null};
    options[3] = {null};

    // Parse the arguments
    try {
      context.set_help_enabled( false );
      context.add_main_entries( options, null );
      context.parse_strv( ref args );
    } catch( OptionError e ) {
      stdout.printf( _( "ERROR: %s\n" ), e.message );
      stdout.printf( _( "Run '%s --help' to see valid options\n" ), args[0] );
      return( end_cl( cl, 1 ) );
    }

    if( show_help ) {
      stdout.printf( context.get_help( true, null ) );
      return( end_cl( cl, 0 ) );
    }

    // If the version was specified, output it and then exit
    if( show_version ) {
      stdout.printf( "%s\n", version );
      return( end_cl( cl, 0 ) );
    }

    // This is called if files aren't specified on the command-line
    if( new_file ) {
      appwin.do_new_file();
    } else {
      for( int i=1; i<args.length; i++ ) {
        var file = args[i];
        if( !appwin.open_file( file ) ) {
          stdout.printf( _( "ERROR:  Unable to open file '%s'\n" ), file );
        }
      }
    }

    return( 0 );

  }

  //-------------------------------------------------------------
  // Main routine which gets everything started
  public static int main( string[] args ) {

    var app = new Outliner();
    return( app.run( args ) );

  }

}

