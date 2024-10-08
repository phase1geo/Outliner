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

public class Outliner : Gtk.Application {

  private static bool          show_version = false;
  private static bool          new_file     = false;
  private static bool          testing      = false;
  public  static string        version      = "1.7.0";
  public  static GLib.Settings settings;
  private        bool          loaded       = false;
  private        MainWindow    appwin;

  public Outliner () {

    Object( application_id: "com.github.phase1geo.outliner", flags: ApplicationFlags.HANDLES_OPEN );

    Intl.setlocale( LocaleCategory.ALL, "" );
    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );

    startup.connect( start_application );
    open.connect( open_files );

  }

  /* Begins execution of the application */
  private void start_application() {

    /* Initialize the settings */
    settings = new GLib.Settings( "com.github.phase1geo.outliner" );

    /* Add the application-specific icons */
    weak IconTheme default_theme = IconTheme.get_for_display( Gdk.Display.get_default() );
    default_theme.add_resource_path( "/com/github/phase1geo/outliner" );

    /* Add the application CSS */
    var provider = new Gtk.CssProvider ();
    provider.load_from_resource( "/com/github/phase1geo/outliner/css/style.css" );
    StyleContext.add_provider_for_display( Gdk.Display.get_default(), provider, STYLE_PROVIDER_PRIORITY_APPLICATION );

    /* Create the main window */
    appwin = new MainWindow( this, settings );

    /* Load the tab information */
    loaded = appwin.load_tab_state();

  }

  /* Parses the list of open files and stores them for opening later during activation */
  private void open_files( File[] files, string hint ) {
    foreach( File open_file in files ) {
      var file = open_file.get_path();
      if( !appwin.open_file( file ) ) {
        stderr.printf( "ERROR:  Unable to open file '%s'\n", file );
      }
    }
  }

  /* This is called if files aren't specified on the command-line */
  protected override void activate() {
    if( new_file || !loaded ) {
      appwin.do_new_file();
    }
  }

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "[files]" );
    var options = new OptionEntry[3];

    /* Create the command-line options */
    options[0] = {"version", 0, 0, OptionArg.NONE, ref show_version, "Display version number", null};
    options[1] = {"new", 'n', 0, OptionArg.NONE, ref new_file, "Starts Outliner with a new file", null};
    options[2] = {null};

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

    return( app.run( args ) );

  }

}

