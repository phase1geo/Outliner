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

  private Array<Node> _nodes;
  private Node?       _selected = null;
  private Node?       _active   = null;
  private double      _press_x;
  private double      _press_y;
  private bool        _pressed    = false;
  private EventType   _press_type = EventType.NOTHING;
  private bool        _motion     = false;

  public UndoBuffer undo_buffer { get; set; }
  public Theme      theme       { get; set; default = new Theme(); }
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
  public OutlineTable() {

    /* Allocate storage item */
    _nodes = new Array<Node>();

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );

    /* Add event listeners */
    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.motion_notify_event.connect( on_motion );
    this.button_release_event.connect( on_release );
    // TBD - this.key_press_event.connect( on_keypress );
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

    /*
     Add some test data so that we can test things before we add the
     ability to save and load data.
    */
    add_test_data();

    /*
    Theme theme = new Theme();
    stdout.printf( "HERE A\n" );
    StyleContext.add_provider_for_screen( Screen.get_default(), theme.get_css_provider(), STYLE_PROVIDER_PRIORITY_APPLICATION );
    stdout.printf( "HERE B\n" );
    */

  }

  /* Selects the node at the given coordinates */
  private bool set_current_at_position( double x, double y, EventButton event ) {

    _active = null;

    /* Get the active node */
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i ).get_containing_node( x, y );
      if( node != null ) {
        if( node.is_within_expander( x, y ) ) {
          _active = node;
        } else {
          selected = node;
        }
        break;
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

    if( _pressed ) {
      // TBD
    }

    return( false );

  }

  private bool on_release( EventButton e ) {

    if( _pressed ) {

      if( _active != null ) {
        if( _active.is_within_expander( e.x, e.y ) ) {
          _active.expanded = !_active.expanded;
          queue_draw();
          changed();
        }
      }

    } else {

    }

    _pressed = false;

    return( false );

  }

  /* Sets the theme to the given value */
  /*
  public void set_theme( string name ) {
    Theme? orig_theme = _theme;
    _theme = themes.get_theme( name );
    StyleContext.add_provider_for_screen(
      Screen.get_default(),
      _theme.get_css_provider(),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
    if( orig_theme != null ) {
      map_theme_colors( orig_theme );
    }
    theme_changed();
    queue_draw();
  }
  */

  public void initialize_for_new() {
    // TBD
  }

  public void initialize_for_open() {
    // TBD
  }

  /* Loads the table information from the given XML node */
  public void load( Xml.Node* n ) {
    // TBD
  }

  /* Saves the table information to the given XML node */
  public void save( Xml.Node* n ) {
    // TBD
  }

  /* Finds the rows that match the given search criteria */
  public void get_match_items( string pattern, bool[] opts, ref Gtk.ListStore items ) {
    // TBD
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
      _nodes.index( i ).draw_tree( ctx, theme );
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

  }

}

