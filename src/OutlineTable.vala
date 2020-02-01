/*
* Copyright (c) 2018 (https://github.com/phase1geo/Outliner)
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

public class OutlineTable : DrawingArea {

  private MainWindow      _win;
  private Document        _doc;
  private Node?           _selected = null;
  private Node?           _active   = null;
  private double          _press_x;
  private double          _press_y;
  private bool            _pressed    = false;
  private EventType       _press_type = EventType.NOTHING;
  private bool            _motion     = false;
  private Theme           _theme;
  private IMContextSimple _im_context;
  private double          _scroll_adjust = -1;
  private string?         _hilite_color  = null;
  private string?         _font_color    = null;
  private FormatBar?      _format_bar    = null;
  private bool?           _show_format   = null;
  private CanvasText      _orig_text;
  private Node?           _move_parent   = null;
  private int             _move_index    = -1;
  private NodeMenu        _node_menu;
  private bool            _condensed     = false;
  private bool            _debug         = true;

  public MainWindow     win         { get { return( _win ); } }
  public Document       document    { get { return( _doc ); } }
  public UndoBuffer     undo_buffer { get; set; }
  public UndoTextBuffer undo_text   { get; set; }
  public Node?          selected {
    get {
      return( _selected );
    }
    set {
      if( _selected != value ) {
        if( _selected != null ) {
          set_selected_mode( NodeMode.NONE );
          _selected.select_mode.disconnect( select_mode_changed );
          _selected.cursor_changed.disconnect( selected_cursor_changed );
        }
        if( value != null ) {
          see( value );
        }
        _selected = value;
        if( _selected != null ) {
          set_selected_mode( NodeMode.SELECTED );
          _selected.select_mode.connect( select_mode_changed );
          _selected.cursor_changed.connect( selected_cursor_changed );
        }
        selected_changed();
      }
    }
  }
  public Node root { private set; get; }
  public string? hilite_color {
    get {
      return( _hilite_color );
    }
    set {
      _hilite_color = value;
      update_css();
    }
  }
  public string? font_color {
    get {
      return( _font_color );
    }
    set {
      _font_color = value;
      update_css();
    }
  }
  public Clipboard node_clipboard { set; get; default = Clipboard.get_for_display( Display.get_default(), Atom.intern( "org.github.phase1geo.outliner", false ) );}
  public bool condensed {
    get {
      return( _condensed );
    }
    set {
      if( _condensed != value ) {
        _condensed = value;
        root.set_condensed( value );
        queue_draw();
      }
    }
  }

  /* Called by this class when a change is made to the table */
  public signal void changed();
  public signal void zoom_changed( int name_size, int note_size, int pady );
  public signal void theme_changed( Theme theme );
  public signal void selected_changed();
  public signal void cursor_changed();

  /* Default constructor */
  public OutlineTable( MainWindow win, GLib.Settings settings ) {

    _win = win;

    /* Create the document for this table */
    _doc = new Document( this, settings );

    /* Create the root node */
    root = new Node.root();

    /* Create contextual menu(s) */
    _node_menu = new NodeMenu( this );

    /* Set the default theme */
    var init_theme = MainWindow.themes.get_theme( "solarized_dark" );
    _hilite_color = Utils.color_from_rgba( init_theme.hilite );
    set_theme( init_theme );

    /* Allocate memory for the canvas text prior to editing for undo purposes */
    _orig_text = new CanvasText( this, 0 );

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );
    undo_text   = new UndoTextBuffer( this );

    /* Set the style context */
    get_style_context().add_class( "canvas" );

    /* Add event listeners */
    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.motion_notify_event.connect( on_motion );
    this.button_release_event.connect( on_release );
    this.key_press_event.connect( on_keypress );
    // TBD - this.scroll_event.connect( on_scroll );
    this.size_allocate.connect( (a) => {
      see_internal();
    });

    /* Make sure the above events are listened for */
    this.add_events(
      EventMask.BUTTON_PRESS_MASK |
      EventMask.BUTTON_RELEASE_MASK |
      EventMask.BUTTON1_MOTION_MASK |
      EventMask.POINTER_MOTION_MASK |
      EventMask.KEY_PRESS_MASK |
      EventMask.SMOOTH_SCROLL_MASK |
      EventMask.STRUCTURE_MASK
    );

    /* Make sure the drawing area can receive keyboard focus */
    this.can_focus = true;

    /* Make sure that we us the ImContextSimple input method */
    _im_context = new IMContextSimple();
    _im_context.commit.connect( handle_printable );

  }

  /* Called whenever the selection mode changed of the current node */
  private void select_mode_changed( bool name, bool mode ) {
    _show_format = mode;
  }

  /* Called whenever the cursor changes position in the current node */
  private void selected_cursor_changed( bool name ) {
    cursor_changed();
  }

  /* Sets the cursor of the drawing area */
  private void set_cursor( CursorType? type = null ) {

    var     win    = get_window();
    Cursor? cursor = win.get_cursor();

    if( type == null ) {
      win.set_cursor( null );
    } else if( (cursor == null) || (cursor.cursor_type != type) ) {
      win.set_cursor( new Cursor.for_display( get_display(), type ) );
    }

  }

  /* Called whenever we want to change the current selected node's mode */
  private void set_selected_mode( NodeMode mode ) {
    if( selected == null ) return;
    if( selected.mode != mode ) {
      if( (selected.mode == NodeMode.EDITABLE) && undo_text.undoable() ) {
        undo_buffer.add_item( new UndoNodeName( this, selected, _orig_text ) );
        undo_text.clear();
        undo_text.ct = null;
      } else if( (selected.mode == NodeMode.NOTEEDIT) && undo_text.undoable() ) {
        undo_buffer.add_item( new UndoNodeNote( this, selected, _orig_text ) );
        undo_text.clear();
        undo_text.ct = null;
      }
      if( mode == NodeMode.EDITABLE ) {
        _orig_text.copy( selected.name );
        undo_text.ct = selected.name;
      } else if( mode == NodeMode.NOTEEDIT ) {
        _orig_text.copy( selected.note );
        undo_text.ct = selected.note;
      }
      selected.mode = mode;
    }
  }

  /* Make sure that the given node is fully in view */
  public void see( Node node ) {
    if( root.children.length == 0 ) return;
    var vp = parent.parent as Viewport;
    var vh = vp.get_allocated_height();
    var sw = parent.parent.parent as ScrolledWindow;
    var y1 = sw.vadjustment.value;
    var y2 = y1 + vh;
    if( node.y < y1 ) {
      _scroll_adjust = node.y;
    } else if( node.last_y > y2 ) {
      _scroll_adjust = node.last_y - vh;
    }
    if( node.last_y <= get_allocated_height() ) {
      see_internal();
    }
  }

  /* Internal see command that is called after this has been resized */
  private void see_internal() {
    if( _scroll_adjust == -1 ) return;
    var sw = parent.parent.parent as ScrolledWindow;
    sw.vadjustment.value = _scroll_adjust;
    _scroll_adjust = -1;
  }

  /* Returns true if the currently selected node is editable */
  public bool is_node_editable() {
    return( (selected != null) && (selected.mode == NodeMode.EDITABLE) );
  }

  /* Returns true if the currently selected note is editable */
  public bool is_note_editable() {
    return( (selected != null) && (selected.mode == NodeMode.NOTEEDIT) );
  }

  /* Returns true if the currently selected node is editable and has text selected */
  private bool is_node_text_selected() {
    return( is_node_editable() && selected.name.is_selected() );
  }

  /* Returns true if the currently selected note is editable and has text selected */
  private bool is_note_text_selected() {
    return( is_note_editable() && selected.note.is_selected() );
  }

  /* Returns the node at the given coordinates */
  private Node? node_at_coordinates( double x, double y ) {
    return( root.get_containing_node( x, y ) );
  }

  /* Called when the given coordinates are clicked within a CanvasText item. */
  private bool clicked_in_text( Node clicked, CanvasText text, EventButton e, NodeMode select_mode ) {

    bool   shift   = (bool)(e.state & ModifierType.SHIFT_MASK);
    bool   control = (bool)(e.state & ModifierType.CONTROL_MASK);
    string url     = "";

    /* Set the selected node to the clicked node */
    selected = clicked;

    /*
     If the mouse click was within a URL and the control key was pressed, open
     the URL in an external application.
    */
    if( control && text.is_within_url( e.x, e.y, ref url ) ) {
      _active = clicked;
      Utils.open_url( url );
      return( false );
    }

    /* Set the cursor or selection */
    switch( e.type ) {
      case EventType.BUTTON_PRESS        :  text.set_cursor_at_char( e.x, e.y, shift );  break;
      case EventType.DOUBLE_BUTTON_PRESS :  text.set_cursor_at_word( e.x, e.y, shift );  break;
      case EventType.TRIPLE_BUTTON_PRESS :  text.set_cursor_all( false );                break;
    }

    /* Sets the selected mode */
    set_selected_mode( select_mode );

    return( true );

  }

  /* Selects the node at the given coordinates */
  private bool set_current_at_position( double x, double y, EventButton e ) {

    var clicked = node_at_coordinates( x, y );;

    _active = null;

    if( clicked != null ) {
      if( clicked.is_within_expander( x, y ) ) {
        _active = clicked;
        return( false );
      } else if( clicked.is_within_note_icon( x, y ) ) {
        _active = clicked;
        return( false );
      } else if( clicked.is_within_name( x, y ) ) {
        return( clicked_in_text( clicked, clicked.name, e, NodeMode.EDITABLE ) );
      } else if( clicked.is_within_note( x, y ) ) {
        return( clicked_in_text( clicked, clicked.note, e, NodeMode.NOTEEDIT ) );
      } else {
        _active = clicked;
      }
    } else {
      selected = null;
    }

    return( true );

  }

  /* Changes the text selection for the specified canvas text element */
  private void change_selection( CanvasText ct, double x, double y ) {
    switch( _press_type ) {
      case EventType.BUTTON_PRESS        :  ct.set_cursor_at_char( x, y, true );  break;
      case EventType.DOUBLE_BUTTON_PRESS :  ct.set_cursor_at_word( x, y, true );  break;
    }
    queue_draw();
  }

  /* Handle button press event */
  private bool on_press( EventButton e ) {

    switch( e.button ) {
      case Gdk.BUTTON_PRIMARY :
        grab_focus();
        _press_x    = e.x;
        _press_y    = e.y;
        _pressed    = set_current_at_position( _press_x, _press_y, e );
        _press_type = e.type;
        _motion     = false;
        queue_draw();
        break;
      case Gdk.BUTTON_SECONDARY :
        show_contextual_menu( e );
        break;
    }

    /* Update the format bar display */
    update_format_bar();

    return( false );

  }

  /* Handle mouse motion */
  private bool on_motion( EventMotion e ) {

    _motion = true;

    if( _pressed ) {

      if( selected != null ) {

        /* If we are dragging out a text selection, handle it here */
        if( (selected.mode == NodeMode.EDITABLE) || (selected.mode == NodeMode.NOTEEDIT) ) {
          change_selection( ((selected.mode == NodeMode.EDITABLE) ? selected.name : selected.note), e.x, e.y );

        /* Otherwise, we are moving the current node */
        } else {
          if( selected.mode == NodeMode.SELECTED ) {
            _move_parent = selected.parent;
            _move_index  = selected.index();
            selected.mode = NodeMode.MOVETO;
            selected.parent.remove_child( selected );
          }
          selected.x = e.x;
          selected.y = e.y;
          var current = node_at_coordinates( e.x, e.y );
          if( current != null ) {
            if( current.is_within_attachto( e.x, e.y ) ) {
              current.mode = NodeMode.ATTACHTO;
            } else if( current.is_within_attachabove( e.x, e.y ) ) {
              current.mode = NodeMode.ATTACHABOVE;
            } else {
              current.mode = NodeMode.ATTACHBELOW;
            }
            if( current != _active ) {
              if( _active != null ) {
                _active.mode = NodeMode.NONE;
              }
              _active = current;
            }
          }
          queue_draw();
        }
      }

    } else {

      /* Get the current node */
      var current = node_at_coordinates( e.x, e.y );

      /* Check the location of the cursor and update the UI appropriately */
      if( current != null ) {
        var orig_over = current.over_note_icon;
        current.over_note_icon = false;
        set_tooltip_markup( null );
        if( current.is_within_note_icon( e.x, e.y ) ) {
          current.over_note_icon = true;
          set_tooltip_markup( current.hide_note ? _( "Show note" ) : _( "Hide note" ) );
          set_cursor( null );
        } else if( current.is_within_name( e.x, e.y ) ) {
          set_cursor( CursorType.XTERM );
        } else if( current.is_within_note( e.x, e.y ) ) {
          set_cursor( CursorType.XTERM );
        } else {
          set_cursor( null );
        }
        if( orig_over != current.over_note_icon ) {
          queue_draw();
        }
      } else {
        set_cursor( null );
      }

      /* If the current node is not the active node, set the mode to HOVER */
      if( current != _active ) {
        if( (_active != null) && (_active != selected) ) {
          _active.over_note_icon = false;
          _active.mode           = NodeMode.NONE;
        }
        if( (current != null) && (current != selected) ) {
          current.mode = NodeMode.HOVER;
          _active      = current;
        }
        queue_draw();
      }

    }

    return( false );

  }

  /* Handles the release of the mouse button */
  private bool on_release( EventButton e ) {

    if( _pressed ) {

      if( _active != null ) {

        /* Handle a node move */
        if( _motion ) {
          switch( _active.mode ) {
            case NodeMode.ATTACHTO :
              _active.add_child( selected );
              undo_buffer.add_item( new UndoNodeMove( selected, _move_parent, _move_index ) );
              break;
            case NodeMode.ATTACHABOVE :
              _active.parent.add_child( selected, _active.index() );
              undo_buffer.add_item( new UndoNodeMove( selected, _move_parent, _move_index ) );
              break;
            case NodeMode.ATTACHBELOW :
              _active.parent.add_child( selected, (_active.index() + 1) );
              undo_buffer.add_item( new UndoNodeMove( selected, _move_parent, _move_index ) );
              break;
          }
          if( selected == null ) {
            selected = _active;
          }
          set_selected_mode( NodeMode.SELECTED );
          _active.mode  = NodeMode.NONE;
          _active       = null;
          queue_draw();
          changed();
        } else {
          selected = _active;
          queue_draw();
        }
      }

    } else {

      /* If the user clicked in an expander, toggle the expander */
      if( !_motion ) {
        if( _active.is_within_expander( e.x, e.y ) ) {
          toggle_expand( _active );
        } else if( _active.is_within_note_icon( e.x, e.y ) ) {
          var control = (bool)(e.state & ModifierType.CONTROL_MASK);
          if( control ) {
            toggle_notes( _active );
          } else {
            toggle_note( _active, true );
          }
        }
      }

    }

    /* Update the format bar state */
    update_format_bar();

    _pressed = false;

    return( false );

  }

  /* Handles keypress events */
  private bool on_keypress( EventKey e ) {

    /* Figure out which modifiers were used */
    var control = (bool)(e.state & ModifierType.CONTROL_MASK);
    var shift   = (bool)(e.state & ModifierType.SHIFT_MASK);
    var nomod   = !(control || shift);

    /* If there is a current node or connection selected, operate on it */
    if( selected != null ) {
      if( control ) {
        switch( e.keyval ) {
          case 99    :  do_copy();                      break;
          case 120   :  do_cut();                       break;
          case 118   :  do_paste( false );              break;
          case 86    :  do_paste( true );               break;
          case 65293 :  handle_control_return();        break;
          case 65289 :  handle_control_tab();           break;
          case 65363 :  handle_control_right( shift );  break;
          case 65361 :  handle_control_left( shift );   break;
          case 65362 :  handle_control_up( shift );     break;
          case 65364 :  handle_control_down( shift );   break;
          case 47    :  handle_control_slash();         break;
          case 92    :  handle_control_backslash();     break;
          case 46    :  handle_control_period();        break;
          case 98    :  handle_control_b();             break;
          case 100   :  handle_control_d();             break;
          case 117   :  handle_control_u();             break;
          case 104   :  handle_control_h();             break;
          case 105   :  handle_control_i();             break;
          case 116   :  handle_control_t();             break;
        }
      } else if( nomod || shift ) {
        if( _im_context.filter_keypress( e ) ) {
          return( true );
        }
        switch( e.keyval ) {
          case 65288 :  handle_backspace();         break;
          case 65535 :  handle_delete();            break;
          case 65307 :  handle_escape();            break;
          case 65293 :  handle_return( shift );     break;
          case 65289 :  handle_tab();               break;
          case 65056 :  handle_shift_tab();         break;
          case 65363 :  handle_right( shift );      break;
          case 65361 :  handle_left( shift );       break;
          case 65360 :  handle_home();              break;
          case 65367 :  handle_end();               break;
          case 65362 :  handle_up( shift );         break;
          case 65364 :  handle_down( shift );       break;
          case 65365 :  handle_pageup();            break;
          case 65366 :  handle_pagedn();            break;
          default    :  handle_printable( e.str );  break;
        }
      }
    }

    /* Update the format bar state, if necessary */
    update_format_bar();

    return( true );

  }

  /* Displays the contextual menu based on what is currently selected */
  private void show_contextual_menu( EventButton event ) {

#if GTK322
    if( (selected != null) && (selected.mode == NodeMode.SELECTED) ) {
      _node_menu.popup_at_pointer( event );
    }
#else
    if( (selected != null) && (selected.mode == NodeMode.SELECTED) ) {
      _node_menu.popup( null, null, null, event.button, event.time );
    }
#endif

  }

  /* Expands or collapses the current node's children */
  public void toggle_expand( Node node ) {
    node.expanded = !node.expanded;
    undo_buffer.add_item( new UndoNodeExpander( node ) );
    queue_draw();
    changed();
  }

  /* Shows or hides all notes within the given node's tree */
  public void toggle_notes( Node node ) {
    node.set_notes_display( node.hide_note );
    node.adjust_nodes( node.last_y, true );
    see( node );
    queue_draw();
    changed();
  }

  /* Shows or hides the note field associated with the given node's tree */
  public void toggle_note( Node node, bool edit ) {
    node.hide_note = !node.hide_note;
    if( node.note.text.text == "" ) {
      selected = node;
      set_selected_mode( (node.hide_note || !edit) ? NodeMode.SELECTED : NodeMode.NOTEEDIT );
    }
    queue_draw();
    changed();
  }

  /* Creates a serialized version of the node for copy */
  public string serialize_for_copy( Node node ) {
    string    str;
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "outliner" );
    doc->set_root_element( root );
    root->add_child( node.save() );
    doc->dump_memory( out str );
    delete doc;
    return( str );
  }

  /* Takes an XML string as input and populates the passed node with its contents */
  public void deserialize_for_paste( string str, Node node ) {
    Xml.Doc* doc = Xml.Parser.parse_doc( str );
    if( doc == null ) return;
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        node.load( this, it );
      }
    }
    delete doc;
  }

  /* Copies the given node to the designated node clipboard */
  public void copy_node_to_clipboard( Node node ) {
    var text = serialize_for_copy( node );
    node_clipboard.set_text( text, -1 );
    node_clipboard.store();
  }

  /*
   Copies the selected text to the clipboard.  TBD - This will not include
   text formatting at this point.
  */
  private void copy_selected_text( CanvasText ct ) {
    var text = ct.get_selected_text();
    if( text != null ) {
      var clipboard = Clipboard.get_default( get_display() );
      clipboard.set_text( text, -1 );
    }
  }

  /* Handles a copy operation on a node or selected text */
  public void do_copy() {
    if( selected == null ) return;
    switch( selected.mode ) {
      case NodeMode.SELECTED :  copy_node_to_clipboard( selected );   break;
      case NodeMode.EDITABLE :  copy_selected_text( selected.name );  break;
      case NodeMode.NOTEEDIT :  copy_selected_text( selected.note );  break;
    }
  }

  /* Copies the given node to the clipboard and then removes it from the document */
  public void cut_node_to_clipboard( Node node ) {
    var text = serialize_for_copy( node );
    node_clipboard.set_text( text, -1 );
    node_clipboard.store();
    undo_buffer.add_item( new UndoNodeCut( node ) );
    delete_node( node );
  }

  /*
   Copies the currently selected text to the clipboard and then removes
   it from the given CanvasText object.
  */
  private void cut_selected_text( CanvasText ct ) {
    copy_selected_text( ct );
    ct.backspace( undo_text );
    queue_draw();
  }

  /* Handles a cut operation on a node or selected text */
  public void do_cut() {
    if( selected == null ) return;
    switch( selected.mode ) {
      case NodeMode.SELECTED :  cut_node_to_clipboard( selected );   break;
      case NodeMode.EDITABLE :  cut_selected_text( selected.name );  break;
      case NodeMode.NOTEEDIT :  cut_selected_text( selected.note );  break;
    }
  }

  /*
   Pastes the given node into the table after the currently selected node as
   a sibling node.
  */
  public void paste_node( bool below ) {

    /* Create the new node from the clipboard */
    var node = new Node( this );
    var text = node_clipboard.wait_for_text();
    deserialize_for_paste( text, node );

    /* Insert the node into the appropriate position in the table */
    if( below ) {
      if( selected.children.length > 0 ) {
        insert_node( selected, node, 0 );
      } else {
        insert_node( selected.parent, node, (selected.index() + 1) );
      }
    } else {
      insert_node( selected.parent, node, selected.index() );
    }

    /* Add an undo item for this operation */
    undo_buffer.add_item( new UndoNodePaste( node ) );

    queue_draw();
    changed();
    see( node );

  }

  /* Pastes the text into the provided CanvasText */
  private void paste_text( CanvasText ct ) {
    var clipboard = Clipboard.get_default( get_display() );
    var text      = clipboard.wait_for_text();
    if( text != null ) {
      ct.insert( text, undo_text );
      queue_draw();
      changed();
    }
  }

  /* Handles a paste operation of a node or text to the table */
  public void do_paste( bool shift ) {
    if( selected == null ) return;
    switch( selected.mode ) {
      case NodeMode.SELECTED :  paste_node( !shift );         break;
      case NodeMode.EDITABLE :  paste_text( selected.name );  break;
      case NodeMode.NOTEEDIT :  paste_text( selected.note );  break;
    }
  }

  /* Handles a backspace keypress */
  private void handle_backspace() {
    if( is_node_editable() ) {
      if( selected.name.text.text == "" ) {
        var prev = selected.get_previous_node();
        if( prev != null ) {
          delete_current_node();
          selected = prev;
          set_selected_mode( NodeMode.EDITABLE );
          selected.name.move_cursor_to_end();
        }
      } else {
        selected.name.backspace( undo_text );
        queue_draw();
      }
    } else if( is_note_editable() ) {
      selected.note.backspace( undo_text );
      queue_draw();
    } else if( selected != null ) {
      delete_current_node();
    }
  }

  /* Handles a delete keypress */
  private void handle_delete() {
    if( is_node_editable() ) {
      selected.name.delete( undo_text );
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.delete( undo_text );
      queue_draw();
    } else if( selected != null ) {
      delete_current_node();
    }
  }

  /* Handles an escape keypress */
  private void handle_escape() {
    if( is_node_editable() || is_note_editable() ) {
      set_selected_mode( NodeMode.SELECTED );
      queue_draw();
      changed();
    }
  }

  /* Handles a return keypress */
  private void handle_return( bool shift ) {
    if( is_note_editable() ) {
      selected.note.insert( "\n", undo_text );
      queue_draw();
      see( selected );
    } else if( is_node_editable() && shift ) {
      selected.name.insert( "\n", undo_text );
      queue_draw();
      see( selected );
    } else if( selected != null ) {
      add_sibling_node( !shift );
    }
  }

  /* Handles a Control-Return keypress */
  private void handle_control_return() {
    if( is_node_editable() ) {
      string name   = selected.name.text.text;
      int    curpos = selected.name.cursor;
      selected.name.text.remove_text( curpos, (selected.name.text.text.length - curpos ) );
      add_sibling_node( true, name.substring( curpos ) );
    } else if( is_note_editable() ) {
      selected.note.insert( "\n", undo_text );
      queue_draw();
    }
  }

  /* Handles a tab key hit when a node is selected */
  private void handle_tab() {
    if( selected != null ) {
      indent();
    }
  }

  /* Handles a shift tab keypress when a node is selected */
  private void handle_shift_tab() {
    if( is_note_editable() ) {
      selected.note.insert( "\t", undo_text );
      queue_draw();
    } else if( selected != null ) {
      unindent();
    }
  }

  /* Handles a Control-Tab keypress */
  private void handle_control_tab() {
    if( is_node_editable() ) {
      selected.name.insert( "\t", undo_text );
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.insert( "\t", undo_text );
      queue_draw();
    }
  }

  /* Handles a right arrow keypress */
  private void handle_right( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_char( 1 );
      } else {
        selected.name.move_cursor( 1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_char( 1 );
      } else {
        selected.note.move_cursor( 1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( selected != null ) {
      if( !selected.is_leaf() && !selected.expanded ) {
        selected.expanded = true;
        undo_buffer.add_item( new UndoNodeExpander( selected ) );
        queue_draw();
        changed();
      }
    }
  }

  /* Handles a Control-Right arrow keypress */
  private void handle_control_right( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_word( 1 );
      } else {
        selected.name.move_cursor_by_word( 1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_word( 1 );
      } else {
        selected.note.move_cursor_by_word( 1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  /* Handles a left arrow keypress */
  private void handle_left( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_char( -1 );
      } else {
        selected.name.move_cursor( -1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_char( -1 );
      } else {
        selected.note.move_cursor( -1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( selected != null ) {
      if( !selected.is_leaf() && selected.expanded ) {
        selected.expanded = false;
        undo_buffer.add_item( new UndoNodeExpander( selected ) );
        queue_draw();
        changed();
      }
    }
  }

  /* Handles a Control-left arrow keypress */
  private void handle_control_left( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_word( -1 );
      } else {
        selected.name.move_cursor_by_word( -1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_word( -1 );
      } else {
        selected.note.move_cursor_by_word( -1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  /* Handles an up arrow keypress */
  private void handle_up( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_vertically( -1 );
      } else {
        selected.name.move_cursor_vertically( -1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_vertically( -1 );
      } else {
        selected.note.move_cursor_vertically( -1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( selected != null ) {
      var node = selected.get_previous_node();
      if( node != null ) {
        selected = node;
        queue_draw();
      }
    }
  }

  /* Handles a Control-Up arrow keypress */
  private void handle_control_up( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_start();
      } else {
        selected.name.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_start();
      } else {
        selected.note.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  /* Handles down arrow keypress */
  private void handle_down( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_vertically( 1 );
      } else {
        selected.name.move_cursor_vertically( 1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_vertically( 1 );
      } else {
        selected.note.move_cursor_vertically( 1 );
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( selected != null ) {
      var node = selected.get_next_node();
      if( node != null ) {
        selected = node;
        queue_draw();
      }
    }
  }

  /* Handles Control-Down arrow keypress */
  private void handle_control_down( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_end();
      } else {
        selected.name.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_end();
      } else {
        selected.note.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  /* Handles a Control-slash keypress */
  private void handle_control_slash() {
    if( is_node_editable() ) {
      selected.name.set_cursor_all( false );
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.set_cursor_all( false );
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  /* Handles a Control-backslash keypress */
  private void handle_control_backslash() {
    if( is_node_editable() ) {
      selected.name.clear_selection();
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.clear_selection();
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  /* Called whenever the period key is entered with the control key */
  private void handle_control_period() {
    if( is_node_editable() ) {
      insert_emoji( selected.name );
    } else if( is_note_editable() ) {
      insert_emoji( selected.note );
    }
  }

  /* Causes selected text to be bolded */
  private void handle_control_b() {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.BOLD, null, undo_text );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.BOLD, null, undo_text );
      queue_draw();
    }
  }

  /* This is just used from debugging purposes */
  private void handle_control_d() {
    if( !_debug ) return;
    if( selected == null ) {
      stdout.printf( "Nothing is selected\n" );
    } else {
      stdout.printf( "HTMLized text: %s\n", selected.name.text.htmlize() );
    }
  }

  /* Toggles the show all notes status given the state of the currently selected node */
  private void handle_control_h() {
    set_notes_display( (selected == null) ? root.children.index( 0 ).hide_note : selected.hide_note );
  }

  /* Causes selected text to be italicized */
  private void handle_control_i() {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.ITALICS, null, undo_text );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.ITALICS, null, undo_text );
      queue_draw();
    }
  }

  /* Causes selected text to be underlined */
  private void handle_control_u() {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.UNDERLINE, null, undo_text );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.UNDERLINE, null, undo_text );
      queue_draw();
    }
  }

  /* Causes selected text to be striken */
  private void handle_control_t() {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.STRIKETHRU, null, undo_text );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.STRIKETHRU, null, undo_text );
      queue_draw();
    }
  }

  /* Handles a Home keypress */
  private void handle_home() {
    if( is_node_editable() ) {
      selected.name.move_cursor_to_start();
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.move_cursor_to_start();
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  /* Handles an End keypress */
  private void handle_end() {
    if( is_node_editable() ) {
      selected.name.move_cursor_to_end();
      undo_text.mergeable = false;
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.move_cursor_to_end();
      undo_text.mergeable = false;
      queue_draw();
    }
  }

  private void handle_pageup() {
    if( selected != null ) {
      /* TBD */
    }
  }

  private void handle_pagedn() {
    if( selected != null ) {
      /* TBD */
    }
  }

  /* Handles any printable characters */
  private void handle_printable( string str ) {
    if( !str.get_char( 0 ).isprint() ) return;
    if( is_node_editable() ) {
      selected.name.insert( str, undo_text );
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.insert( str, undo_text );
      queue_draw();
    } else if( selected != null ) {
      switch( str ) {
        case "e" :  edit_selected( true );  break;
        case "E" :  edit_selected( false );  break;
        case "m" :  change_selected( selected.get_root_node() );  break;
        case "j" :  change_selected( selected.get_next_node() );  break;
        case "h" :  unindent();  break;
        case "k" :  change_selected( selected.get_previous_node() );  break;
        case "l" :  indent();  break;
        case "a" :  change_selected( selected.parent );  break;
      }
    }
  }

  /* Edit the selected node */
  public void edit_selected( bool title ) {
    if( selected == null ) return;
    if( title ) {
      set_selected_mode( NodeMode.EDITABLE );
    } else {
      set_selected_mode( NodeMode.NOTEEDIT );
      selected.hide_note = false;
    }
    queue_draw();
  }

  /* Change the selected node to the given node */
  private void change_selected( Node? node ) {
    if( node == null ) return;
    selected = node;
    queue_draw();
    see( selected );
  }

  /*************************/
  /* MISCELLANEOUS METHODS */
  /*************************/

  /* Handles the emoji insertion process for the given text item */
  private void insert_emoji( CanvasText text ) {
    var overlay = (Overlay)get_parent();
    var entry = new Entry();
    int x, ytop, ybot;
    text.get_cursor_pos( out x, out ytop, out ybot );
    entry.margin_start = x;
    entry.margin_top   = ytop + ((ybot - ytop) / 2);
    entry.changed.connect(() => {
      text.insert( entry.text, undo_text );
      entry.unparent();
      grab_focus();
      queue_draw();
    });
    overlay.add_overlay( entry );
    entry.insert_emoji();
  }

  /* Returns the currently applied heme */
  public Theme get_theme() {

    return( _theme );

  }

  private void update_css() {

    StyleContext.add_provider_for_screen(
      Screen.get_default(),
      _theme.get_css_provider( _hilite_color, _font_color ),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );

  }

  /* Sets the theme to the given value */
  public void set_theme( Theme theme, bool save = true ) {

    _theme = theme;

    /* Update the CSS */
    update_css();

    /* Change the theme of the formatted text */
    FormattedText.set_theme( theme );

    /* Indicate that the theme has changed to anyone listening */
    theme_changed( theme );

    /* Update all nodes */
    queue_draw();

    if( save ) {
      changed();
    }

  }

  /* Creates a new, unnamed document */
  public void initialize_for_new() {

    /* Initialize variables */
    _press_type = EventType.NOTHING;

    /* Create the main idea node */
    var node = new Node( this );
    insert_node( root, node, 0 );
    set_selected_mode( NodeMode.EDITABLE );

    queue_draw();

  }

  /*
   If the format bar needs to be created, create it.  Place it at the current
   cursor position and make sure that it is visible.
  */
  private void show_format_bar() {

    /* If the format bar is currently displayed, just reposition it */
    if( _format_bar == null ) {
      _format_bar = new FormatBar( this );
    }

    int selstart, selend, cursor;
    var text = (selected.mode == NodeMode.EDITABLE) ? selected.name : selected.note;

    text.get_cursor_info( out cursor, out selstart, out selend );

    /* Position the popover */
    double left, top;
    text.get_char_pos( cursor, out left, out top );
    Gdk.Rectangle rect = {(int)left, (int)top, 1, 1};
    _format_bar.pointing_to = rect;

#if GTK322
    _format_bar.popup();
#else
    _format_bar.show();
#endif

  }

  /* Hides the format bar if it is currently visible and destroys it */
  private void hide_format_bar() {

    if( _format_bar != null ) {

#if GTK322
      _format_bar.popdown();
#else
      _format_bar.hide();
#endif

      _format_bar = null;

    }

  }

  /* Shows/Hides the formatting toolbar */
  private void update_format_bar() {

    /* If we have nothing to do, just return */
    if( _show_format == null ) return;

    /* Update the format bar */
    if( _show_format ) {
      show_format_bar();
    } else {
      hide_format_bar();
    }

    /* Clear the show format indicator */
    _show_format = null;

  }

  /***************************/
  /* FILE LOAD/STORE METHODS */
  /***************************/

  /* Loads the table information from the given XML node */
  public void load( Xml.Node* n ) {

    string? c = n->get_prop( "condensed" );
    if( c != null ) {
      _condensed = bool.parse( c );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "theme" :  load_theme( it );  break;
          case "nodes" :  load_nodes( it );  break;
        }
      }
    }

    queue_draw();

  }

  /* Loads the given theme from XML format */
  private void load_theme( Xml.Node* n ) {

    string? name = n->get_prop( "name" );
    if( name != null ) {
      set_theme( MainWindow.themes.get_theme( name ), false );
    }

  }

  /* Loads all of the nodes from the outliner XML document */
  private void load_nodes( Xml.Node* n ) {

    var i = 0;

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        var node = new Node( this );
        node.load( this, it );
        root.add_child( node, i++ );
      }
    }

  }

  /* Saves the table information to the given XML node */
  public void save( Xml.Node* n ) {

    n->set_prop( "condensed", _condensed.to_string() );

    n->add_child( save_theme() );
    n->add_child( save_nodes() );

  }

  /* Saves the theme information in XML format */
  private Xml.Node* save_theme() {

    Xml.Node* theme = new Xml.Node( null, "theme" );

    theme->new_prop( "name", _theme.name );

    return( theme );

  }

  /* Saves the nodes in XML format and returns the <nodes> node */
  private Xml.Node* save_nodes() {

    Xml.Node* n = new Xml.Node( null, "nodes" );

    for( int i=0; i<root.children.length; i++ ) {
      n->add_child( root.children.index( i ).save() );
    }

    return( n );

  }

  /**************************/
  /* SEARCH-RELATED METHODS */
  /**************************/

  /* Perform a depth-first search for the given search pattern */
  public void do_search( string pattern ) {
    root.do_search( pattern );
    queue_draw();
  }

  /* Replaces the current match */
  public void replace_current( string replace ) {
    if( is_node_editable() ) {
      selected.name.insert( replace, undo_text );
      queue_draw();
      changed();
    } else if( is_note_editable() ) {
      selected.note.insert( replace, undo_text );
      queue_draw();
      changed();
    }
  }

  /* Replaces all matched text within the document with the given string */
  public void replace_all( string search, string replace ) {
    var undo = new UndoReplaceAll( search, replace );
    root.replace_all( replace, ref undo );
    undo_buffer.add_item( undo );
    queue_draw();
    changed();
  }

  /************************/
  /* TREE-RELATED METHODS */
  /************************/

  /* Creates a new node that is ready to be edited */
  private Node create_node( string? title = null ) {

    var node = new Node( this );

    if( title != null ) {
      node.name.text.set_text( title );
    }

    return( node );

  }

  /* Inserts the given node into the given parent at the specified index */
  public void insert_node( Node parent, Node node, int index ) {
    parent.add_child( node, index );
    selected = node;
    queue_draw();
    changed();
    see( node );
  }

  /* Adds a sibling node of the currently selected node */
  public void add_sibling_node( bool below, string? title = null ) {
    if( (selected == null) || selected.is_root() ) return;
    var index = selected.index() + (below ? 1 : 0);
    var sel   = selected;
    var node  = create_node( title );
    insert_node( sel.parent, node, index );
    set_selected_mode( NodeMode.EDITABLE );
    undo_buffer.add_item( new UndoNodeInsert( node ) );
  }

  /* Adds a child node of the currently selected node */
  public void add_child_node() {
    if( selected == null ) return;
    var index = selected.children.length;
    var sel   = selected;
    var node  = create_node();
    insert_node( sel, node, (int)index );
    set_selected_mode( NodeMode.EDITABLE );
    undo_buffer.add_item( new UndoNodeInsert( node ) );
  }

  /* Removes the specified node from the table */
  public void delete_node( Node node ) {
    var was_selected = (node == selected);
    var next         = node.get_next_node() ?? node.get_previous_node();
    node.parent.remove_child( node );
    if( was_selected ) {
      selected = next;
    }
    queue_draw();
    changed();

  }

  /* Removes the selected node from the table */
  public void delete_current_node() {
    if( selected == null ) return;
    undo_buffer.add_item( new UndoNodeDelete( selected ) );
    delete_node( selected );
    queue_draw();
    changed();
  }

  /* Returns true if the currently selected row is indentable */
  public bool indentable() {
    return( (selected != null) && (selected.index() > 0) );
  }

  /* Returns true if the currently selected row is unindentable */
  public bool unindentable() {
    return( (selected != null) && !selected.parent.is_root() );
  }

  /*
   Indents the specified node such that it becomes the child of the sibling
   node above it.
  */
  public void indent_node( Node node ) {
    var index = node.index();
    if( index == 0 ) return;
    var parent = node.parent;
    parent.remove_child( node );
    parent.children.index( index - 1 ).add_child( node );
    queue_draw();
    changed();
  }

  /*
   Indents the currently selected row such that it becomes the child of the
   sibling row above it
  */
  public void indent() {
    if( selected == null ) return;
    undo_buffer.add_item( new UndoNodeIndent( selected ) );
    indent_node( selected );
  }

  /*
   Removes the specified node from its parent and places itself just below its
   parent.
  */
  public void unindent_node( Node node ) {
    if( node.parent.is_root() ) return;
    var parent       = node.parent;
    var parent_index = parent.index();
    var grandparent  = parent.parent;
    parent.remove_child( node );
    grandparent.add_child( node, (parent_index + 1) );
    see( selected );
    queue_draw();
    changed();
  }

  /*
   Removes the currently selected row from its parent and places itself just
   below its parent.
  */
  public void unindent() {
    if( selected == null ) return;
    undo_buffer.add_item( new UndoNodeUnindent( selected ) );
    unindent_node( selected );
  }

  /* Set the notes display for all nodes to the given value */
  public void set_notes_display( bool show ) {
    root.set_notes_display( show );
    // nodes.index( 0 ).adjust_nodes_all( nodes.index( 0 ).last_y, true );
    see( selected );
    queue_draw();
    changed();
  }

  /*******************/
  /* DRAWING METHODS */
  /*******************/

  /* Draw the available nodes */
  public bool on_draw( Context ctx ) {

    draw_background( ctx );
    draw_all( ctx );

    return( false );

  }

  /* Draw the background from the stylesheet */
  private void draw_background( Context ctx ) {
    get_style_context().render_background( ctx, 0, 0, get_allocated_width(), get_allocated_height() );
  }

  /* Draws all of the root node trees */
  public void draw_all( Context ctx ) {
    root.draw_tree( ctx, _theme );
    if( (selected != null) && ((selected.parent == null) || selected.parent.expanded) ) {
      selected.draw( ctx, _theme );
    }
  }

}

