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

using Gtk;
using GLib;

public class Outliner : Granite.Application {

  private static bool          show_version = false;
  private static bool          new_file     = false;
  private static bool          testing      = false;
  public  static string        version      = "1.5.0";
  public  static GLib.Settings settings;
  private        bool          loaded       = false;
  private        MainWindow    appwin;

  public Outliner () {

    Object( application_id: "com.github.phase1geo.outliner", flags: ApplicationFlags.HANDLES_OPEN );

    startup.connect( start_application );
    open.connect( open_files );

  }

  /* Begins execution of the application */
  private void start_application() {

    /* Initialize the settings */
    settings = new GLib.Settings( "com.github.phase1geo.outliner" );

    /* Add the application-specific icons */
    weak IconTheme default_theme = IconTheme.get_default();
    default_theme.add_resource_path( "/com/github/phase1geo/outliner" );

    /* Add the application CSS */
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource( "/com/github/phase1geo/outliner/css/style.css" );
    Gtk.StyleContext.add_provider_for_screen( Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION );

    /* Create the main window */
    appwin = new MainWindow( this, settings );

    /* Load the tab information */
    loaded = appwin.load_tab_state();

    /* Handle any changes to the position of the window */
    appwin.configure_event.connect(() => {
      int root_x, root_y;
      int size_w, size_h;
      appwin.get_position( out root_x, out root_y );
      appwin.get_size( out size_w, out size_h );
      settings.set_int( "window-x", root_x );
      settings.set_int( "window-y", root_y );
      settings.set_int( "window-w", size_w );
      settings.set_int( "window-h", size_h );
      return( false );
    });

  }

  /* Parses the list of open files and stores them for opening later during activation */
  private void open_files( File[] files, string hint ) {
    hold();
    foreach( File open_file in files ) {
      var file = open_file.get_path();
      if( !appwin.open_file( file ) ) {
        stderr.printf( "ERROR:  Unable to open file '%s'\n", file );
      }
    }
    Gtk.main();
    release();
  }

  /* This is called if files aren't specified on the command-line */
  protected override void activate() {
    hold();
    if( new_file || !loaded ) {
      appwin.do_new_file();
    }
    Gtk.main();
    release();
  }

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "[files]" );
    var options = new OptionEntry[4];

    /* Create the command-line options */
    options[0] = {"version", 0, 0, OptionArg.NONE, ref show_version, "Display version number", null};
    options[1] = {"new", 'n', 0, OptionArg.NONE, ref new_file, "Starts Outliner with a new file", null};
    options[2] = {"run-tests", 0, 0, OptionArg.NONE, ref testing, "Run testing", null};
    options[3] = {null};

    /* Parse the arguments */
    try {
      context.set_help_enabled( true );
      context.add_main_entries( options, null );
      context.parse( ref args );
    } catch( OptionError e ) {
      stdout.printf( "ERROR: %s\n", e.message );
      stdout.printf( "Run '%s --help' to see valid options\n", args[0] );
      Process.exit( 1 );
    }

    /* If the version was specified, output it and then exit */
    if( show_version ) {
      stdout.printf( "%s\n", version );
      Process.exit( 0 );
    }

  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {

    var app = new Outliner();
    app.parse_arguments( ref args );

    if( testing ) {
      Gtk.init( ref args );
      var testing = new App.Tests.Testing( args );
      Idle.add(() => {
        testing.run();
        Gtk.main_quit();
        return( false );
      });
      Gtk.main();
      return( 0 );
    } else {
      return( app.run( args ) );
    }

  }

}

