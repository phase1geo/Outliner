/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

using Gdk;

public enum TableState {
  NONE,
  NODE,
  EDITING;

  //-------------------------------------------------------------
  // Returns the state from the given outline table
  public static TableState get_state( OutlineTable ot ) {
    if( ot.is_node_editable() || ot.is_note_editable() || ot.is_title_editable() ) {
      return( EDITING );
    } else if( ot.selected != null ) {
      return( NODE );
    } else {
      return( NONE );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given state matches that required for the
  // given command.
  public static bool matches( TableState state, KeyCommand command ) {
    var for_node = command.for_node();
    var for_edit = command.for_editing();
    var for_none = command.for_none();
    var for_any  = !for_node && !for_edit && !for_none;
    return(
      (for_node && (state == TableState.NODE))    ||
      (for_edit && (state == TableState.EDITING)) ||
      (for_none && (state == TableState.NONE))    ||
      for_any
    );
  }

}

public class Shortcut {

  private uint           _keycode;
  private bool           _control;
  private bool           _shift;
  private bool           _alt;
  private KeyCommand     _command;
  private KeyCommandFunc _func;

  public KeyCommand command {
    get {
      return( _command );
    }
  }

  //-------------------------------------------------------------
  // Default constructor.
  public Shortcut( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    _keycode = keycode;
    _control = control;
    _shift   = shift;
    _alt     = alt;
    _command = command;
    _func    = command.get_func();
  }

  //-------------------------------------------------------------
  // Constructor from XML.
  public Shortcut.from_xml( Xml.Node* node ) {
    load( node );
  }

  //-------------------------------------------------------------
  // Returns true if our keycode matches the input keycode from
  // the user.
  private bool has_key( uint[] kvs ) {
    foreach( uint kv in kvs ) {
      if( kv == _keycode ) return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given values exactly.
  public bool conflicts_with( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    return(
      (_keycode == keycode) &&
      (_control == control) &&
      (_shift   == shift)   &&
      (_alt     == alt)     &&
      (_command != command) &&
      _command.target_matches( command )
    );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the contents of the provided
  // shortcut.
  public bool matches_shortcut( Shortcut shortcut ) {
    return( (_keycode == shortcut._keycode) &&
            (_control == shortcut._control) &&
            (_shift   == shortcut._shift)   &&
            (_alt     == shortcut._alt)     &&
            (_command == shortcut._command) );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given command.
  public bool matches_command( KeyCommand command ) {
    return( _command == command );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given match values
  public bool matches_keypress( bool control, bool shift, bool alt, uint[] kvs, TableState state ) {
    return(
      (_control == control) &&
      (_shift   == shift)   &&
      (_alt     == alt)     &&
      has_key( kvs )        &&
      TableState.matches( state, _command )
    );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut can be edited by the user and
  // needs to be saved to the shortcuts.xml file.
  public bool editable() {
    return( _command.editable() );
  }

  //-------------------------------------------------------------
  // Executes the stored function with the given map.
  public void execute( OutlineTable ot ) {
    _func( ot );
  }

  //-------------------------------------------------------------
  // Returns the Gtk4 accelerator for this shortcut.
  public string get_accelerator() {
    var accel = "";
    if( _control ) {
      accel += "<Control>";
    }
    if( _shift &&
        (!keyval_is_lower( _keycode ) ||
         !keyval_is_upper( _keycode ) ||
         (_keycode == Key.Delete)     ||
         (_keycode == Key.BackSpace)  ||
         (_keycode == Key.Tab)        ||
         (_keycode == Key.Return))
    ) {
      accel += "<Shift>";
    }
    if( _alt ) {
      accel += "<Alt>";
    }
    accel += keyval_name( _keycode );
    return( accel );
  }

  //-------------------------------------------------------------
  // Returns a string with the shortcut string to display in the
  // preferences label.
  public string get_label() {
    string[] lbl = {};
    unichar  uc  = keyval_to_unicode( _keycode );
    string   str = "";
    if( _control ) {
      lbl += "Ctrl";
    }
    if( _shift ) {
      lbl += "Shift";
    }
    if( _alt ) {
      lbl += "Alt";
    }
    lbl += uc.isprint() ? uc.to_string().up() : keyval_name( _keycode );
    return( string.joinv( "+", lbl ) );
  }

  //-------------------------------------------------------------
  // Outputs a debuggable string version of this shortcut.
  public string to_string() {
    return( ( "Ctrl: %s, Shift: %s, Alt: %s, Key: %s, Command: %s" ).printf( _control.to_string(), _shift.to_string(), _alt.to_string(), _keycode.to_string(), _command.to_string() ) );
  }

  //-------------------------------------------------------------
  // Saves the contents of this shortcut to an XML node and returns
  // it.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "shortcut" );
    node->set_prop( "key",     _keycode.to_string() );
    node->set_prop( "control", _control.to_string() );
    node->set_prop( "shift",   _shift.to_string() );
    node->set_prop( "alt",     _alt.to_string() );
    node->set_prop( "command", _command.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads this shortcut from an XML node.
  private void load( Xml.Node* node ) {
    var k = node->get_prop( "key" );
    if( k != null ) {
      _keycode = uint.parse( k );
    }
    var c = node->get_prop( "control" );
    if( c != null ) {
      _control = bool.parse( c );
    }
    var s = node->get_prop( "shift" );
    if( s != null ) {
      _shift = bool.parse( s );
    }
    var a = node->get_prop( "alt" );
    if( a != null ) {
      _alt = bool.parse( a );
    }
    var cmd = node->get_prop( "command" );
    if( cmd != null ) {
      _command = KeyCommand.parse( cmd );
      _func    = _command.get_func();
    }
  }

}


public class Shortcuts {

  private Array<Shortcut> _shortcuts;
  private Array<Shortcut> _defaults;

  public signal void shortcut_changed( KeyCommand command, Shortcut? shortcut );

  //-------------------------------------------------------------
  // Default constructor
  public Shortcuts() {

    _shortcuts = new Array<Shortcut>();
    _defaults  = new Array<Shortcut>();

    create_default_shortcuts();

    add_builtin_shortcuts();
    add_default_shortcuts();

    load();

  }

  //-------------------------------------------------------------
  // Removes the shortcut associated with the given command.  Returns
  // true if the shortcut is found and removed.
  private bool remove_shortcut( KeyCommand command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_command( command ) ) {
        _shortcuts.remove_index( i );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Clears the shortcut for the given command, if it exists.
  // Called by the shortcut preferences class.
  public void clear_shortcut( KeyCommand command ) {
    if( remove_shortcut( command ) ) {
      shortcut_changed( command, null );
      save();
    }
  }

  //-------------------------------------------------------------
  // Clears all of the shortcuts
  public void clear_all_shortcuts() {
    for( int i=0; i<KeyCommand.NUM; i++ ) {
      var command = (KeyCommand)i;
      if( remove_shortcut( command ) ) {
        shortcut_changed( command, null );
      }
    }
  }

  //-------------------------------------------------------------
  // Sets the shortcut for the given command.  Called by the
  // shortcut preferences class.
  public void set_shortcut( Shortcut shortcut ) {
    remove_shortcut( shortcut.command );
    _shortcuts.append_val( shortcut );
    shortcut_changed( shortcut.command, shortcut );
    save();
  }

  //-------------------------------------------------------------
  // Returns the shortcut associated with the given command in the
  // current map state.  If none is found, returns null.
  public Shortcut? get_shortcut( KeyCommand command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_command( command ) ) {
        return( _shortcuts.index( i ) );
      }
    }
    return( null ); 
  }

  //-------------------------------------------------------------
  // Returns the default shortcut associated with the given
  // keycommand and return it.  If it cannot be found, return
  // null.
  public Shortcut? get_default_shortcut( KeyCommand command ) {
    for( int i=0; i<_defaults.length; i++ ) {
      if( _defaults.index( i ).matches_command( command ) ) {
        return( _defaults.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Checks to see if the given shortcut is already mapped.
  public Shortcut? shortcut_conflicts_with( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).conflicts_with( keycode, control, shift, alt, command ) ) {
        return( _shortcuts.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Executes the command associated with the given keypress
  // information.  If no shortcut exists, return false to indicate
  // that the calling code should insert the character if we are
  // editing an element in the map.
  public bool execute( OutlineTable ot, uint keyval, uint keycode, ModifierType mods ) {

    KeymapKey[] ks      = {};
    uint[]      kvs     = {};
    var         state   = TableState.get_state( ot );
    var         control = (mods & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK;
    var         shift   = (mods & ModifierType.SHIFT_MASK)   == ModifierType.SHIFT_MASK;
    var         alt     = (mods & ModifierType.ALT_MASK)     == ModifierType.ALT_MASK;

    Display.get_default().map_keycode( keycode, out ks, out kvs );

    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_keypress( control, shift, alt, kvs, state ) ) {
        _shortcuts.index( i ).execute( ot );
        return( true );
      }
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Returns the path of the shortcuts file.
  private string shortcuts_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "outliner", "shortcuts.xml" ) );
  }

  //-------------------------------------------------------------
  // Returns true if the given shortcut is different than the default
  // version of this shortcut (if a default exists).  If the default
  // does not exist, returns true.
  private bool differs_from_default( Shortcut shortcut ) {
    var dflt = get_default_shortcut( shortcut.command );
    return( (dflt == null) || !dflt.matches_shortcut( shortcut ) );
  }

  //-------------------------------------------------------------
  // Saves the shortcuts to the shortcuts XML file.
  public void save() {

    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "shortcuts" );

    doc->set_root_element( root );

    for( int i=0; i<_shortcuts.length; i++ ) {
      var shortcut = _shortcuts.index( i );
      if( shortcut.editable() && differs_from_default( shortcut ) ) {
        root->add_child( shortcut.save() );
      }
    }

    /* Save the file */
    doc->save_format_file( shortcuts_path(), 1 );

    delete doc;

  }

  //-------------------------------------------------------------
  // Loads the shortcuts from the shortcuts XML file.
  private void load() {

    if( !FileUtils.test( shortcuts_path(), FileTest.EXISTS ) ) return;

    Xml.Doc* doc = Xml.Parser.parse_file( shortcuts_path() );

    if( doc == null ) {
      return;
    }

    var root = doc->get_root_element();

    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "shortcut") ) {
        var shortcut = new Shortcut.from_xml( it );
        _shortcuts.append_val( shortcut );
      }
    }

    delete doc;

  }

  //-------------------------------------------------------------
  // Adds a single shortcut to the list of shortcuts.
  private void add_shortcut( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    var shortcut = new Shortcut( keycode, control, shift, alt, command );
    _shortcuts.append_val( shortcut );
  }

  //-------------------------------------------------------------
  // Creates a shortcut from the given information and adds it to the
  // list of default shortcuts.
  private void add_default( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    var shortcut = new Shortcut( keycode, control, shift, alt, command );
    _defaults.append_val( shortcut );
  }

  //-------------------------------------------------------------
  // Adds all of the default shortcuts to the shortcuts array.
  // This will be called internally if the shortcuts.xml file
  // does not exist.
  public void add_default_shortcuts() {
    for( int i=0; i<_defaults.length; i++ ) {
      _shortcuts.append_val( _defaults.index( i ) );
      // FOOBAR
    }
  }

  //-------------------------------------------------------------
  // Restores all of the default shortcuts
  public void restore_default_shortcuts() {
    clear_all_shortcuts();
    add_builtin_shortcuts();
    add_default_shortcuts();
    for( int i=0; i<_shortcuts.length; i++ ) {
      shortcut_changed( _shortcuts.index( i ).command, _shortcuts.index( i ) );
    }
  }

  //-------------------------------------------------------------
  // Creates the built-in shortcuts (these are not stored in the
  // shortcuts.xml file and therefore cannot be changed by the user)
  public void add_builtin_shortcuts() {

    add_shortcut( Key.Escape,    false, false, false, KeyCommand.ESCAPE );
    add_shortcut( Key.Escape,    false, false, false, KeyCommand.EDIT_ESCAPE );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.EDIT_BACKSPACE );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.NODE_REMOVE );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.EDIT_DELETE );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.NODE_REMOVE );

    add_shortcut( Key.Return,    false, false, false, KeyCommand.EDIT_RETURN );
    // add_shortcut( Key.Return,    false, false, false, KeyCommand.NODE_ADD_SIBLING_AFTER );
    add_shortcut( Key.Return,    false, true,  false, KeyCommand.EDIT_SHIFT_RETURN );
    // add_shortcut( Key.Return,    false, true,  false, KeyCommand.NODE_ADD_SIBLING_BEFORE );
    add_shortcut( Key.Tab,       false, false, false, KeyCommand.EDIT_TAB );
    // add_shortcut( Key.Tab,       false, false, false, KeyCommand.NODE_ADD_CHILD );
    add_shortcut( Key.Tab,       false, true,  false, KeyCommand.EDIT_SHIFT_TAB );
    // add_shortcut( Key.Tab,       false, true,  false, KeyCommand.NODE_ADD_PARENT );
    add_shortcut( Key.Right,     false, false, false, KeyCommand.EDIT_CURSOR_CHAR_NEXT );
    add_shortcut( Key.Right,     false, true,  false, KeyCommand.EDIT_SELECT_CHAR_NEXT );
    add_shortcut( Key.Left,      false, false, false, KeyCommand.EDIT_CURSOR_CHAR_PREV );
    add_shortcut( Key.Left,      false, true,  false, KeyCommand.EDIT_SELECT_CHAR_PREV );
    add_shortcut( Key.Up,        false, false, false, KeyCommand.EDIT_CURSOR_UP );
    add_shortcut( Key.Up,        false, false, false, KeyCommand.NODE_SELECT_UP );
    // add_shortcut( Key.Up,        false, false, true,  KeyCommand.NODE_SWAP_UP );
    add_shortcut( Key.Up,        false, true,  false, KeyCommand.EDIT_SELECT_UP );
    add_shortcut( Key.Down,      false, false, false, KeyCommand.EDIT_CURSOR_DOWN );
    add_shortcut( Key.Down,      false, false, false, KeyCommand.NODE_SELECT_DOWN );
    // add_shortcut( Key.Down,      false, false, true,  KeyCommand.NODE_SWAP_DOWN );
    add_shortcut( Key.Down,      false, true,  false, KeyCommand.EDIT_SELECT_DOWN );
    add_shortcut( Key.Control_L, false, false, false, KeyCommand.CONTROL_PRESSED );
    add_shortcut( Key.Control_R, false, false, false, KeyCommand.CONTROL_PRESSED );

  }

  //-------------------------------------------------------------
  // If the shortcuts file is missing, we will create the default
  // set of shortcuts and save them to the save file.
  private void create_default_shortcuts() {

    add_default( Key.n,            true, false, false, KeyCommand.FILE_NEW );
    add_default( Key.o,            true, false, false, KeyCommand.FILE_OPEN );
    add_default( Key.s,            true, false, false, KeyCommand.FILE_SAVE );
    add_default( Key.s,            true, true,  false, KeyCommand.FILE_SAVE_AS );
    add_default( Key.q,            true, false, false, KeyCommand.QUIT );
    add_default( Key.z,            true, false, false, KeyCommand.UNDO_ACTION );
    add_default( Key.z,            true, true,  false, KeyCommand.REDO_ACTION );
    add_default( Key.@0,           true, false, false, KeyCommand.ZOOM_ACTUAL );
    add_default( Key.plus,         true, false, false, KeyCommand.ZOOM_IN );
    add_default( Key.minus,        true, false, false, KeyCommand.ZOOM_OUT );
    add_default( Key.p,            true, false, false, KeyCommand.FILE_PRINT );
    add_default( Key.comma,        true, false, false, KeyCommand.SHOW_PREFERENCES );
    add_default( Key.question,     true, false, false, KeyCommand.SHOW_SHORTCUTS );
    add_default( Key.Tab,          true, false, false, KeyCommand.TAB_GOTO_NEXT );
    add_default( Key.Tab,          true, true,  false, KeyCommand.TAB_GOTO_PREV );
    add_default( Key.f,            true, true,  false, KeyCommand.TOGGLE_FOCUS_MODE );
    add_default( Key.f,            true, false, false, KeyCommand.SEARCH );
    add_default( Key.w,            true, false, false, KeyCommand.TAB_CLOSE_CURRENT );

    add_default( Key.c,            true, false, false, KeyCommand.EDIT_COPY );
    add_default( Key.x,            true, false, false, KeyCommand.EDIT_CUT );
    add_default( Key.v,            true, false, false, KeyCommand.EDIT_PASTE );
    add_default( Key.v,            true, true,  false, KeyCommand.NODE_PASTE_REPLACE );
    add_default( Key.Return,       true, false, false, KeyCommand.EDIT_INSERT_NEWLINE );
    add_default( Key.Return,       true, true,  false, KeyCommand.EDIT_SPLIT_LINE );
    add_default( Key.BackSpace,    true, false, false, KeyCommand.EDIT_REMOVE_WORD_PREV );
    add_default( Key.Delete,       true, false, false, KeyCommand.EDIT_REMOVE_WORD_NEXT );
    add_default( Key.Tab,          true, false, false, KeyCommand.EDIT_INSERT_TAB );
    add_default( Key.Right,        true, true,  false, KeyCommand.EDIT_SELECT_WORD_NEXT );
    add_default( Key.Right,        true, false, false, KeyCommand.EDIT_CURSOR_WORD_NEXT );
    add_default( Key.Left,         true, true,  false, KeyCommand.EDIT_SELECT_WORD_PREV );
    add_default( Key.Left,         true, false, false, KeyCommand.EDIT_CURSOR_WORD_PREV );
    add_default( Key.Up,           true, true,  false, KeyCommand.EDIT_SELECT_START_UP );
    add_default( Key.Up,           true, false, false, KeyCommand.EDIT_CURSOR_FIRST );
    add_default( Key.Down,         true, true,  false, KeyCommand.EDIT_SELECT_END_DOWN );
    add_default( Key.Down,         true, false, false, KeyCommand.EDIT_CURSOR_LAST );
    add_default( Key.Home,         true, true,  false, KeyCommand.EDIT_SELECT_START_HOME );
    add_default( Key.Home,         true, false, false, KeyCommand.EDIT_CURSOR_LINESTART );
    add_default( Key.End,          true, true,  false, KeyCommand.EDIT_SELECT_END_END );
    add_default( Key.End,          true, false, false, KeyCommand.EDIT_CURSOR_LINEEND );
    add_default( Key.a,            true, false, false, KeyCommand.EDIT_SELECT_ALL );
    add_default( Key.slash,        true, false, false, KeyCommand.EDIT_SELECT_ALL );
    add_default( Key.a,            true, true,  false, KeyCommand.EDIT_SELECT_NONE );
    add_default( Key.backslash,    true, false, false, KeyCommand.EDIT_SELECT_NONE );
    add_default( Key.period,       true, false, false, KeyCommand.EDIT_INSERT_EMOJI );
    add_default( Key.k,            true, false, false, KeyCommand.EDIT_ADD_URL );
    add_default( Key.k,            true, true,  false, KeyCommand.EDIT_REMOVE_URL );
    add_default( Key.b,            true, false, false, KeyCommand.EDIT_BOLD );
    add_default( Key.i,            true, false, false, KeyCommand.EDIT_ITALICS );
    add_default( Key.u,            true, false, false, KeyCommand.EDIT_UNDERLINE );
    add_default( Key.t,            true, false, false, KeyCommand.EDIT_STRIKETHRU );

    add_default( Key.F10,          false, true,  false, KeyCommand.SHOW_CONTEXTUAL_MENU );

    add_default( Key.Tab,          false, false, false, KeyCommand.NODE_INDENT );
    add_default( Key.Tab,          false, true,  false, KeyCommand.NODE_UNINDENT );
    add_default( Key.Down,         true,  false, false, KeyCommand.NODE_MOVE_DOWN );
    add_default( Key.Up,           true,  false, false, KeyCommand.NODE_MOVE_UP );
    add_default( Key.a,            true,  false, false, KeyCommand.NODE_MOVE_PARENT_BELOW );
    add_default( Key.a,            true,  true,  false, KeyCommand.NODE_MOVE_PARENT_ABOVE );
    add_default( Key.@1,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_1 );
    add_default( Key.@2,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_2 );
    add_default( Key.@3,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_3 );
    add_default( Key.@4,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_4 );
    add_default( Key.@5,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_5 );
    add_default( Key.@6,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_6 );
    add_default( Key.@7,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_7 );
    add_default( Key.@8,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_8 );
    add_default( Key.@9,           true,  false, false, KeyCommand.NODE_MOVE_TO_LABEL_9 );

    add_default( Key.t,            false, true,  false, KeyCommand.NODE_SELECT_TOP );
    add_default( Key.b,            false, true,  false, KeyCommand.NODE_SELECT_BOTTOM );
    add_default( Key.Up,           false, true,  false, KeyCommand.NODE_SELECT_PAGE_TOP );
    add_default( Key.Down,         false, true,  false, KeyCommand.NODE_SELECT_PAGE_BOTTOM );
    add_default( Key.a,            false, false, false, KeyCommand.NODE_SELECT_PARENT );
    add_default( Key.c,            false, false, false, KeyCommand.NODE_SELECT_LAST_CHILD );
    add_default( Key.n,            false, false, false, KeyCommand.NODE_SELECT_NEXT_SIBLING );
    add_default( Key.p,            false, false, false, KeyCommand.NODE_SELECT_PREV_SIBLING );

    add_default( Key.numbersign,   false, true,  false, KeyCommand.NODE_LABEL_TOGGLE );
    add_default( Key.asterisk,     false, true,  false, KeyCommand.NODE_LABEL_CLEAR_ALL );
    add_default( Key.@1,           false, false, false, KeyCommand.NODE_LABEL_GOTO_1 );
    add_default( Key.@2,           false, false, false, KeyCommand.NODE_LABEL_GOTO_2 );
    add_default( Key.@3,           false, false, false, KeyCommand.NODE_LABEL_GOTO_3 );
    add_default( Key.@4,           false, false, false, KeyCommand.NODE_LABEL_GOTO_4 );
    add_default( Key.@5,           false, false, false, KeyCommand.NODE_LABEL_GOTO_5 );
    add_default( Key.@6,           false, false, false, KeyCommand.NODE_LABEL_GOTO_6 );
    add_default( Key.@7,           false, false, false, KeyCommand.NODE_LABEL_GOTO_7 );
    add_default( Key.@8,           false, false, false, KeyCommand.NODE_LABEL_GOTO_8 );
    add_default( Key.@9,           false, false, false, KeyCommand.NODE_LABEL_GOTO_9 );

    add_default( Key.e,            false, false, false, KeyCommand.NODE_CHANGE_TEXT );
    add_default( Key.e,            false, true,  false, KeyCommand.NODE_CHANGE_NOTE );
    add_default( Key.t,            false, false, false, KeyCommand.NODE_CHANGE_TASK );
    add_default( Key.at,           false, true,  false, KeyCommand.NODE_CHANGE_TAGS );
    add_default( Key.BackSpace,    true,  false, false, KeyCommand.NODE_JOIN );
    // add_default( Key.s,            false, false, false, KeyCommand.SHOW_SELECTED );

    /*
    add_default( Key.c,            false, true,  false, KeyCommand.NODE_CENTER );
    add_default( Key.s,            false, true,  false, KeyCommand.NODE_SORT_ALPHABETICALLY );
    add_default( Key.Up,           false, false, true,  KeyCommand.NODE_SWAP_UP );
    add_default( Key.Down,         false, false, true,  KeyCommand.NODE_SWAP_DOWN );
    */
    add_default( Key.Right,        false, false, false, KeyCommand.NODE_EXPAND_ONE );
    add_default( Key.Right,        false, true,  false, KeyCommand.NODE_EXPAND_ALL );
    add_default( Key.Left,         false, false, false, KeyCommand.NODE_COLLAPSE_ONE );
    add_default( Key.Left,         false, true,  false, KeyCommand.NODE_COLLAPSE_ALL );

  }

  private Xml.Node* make_property( string name, string value, string? translatable = null ) {
    Xml.Node* node = new Xml.Node( null, "property" );
    node->set_prop( "name", name );
    if( translatable != null ) {
      node->set_prop( "translatable", translatable );
    }
    node->set_content( value );
    return( node );
  }

  private Xml.Node* make_object( string klass, string? id = null ) {
    Xml.Node* node = new Xml.Node( null, "object" );
    node->set_prop( "class", klass );
    if( id != null ) {
      node->set_prop( "id", id );
    }
    return( node );
  }

  private Xml.Node* make_child() {
    Xml.Node* node = new Xml.Node( null, "child" );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a section for the shortcuts UI output.
  private Xml.Node* make_base_section( string name, string title, out Xml.Node* obj ) {
    Xml.Node* node = make_child();
    obj = make_object( "GtkShortcutsSection" );
    obj->add_child( make_property( "section-name", name ) );
    obj->add_child( make_property( "title", title, "yes" ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  private Xml.Node* make_section( KeyCommand command, out Xml.Node* obj ) {
    return( make_base_section( command.to_string(), command.shortcut_label(), out obj ) );
  }

  //-------------------------------------------------------------
  // Creates a group for the shortcuts UI output.
  private Xml.Node* make_base_group( string title, out Xml.Node* obj ) {
    Xml.Node* node = make_child();
    obj = make_object( "GtkShortcutsGroup" );
    obj->add_child( make_property( "title", title, "yes" ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  private Xml.Node* make_group( KeyCommand command, out Xml.Node* obj ) {
    return( make_base_group( command.shortcut_label(), out obj ) );
  }

  //-------------------------------------------------------------
  // Creates a shortcut for the shortcuts UI output.
  private Xml.Node* make_shortcut( Shortcut shortcut ) {
    Xml.Node* node = make_child();
    Xml.Node* obj  = make_object( "GtkShortcutsShortcut" );
    obj->add_child( make_property( "title", shortcut.command.shortcut_label(), "yes" ) );
    obj->add_child( make_property( "accelerator", shortcut.get_accelerator() ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a shortcut for a mouse event.
  private Xml.Node* make_mouse_shortcut( string title, string subtitle ) {
    Xml.Node* node = make_child();
    Xml.Node* obj  = make_object( "GtkShortcutsShortcut" );
    obj->add_child( make_property( "title", title, "yes" ) );
    obj->add_child( make_property( "subtitle", subtitle, "yes" ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  //-------------------------------------------------------------
  // Generates the shortcuts UI string.
  public string get_ui_string() {

    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "interface" );

    doc->set_root_element( root );

    root->set_prop( "domain", "com.github.phase1geo.minder" );

    var window = make_object( "GtkShortcutsWindow", "shortcuts" );
    root->add_child( window );

    window->add_child( make_property( "modal", "0" ) );
    window->add_child( make_property( "resizable", "0" ) );
    window->add_child( make_property( "title", "Minder Shortcuts", "yes" ) );
    window->add_child( make_property( "section-name", "global" ) );
    window->add_child( make_property( "view-name", "file" ) );

    Xml.Node* section  = null;
    Xml.Node* group    = null;
    var       commands = 0;

    for( int i=0; i<KeyCommand.NUM; i++ ) {
      var command = (KeyCommand)i;
      if( command.viewable() ) {
        if( command.is_section_start() ) {
          if( (group != null) && (commands == 0) ) {
            group->add_child( make_mouse_shortcut( _( "No Commands Listed" ), "" ) );
          }
          window->add_child( make_section( command, out section ) );
          group = null;
        } else if( command.is_group_start() ) {
          if( (group != null) && (commands == 0) ) {
            group->add_child( make_mouse_shortcut( _( "No Commands Listed" ), "" ) );
          }
          commands = 0;
          section->add_child( make_group( command, out group ) );
        } else if( !command.is_section_start() && !command.is_section_end() ) {
          var shortcut = get_shortcut( command );
          if( shortcut != null ) {
            group->add_child( make_shortcut( shortcut ) );
            commands++;
          }
        }
      }
    }

    /*
    // We will need to manually add the mouse events
    window->add_child( make_base_section( "mouse", _( "Mouse Events" ), out section ) );

    section->add_child( make_base_group( _( "General" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Show Contextual Menu" ), _( "[Right-click when item is selected]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Edit Image" ), _( "[Double left-click image]" ) ) );

    section->add_child( make_base_group( _( "Canvas Movement" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Pan Canvas" ), _( "[Middle-click + Drag / Alt + Motion]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Scroll Vertically" ), _( "[Scrollwheel up/down]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Scroll Horizontally" ), _( "[Scrollwhile left/right]" ) ) );

    section->add_child( make_base_group( _( "Item Selection" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Select Single Item" ), _( "[Left-click on item]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select Child Nodes" ), _( "[Control + Left-click on parent node]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select Node Tree/Subtree" ), _( "[Control + Double left-click on parent node" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select All Nodes at Same Depth Level" ), _( "[Control + Triple left-click on node]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Block Selection" ), _( "[Left-click + Drag]" ) ) );

    section->add_child( make_base_group( _( "Item Selection Toggle" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of Item" ), _( "[Shift + Left-click on item]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of Child Nodes" ), _( "[Shift + Control + Left-click on item]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of Node Tree/Subtree" ), _( "[Shift + Control + Double left-click on parent node]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of All Nodes at Same Depth Level" ), _( "Shift + Control + Triple-click on node]" ) ) );

    section->add_child( make_base_group( _( "Text Selection" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Set Cursor Insert Point" ), _( "[Left-click in text]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select Current Word" ), _( "[Double left-click on word]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select all text" ), _( "[Triple left-click text]" ) ) );
    */

    var dump_str = "";
    doc->dump_memory_format( out dump_str );
    delete doc;

    return( dump_str );

  }

}
