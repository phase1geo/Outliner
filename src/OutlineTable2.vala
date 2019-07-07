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

  private Document        _doc;
  private Array<Node>     _nodes;
  private Node?           _selected = null;
  private Node?           _active   = null;
  private double          _press_x;
  private double          _press_y;
  private bool            _pressed    = false;
  private EventType       _press_type = EventType.NOTHING;
  private bool            _motion     = false;
  private Theme           _theme;
  private IMContextSimple _im_context;

  public Document   document    { get { return( _doc ); } }
  public UndoBuffer undo_buffer { get; set; }
  public Node?      selected {
    get {
      return( _selected );
    }
    set {
      if( _selected != null ) {
        _selected.mode = NodeMode.NONE;
      }
      _selected = value;
      if( _selected != null ) {
        _selected.mode = NodeMode.SELECTED;
      }
    }
  }

  /* Called by this class when a change is made to the table */
  public signal void changed();

  /* Default constructor */
  public OutlineTable( GLib.Settings settings ) {
 
    /* Create the document for this table */
    _doc = new Document( this, settings );

    /* Allocate storage item */
    _nodes = new Array<Node>();

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );

    /* Set the style context */
    get_style_context().add_class( "canvas" );

    /* Set the default theme */
    set_theme( MainWindow.themes.get_theme( "solarized_dark" ) );

    /* Add event listeners */
    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.motion_notify_event.connect( on_motion );
    this.button_release_event.connect( on_release );
    this.key_press_event.connect( on_keypress );
    // TBD - this.scroll_event.connect( on_scroll );

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

  /* Returns true if the currently selected node is editable */
  private bool is_node_editable() {

    return( (selected != null) && (selected.mode == NodeMode.EDITABLE) );

  }

  /* Returns the node at the given coordinates */
  private Node? node_at_coordinates( double x, double y ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var clicked = _nodes.index( i ).get_containing_node( x, y );
      if( clicked != null ) {
        return( clicked );
      }
    }
    return( null );
  }

  /* Selects the node at the given coordinates */
  private bool set_current_at_position( double x, double y, EventButton e ) {

    var clicked = node_at_coordinates( x, y );;

    _active = null;

    if( clicked != null ) {
      if( clicked.is_within_expander( x, y ) ) {
        stdout.printf( "A WITHIN_EXPANDER\n" );
        _active = clicked;
        return( false );
      } else if( (clicked == selected) && (clicked.mode == NodeMode.EDITABLE) ) {
        bool shift = (bool) e.state & ModifierType.SHIFT_MASK;
        switch( e.type ) {
          case EventType.BUTTON_PRESS        :  clicked.name.set_cursor_at_char( e.x, e.y, shift );  break;
          case EventType.DOUBLE_BUTTON_PRESS :  clicked.name.set_cursor_at_word( e.x, e.y, shift );  break;
          case EventType.TRIPLE_BUTTON_PRESS :  clicked.name.set_cursor_all( false );                break;
        }
      } else {
        selected = clicked;
        if( e.type == EventType.DOUBLE_BUTTON_PRESS ) {
          clicked.mode = NodeMode.EDITABLE;
        }
      }
    }

    return( true );

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
        // TBD - show_contextual_menu( e );
        break;
    }

    return( false );

  }

  /* Handle mouse motion */
  private bool on_motion( EventMotion e ) {

    _motion = true;

    if( _pressed ) {
      if( selected != null ) {
        if( selected.mode == NodeMode.SELECTED ) {
          selected.mode = NodeMode.MOVETO;
          selected.parent.remove_child( selected );
        }
        selected.x = e.x;
        selected.y = e.y;
        var current = node_at_coordinates( e.x, e.y );
        if( current != null ) {
          if( current.is_within_attach( e.x, e.y ) ) {
            current.mode = NodeMode.ATTACHTO;
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

    return( false );

  }

  /* Handles the release of the mouse button */
  private bool on_release( EventButton e ) {

    if( _pressed ) {

      if( _active != null ) {
        if( _motion ) {
          switch( _active.mode ) {
            case NodeMode.ATTACHTO :
              _active.add_child( selected );
              break;
            case NodeMode.ATTACHBELOW :
              if( !_active.is_leaf() ) {
                _active.add_child( selected, 0 );
              } else {
                _active.parent.add_child( selected, (_active.index() + 1) );
              }
              break;
          }
          selected.mode = NodeMode.SELECTED;
          _active.mode  = NodeMode.NONE;
          _active       = null;
          queue_draw();
          changed();
        }
      }

    } else {

      /* If the user clicked in an expander, toggle the expander */
      if( !_motion && _active.is_within_expander( e.x, e.y ) ) {
        stdout.printf( "B WITHIN_EXPANDER\n" );
        _active.expanded = !_active.expanded;
        queue_draw();
        changed();
      }

    }

    _pressed = false;

    return( false );

  }

  /* Handles keypress events */
  private bool on_keypress( EventKey e ) {

    /* Figure out which modifiers were used */
    var control = (bool) e.state & ModifierType.CONTROL_MASK;
    var shift   = (bool) e.state & ModifierType.SHIFT_MASK;
    var nomod   = !(control || shift);

    /* If there is a current node or connection selected, operate on it */
    if( selected != null ) {
      if( control ) {
        switch( e.keyval ) {
          case 99    :  /* do_copy(); */                     break;
          case 120   :  /* do_cut(); */                      break;
          case 118   :  /* do_paste(); */                    break;
          case 65293 :  handle_control_return();        break;
          case 65289 :  handle_control_tab();           break;
          case 65363 :  handle_control_right( shift );  break;
          case 65361 :  handle_control_left( shift );   break;
          case 65362 :  handle_control_up( shift );     break;
          case 65364 :  handle_control_down( shift );   break;
          case 47    :  handle_control_slash();         break;
          case 92    :  handle_control_backslash();     break;
          case 46    :  handle_control_period();        break;
        }
      } else if( nomod || shift ) {
        if( _im_context.filter_keypress( e ) ) {
          return( true );
        }
        switch( e.keyval ) {
          case 65288 :  handle_backspace();         break;
          case 65535 :  handle_delete();            break;
          case 65307 :  handle_escape();            break;
          case 65293 :  handle_return();            break;
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

    return( true );

  }

  private void handle_backspace() {
    if( is_node_editable() ) {
      selected.name.backspace();
      queue_draw();
    } else if( selected != null ) {
      delete_node();
    }
  }

  private void handle_delete() {
    if( is_node_editable() ) {
      selected.name.delete();
      queue_draw();
    } else if( selected != null ) {
      delete_node();
    }
  }

  private void handle_escape() {
    if( is_node_editable() ) {
      selected.mode = NodeMode.SELECTED;
      queue_draw();
      changed();
    }
  }

  private void handle_return() {
    if( selected != null ) {
      if( selected.is_root() ) {
        add_root_node();
      } else {
        add_sibling_node();
      }
    }
  }

  private void handle_control_return() {
    if( is_node_editable() ) {
      selected.name.insert( "\n" );
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
    if( selected != null ) {
      unindent();
    }
  }

  private void handle_control_tab() {
    if( is_node_editable() ) {
      selected.name.insert( "\t" );
      queue_draw();
    }
  }

  private void handle_right( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_char( 1 );
      } else {
        selected.name.move_cursor( 1 );
      }
      queue_draw();
    } else if( selected != null ) {
      if( !selected.is_leaf() && !selected.expanded ) {
        selected.expanded = true;
        queue_draw();
      }
    }
  }

  private void handle_control_right( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_word( 1 );
      } else {
        selected.name.move_cursor_by_word( 1 );
      }
      queue_draw();
    }
  }

  private void handle_left( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_char( -1 );
      } else {
        selected.name.move_cursor( -1 );
      }
      queue_draw();
    } else if( selected != null ) {
      if( !selected.is_leaf() && selected.expanded ) {
        selected.expanded = false;
        queue_draw();
      }
    }
  }

  private void handle_control_left( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_word( -1 );
      } else {
        selected.name.move_cursor_by_word( -1 );
      }
      queue_draw();
    }
  }

  private void handle_up( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_vertically( -1 );
      } else {
        selected.name.move_cursor_vertically( -1 );
      }
      queue_draw();
    } else if( selected != null ) {
      var node = selected.get_previous_node();
      if( node != null ) {
        selected = node;
        queue_draw();
      }
    }
  }

  private void handle_control_up( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_start();
      } else {
        selected.name.move_cursor_to_start();
      }
      queue_draw();
    }
  }

  private void handle_down( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_vertically( 1 );
      } else {
        selected.name.move_cursor_vertically( 1 );
      }
      queue_draw();
    } else if( selected != null ) {
      var node = selected.get_next_node();
      if( node != null ) {
        selected = node;
        queue_draw();
      }
    }
  }

  private void handle_control_down( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_end();
      } else {
        selected.name.move_cursor_to_end();
      }
      queue_draw();
    }
  }

  private void handle_control_slash() {
    if( is_node_editable() ) {
      selected.name.set_cursor_all( false );
      queue_draw();
    }
  }

  private void handle_control_backslash() {
    if( is_node_editable() ) {
      selected.name.clear_selection();
      queue_draw();
    }
  }

  /* Called whenever the period key is entered with the control key */
  private void handle_control_period() {
    if( is_node_editable() ) {
      insert_emoji( selected.name );
    }
  }

  private void handle_home() {
    if( is_node_editable() ) {
      selected.name.move_cursor_to_start();
      queue_draw();
    }
  }

  private void handle_end() {
    if( is_node_editable() ) {
      selected.name.move_cursor_to_end();
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

  private void handle_printable( string str ) {
    if( !str.get_char( 0 ).isprint() ) return;
    if( is_node_editable() ) {
      selected.name.insert( str );
      queue_draw();
    } else if( selected != null ) {
      /* TBD */
    }
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
      text.insert( entry.text );
      entry.unparent();
      grab_focus();
    });
    overlay.add_overlay( entry );
    entry.insert_emoji();
  }

  /* Returns the currently applied heme */
  public Theme get_theme() {

    return( _theme );

  }

  /* Sets the theme to the given value */
  public void set_theme( Theme theme, bool save = true ) {

    _theme = theme;

    StyleContext.add_provider_for_screen(
      Screen.get_default(),
      _theme.get_css_provider(),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    queue_draw();

    if( save ) {
      changed();
    }

  }

  /* Creates a new, unnamed document */
  public void initialize_for_new() {

    /*
     Add some test data so that we can test things before we add the
     ability to save and load data.
    */
    add_test_data();

  }

  public void initialize_for_open() {
    // TBD
  }

  /***************************/
  /* FILE LOAD/STORE METHODS */
  /***************************/

  /* Loads the table information from the given XML node */
  public void load( Xml.Node* n ) {

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

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        var node = new Node( this );
        node.load( this, it );
        _nodes.append_val( node );
      }
    }

  }

  /* Saves the table information to the given XML node */
  public void save( Xml.Node* n ) {

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

    Xml.Node* nodes = new Xml.Node( null, "nodes" );

    for( int i=0; i<_nodes.length; i++ ) {
      nodes->add_child( _nodes.index( i ).save() );
    }

    return( nodes );

  }

  /**************************/
  /* SEARCH-RELATED METHODS */
  /**************************/

  /* Finds the rows that match the given search criteria */
  public void get_match_items( string pattern, bool[] opts, ref Gtk.ListStore items ) {
    // TBD
  }

  /************************/
  /* TREE-RELATED METHODS */
  /************************/

  /* Creates a new node that is ready to be edited */
  private Node create_node() {

    var node = new Node( this );

    selected = node;
    node.mode = NodeMode.EDITABLE;

    return( node );

  }

  /* Adds a new root node */
  public void add_root_node() {

    uint insert_index = _nodes.length;

    if( selected != null ) {
      var root = selected.get_root_node();
      for( uint i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == root ) {
          insert_index = (i + 1);
        }
      }
    }

    /* Create the new node and add it to the nodes array */
    _nodes.insert_val( insert_index, create_node() );

    queue_draw();
    changed();

  }

  /* Adds a sibling node of the currently selected node */
  public void add_sibling_node() {

    if( (selected == null) || selected.is_root() ) return;

    var index = selected.index();
    var sel   = selected;

    sel.parent.add_child( create_node(), (index + 1) );

    queue_draw();
    changed();

  }

  /* Adds a child node of the currently selected node */
  public void add_child_node() {

    if( selected == null ) return;

    var sel = selected;

    sel.add_child( create_node() );

    queue_draw();
    changed();

  }

  /* Removes the selected node from the table */
  public void delete_node() {

    if( selected == null ) return;

    var next = selected.get_next_node() ?? selected.get_previous_node();

    selected.parent.remove_child( selected );

    if( next != null ) {
      selected = next;
    }

    queue_draw();
    changed();

  }

  /* Indents the currently selected row such that it becomes the child of the sibling row above it */
  public void indent() {
    if( (selected == null) || selected.is_root() ) return;
    var index = selected.index();
    if( index > 0 ) {
      var parent = selected.parent;
      if( selected.is_root() ) {
        _nodes.remove_index( index );
      } else {
        parent.remove_child( selected );
      }
      parent.children.index( index - 1 ).add_child( selected );
    }
    queue_draw();
    changed();
  }
      
  /* Removes the currently selected row from its parent and places itself just below its parent */
  public void unindent() {
    if( (selected == null) || selected.is_root() ) return;
    var index        = selected.index();
    var parent       = selected.parent;
    var parent_index = parent.index();
    var grandparent  = parent.parent;
    parent.remove_child( selected );
    if( grandparent == null ) {
      _nodes.insert_val( (parent_index + 1), selected );
    } else {
      grandparent.add_child( selected, (parent_index + 1) );
    }
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
  private void draw_all( Context ctx ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).draw_tree( ctx, _theme );
    }
    if( selected != null ) {
      selected.draw( ctx, _theme );
    }
  }

  /* Temporary function which gives us some test data */
  private void add_test_data() {

    Node level0;
    Node level1;
    Node level2;
    
    level0 = new Node( this );  level0.name.text = "Main Idea";

    level1 = new Node( this );  level1.name.text = "First things";   level0.add_child( level1 );
    level1 = new Node( this );  level1.name.text = "Second things";  level0.add_child( level1 );

    level2 = new Node( this );  level2.name.text = "Subitem A";  level1.add_child( level2 );
    level2 = new Node( this );  level2.name.text = "Subitem B";  level1.add_child( level2 );

    level1 = new Node( this );  level1.name.text = "Third things";  level0.add_child( level1 );

    _nodes.append_val( level0 );

    changed();

  }

}

