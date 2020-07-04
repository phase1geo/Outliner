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
using Gdk;
using Gee;
using Granite.Drawing;

public enum NodeMode {
  NONE = 0,      // Indicates that this node is nothing special
  SELECTED,      // Selects the node to perform an action on
  ATTACHTO,      // Shows the node as something that can be attached as a child
  ATTACHABOVE,   // Shows the node as something that can be attached as a sibling above
  ATTACHBELOW,   // Shows the node as something that can be attached as a sibling below
  MOVETO,        // Indicates that the node is being dragged by the user
  EDITABLE,      // Indicates that the node text is being edited
  NOTEEDIT,      // Indicates that the note text is being edited
  HOVER          // Indicates that the cursor is hovering over this node
}

public enum NodeListType {
  NONE = 0,   // Indicates that lists should not be annotated
  OUTLINE,    // Indicates that lists should show ordered outline annotations (ex. "I.", "A.", etc.)
  SECTION,    // Indicates that lists should show section annotations (ex. "1.0", "1.1.2", etc.)
  LENGTH;     // Not a value but can be used for for() loops

  /* Displays the string value of this NodeSide */
  public string to_string() {
    switch( this ) {
      case NONE    :  return( "none" );
      case OUTLINE :  return( "outline" );
      case SECTION :  return( "section" );
      default      :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case NONE    :  return( _( "None" ) );
      case OUTLINE :  return( _( "Outline" ) );
      case SECTION :  return( _( "Section" ) );
      default      :  assert_not_reached();
    }
  }

  /* Translates a string from to_string() to a NodeSide value */
  public static NodeListType parse( string val ) {
    switch( val ) {
      case "none"    :  return( NONE );
      case "outline" :  return( OUTLINE );
      case "section" :  return( SECTION );
      default        :  assert_not_reached();
    }
  }

  /* Outputs the tooltip to be displayed for each type */
  public string tooltip() {
    switch( this ) {
      case NONE    :  return( _( "No enumeration will be displayed" ) );
      case OUTLINE :  return( _( "Shows outline-like enumeration (ex., I., A., 1.)" ) );
      case SECTION :  return( _( "Shows section enumeration (ex., 2., 2.1., 2.1.3.)" ) );
      default      :  assert_not_reached();
    }
  }
}

public enum NodeTaskMode {
  NONE = 0,  // Indicates that this node does not have a task assigned
  OPEN,      // Indicates that a task is assigned but is not completed
  DOING,     // Indicates that the task is in the process of being done
  DONE;      // Indicates that a task is assigned and is completed

  public string to_string() {
    switch( this ) {
      case OPEN  :  return( "open" );
      case DOING :  return( "doing" );
      case DONE  :  return( "done" );
      default    :  return( "none" );
    }
  }

  public static NodeTaskMode from_string( string value ) {
    switch( value ) {
      case "open"  :  return( OPEN );
      case "doing" :  return( DOING );
      case "done"  :  return( DONE );
      default      :  return( NONE );
    }
  }

}

public class NodeDrawOptions {
  public bool show_note_icon { get; set; default = true; }
  public bool show_modes     { get; set; default = true; }
  public bool show_note_bg   { get; set; default = true; }
  public bool show_note_ol   { get; set; default = false; }
  public bool show_expander  { get; set; default = true; }
  public bool show_depth     { get; set; default = true; }
  public bool use_theme      { get; set; default = false; }
  public NodeDrawOptions() {}
}

public class NodeCloneData {
  public int           id;
  public FormattedText name;
  public FormattedText note;
  public NodeCloneData() {}
}

public class Node {

  private const int note_size = 16;
  private const int task_size = 16;
  private const int expander_size = 10;

  private static int next_id  = 0;
  private static int clone_id = 0;

  private OutlineTable  _ot;
  private int           _id        = next_id++;
  private CanvasText    _name;
  private CanvasText    _note;
  private NodeMode      _mode      = NodeMode.NONE;
  private double        _x         = 0;
  private double        _y         = 40;
  private double        _w         = 500;
  private double        _h         = 80;
  private int           _depth     = 0;
  private bool          _expanded  = true;
  private Pango.Layout  _lt_layout;
  private double        _lt_width  = 0;
  private bool          _hide_note = true;
  private int           _clone_id  = -1;
  private NodeTaskMode  _task      = NodeTaskMode.OPEN;
  private bool          _debug     = false;

  private static Pixbuf? _note_icon = null;

  /* Signals */
  public signal void select_mode( bool name, bool mode );
  public signal void cursor_changed( bool name );

  /* Properties */
  public int id {
    get {
      return( _id );
    }
  }
  public NodeMode mode {
    get {
      return( _mode );
    }
    set {
      if( (_mode != value) && !is_root() ) {
        var note_was_edited = _mode == NodeMode.NOTEEDIT;
        _mode = value;
        name.edit = (_mode == NodeMode.EDITABLE);
        note.edit = (_mode == NodeMode.NOTEEDIT);
        if( !note.edit && note_was_edited && (note.text.text == "") ) {
          hide_note = true;
        }
        update_height( true );
      }
    }
  }
  public NodeTaskMode task {
    get {
      return( _ot.show_tasks ? _task : NodeTaskMode.NONE );
    }
    set {
      if( _ot.show_tasks ) {
        update_task( value, true, true );
      }
    }
  }
  public CanvasText name {
    get {
      return( _name );
    }
    set {
      _name = value;
    }
  }
  public CanvasText note {
    get {
      return( _note );
    }
    set {
      _note = value;
    }
  }
  public double x {
    get {
      return( _x );
    }
    set {
      _x = value;
      position_text();
    }
  }
  public double y {
    get {
      return( _y );
    }
    set {
      _y = value;
      position_text();
    }
  }
  public double width {
    get {
      return( _w );
    }
    set {
      _w = value;
    }
  }
  public double height {
    get {
      return( _h );
    }
    set {
      _h = value;
    }
  }
  public int depth {
    get {
      return( _depth );
    }
    set {
      _depth = value;
      for( int i=0; i<children.length; i++ ) {
        children.index( i ).depth = _depth + 1;
      }
    }
  }
  public bool expanded {
    get {
      return( _expanded );
    }
    set {
      if( value != _expanded ) {
        _expanded = value;
        adjust_nodes( last_y, false, "expanded" );
      }
    }
  }
  public bool expanded_only {
    set {
      _expanded = value;
    }
  }
  public bool hidden { get; set; default = false; }
  public bool hide_note {
    get {
      return( _hide_note );
    }
    set {
      if( value != _hide_note ) {
        _hide_note = value;
        update_height( true );
        adjust_nodes( last_y, false, "hide_note" );
      }
    }
  }
  public double      alpha     { get; set; default = 1.0; }
  public double      padx      { get; set; default = 10; }
  public double      pady      { get; set; default = 10; }
  public double      indent    { get; set; default = 25; }
  public Node?       parent    { get; set; default = null; }
  public Array<Node> children  { get; set; default = new Array<Node>(); }
  public double      last_y    { get { return( _y + (hidden ? 0 : _h) ); } }
  public bool        over_note_icon { get; set; default = false; }

  /* Constructor */
  public Node( OutlineTable ot ) {

    _ot = ot;

    _lt_layout = ot.create_pango_layout( null );

    _name = new CanvasText( ot, ot.get_allocated_width() );
    _name.text.add_parser( ot.tagger_parser );
    _name.resized.connect( update_height_from_resize );
    _name.select_mode.connect( name_select_mode );
    _name.cursor_changed.connect( name_cursor_changed );

    _note = new CanvasText( ot, ot.get_allocated_width() );
    _note.resized.connect( update_height_from_resize );
    _note.select_mode.connect( note_select_mode );
    _note.cursor_changed.connect( note_cursor_changed );

    change_name_font( ot.name_font_family, ot.name_font_size, false );
    change_note_font( ot.note_font_family, ot.note_font_size, false );

    pady = ot.condensed ? 2 : 10;

    position_text();
    update_width();
    table_markdown_changed();

    /* Detect any size changes by the drawing area */
    ot.win.configure_event.connect( window_size_changed );
    ot.zoom_changed.connect( table_zoom_changed );
    ot.theme_changed.connect( table_theme_changed );
    ot.show_tasks_changed.connect( update_height_from_resize );
    ot.markdown_changed.connect( table_markdown_changed );

  }

  /* Constructor of root node */
  public Node.root() {}

  /* Copy constructor */
  public Node.clone_from_node( OutlineTable ot, Node node ) {

    _ot = ot;

    /* Handle the clone ID */
    if( node._clone_id == -1 ) {
      int cid        = clone_id++;
      node._clone_id = cid;
      _clone_id      = cid;
    } else {
      _clone_id      = node._clone_id;
    }

    _lt_layout = ot.create_pango_layout( null );

    _name = new CanvasText.clone_from( ot, ot.get_allocated_width(), node.name );
    _name.text.add_parser( ot.tagger_parser );
    _name.resized.connect( update_height_from_resize );
    _name.select_mode.connect( name_select_mode );
    _name.cursor_changed.connect( name_cursor_changed );

    _note = new CanvasText.clone_from( ot, ot.get_allocated_width(), node.note );
    _note.resized.connect( update_height_from_resize );
    _note.select_mode.connect( note_select_mode );
    _note.cursor_changed.connect( note_cursor_changed );

    change_name_font( ot.name_font_family, ot.name_font_size, false );
    change_note_font( ot.note_font_family, ot.note_font_size, false );

    pady = ot.condensed ? 2 : 10;

    position_text();
    update_width();
    table_markdown_changed();

    /* Detect any size changes by the drawing area */
    ot.win.configure_event.connect( window_size_changed );
    ot.zoom_changed.connect( table_zoom_changed );
    ot.theme_changed.connect( table_theme_changed );
    ot.show_tasks_changed.connect( update_height_from_resize );
    ot.markdown_changed.connect( table_markdown_changed );

  }

  /* Destructor */
  ~Node() {
    _ot.win.configure_event.disconnect( window_size_changed );
    _ot.zoom_changed.disconnect( table_zoom_changed );
    _ot.theme_changed.disconnect( table_theme_changed );
    _ot.show_tasks_changed.disconnect( update_height_from_resize );
    _ot.markdown_changed.disconnect( table_markdown_changed );
  }

  /* Create the note icon pixbuf if we need to */
  private void initialize_note_icon() {
    if( _note_icon == null ) {
      try {
        _note_icon = new Pixbuf.from_resource( "/com/github/phase1geo/outliner/images/accessories-text-editor-symbolic" );
      } catch( GLib.Error e ) {}
    }
  }

  /* If the window size changes, adjust our width */
  private bool window_size_changed( EventConfigure e ) {
    update_width();
    return( false );
  }

  /* Updates the size of the name and note information */
  private void table_zoom_changed() {
    int width, height;
    var zoom_factor = _ot.win.get_zoom_factor();
    _name.set_font( null, null, zoom_factor );
    _note.set_font( null, null, zoom_factor );
    _lt_layout.set_font_description( _name.get_font_fd() );
    _lt_layout.get_size( out width, out height );
    _lt_width = width / Pango.SCALE;
  }

  /*
   If the theme has changed, all we need to do is alert the CanvasText to
   rerender the text.
  */
  private void table_theme_changed() {
    _name.update_size( false );
    _note.update_size( false );
  }

  /* Handle any changes to the markdown parser */
  private void table_markdown_changed() {
    if( _ot.markdown ) {
      _name.text.add_parser( _ot.markdown_parser );
      _note.text.add_parser( _ot.markdown_parser );
    } else {
      _name.text.remove_parser( _ot.markdown_parser );
      _note.text.remove_parser( _ot.markdown_parser );
    }
  }

  /* Generates the select mode signal for the name field */
  private void name_select_mode( bool mode ) {
    select_mode( true, mode );
  }

  /* Generates the select mode signal for the note field */
  private void note_select_mode( bool mode ) {
    select_mode( false, mode );
  }

  private void name_cursor_changed() {
    cursor_changed( true );
  }

  private void note_cursor_changed() {
    cursor_changed( false );
  }

  /* Returns true if this node is a cloned node */
  public bool is_clone() {
    return( _clone_id != -1 );
  }

  /*
   If this node is cloned, we will unclone the node by making a copy of the name/note from
   the cloned value.
  */
  public void unclone() {
    if( !is_clone() ) return;
    _clone_id = -1;
    name.unclone( _ot );
    note.unclone( _ot );
  }

  /* Returns clone data which is used for undoing/redoing uncloning */
  public NodeCloneData get_clone_data() {
    var clone_data = new NodeCloneData();
    clone_data.id   = _clone_id;
    clone_data.name = name.text;
    clone_data.note = note.text;
    return( clone_data );
  }

  /* Re-clones a node that was previously cloned */
  public void reclone( NodeCloneData clone_data ) {
    _clone_id = clone_data.id;
    name.clone( clone_data.name );
    note.clone( clone_data.note );
  }

  /* Called whenever the canvas width changes */
  private void update_width() {

    /* Get the width of the table */
    int w, h;
    _ot.win.get_size( out w, out h );

    var rmargin = (padx * 5) + 20;

    /* Update our width information */
    _w = w;
    _name.max_width = _w - (_name.posx + rmargin);
    _note.max_width = _w - (_note.posx + rmargin);

  }

  /* Updates the size of this node */
  private void update_height( bool adjust ) {

    var orig_height = _h;

    _h = (pady * 2) + _name.height;

    if( !_hide_note && (mode != NodeMode.MOVETO) ) {
      _h += pady + _note.height;
    }

    if( adjust && (orig_height != _h) ) {
      adjust_nodes( last_y, false, "update_height" );
      _ot.see( this );
    }

  }

  /*
   Updates the height information due to either the name or the note being
   resized.
  */
  private void update_height_from_resize() {
    position_text();
    update_width();
    update_height( true );
  }

  /*
   Returns true if this node is on the border of a page and we will return the
   number of pixels to draw on the first page.
  */
  public bool on_page_boundary( int page_size, out double inc_size ) {

    var int_y     = (int)_y;
    var int_pady  = (int)pady;
    var int_nameh = (int)_name.height;
    var int_noteh = (int)_note.height;

    /* If the node starts at the top of the next page, return true */
    if( ((int)_y % page_size) == 0 ) {
      inc_size = 0;
      return( true );

    /*
     If the node name straddles the page boundary, make sure that we set inc_size
     such that we don't cut off a line.
    */
    } else if( (int_y / page_size) != ((int_y + int_pady + int_nameh) / page_size) ) {
      inc_size = name.get_page_include_size( page_size ) + int_y + int_pady;
      return( true );

    /*
     If the node note straddles the page boundary, make sure that we set inc_size
     such that we don't cut off a line.
    */
    } else if( !hide_note && ((int_y / page_size) != ((int_y + (int_pady * 2) + int_nameh + int_noteh) / page_size)) ) {
      inc_size = note.get_page_include_size( page_size ) + int_y + (int_pady * 2) + int_nameh;
      return( true );
    }

    inc_size = _h;

    return( false );

  }

  /*
   Checks to see if the current node is the last node and, if it is, sets the
   height of the OutlineTable to the calculated last_y of this node.
  */
  private void set_ot_height() {
    if( this == get_root_node().get_last_node() ) {
      var vp = _ot.parent.parent as Viewport;
      var vh = vp.get_allocated_height();
      var end_y = ((int)last_y > ((int)y + vh)) ? (int)last_y : ((int)y + vh);
      _ot.set_size_request( -1, end_y );
    }
  }

  /* Adjusts the posy value of all of the nodes displayed below this node */
  public double adjust_nodes( double last_y, bool deleted, string msg, int child_start = 0 ) {

    if( _debug ) {
      stdout.printf( "In adjust_nodes (%s)\n", msg );
    }

    if( expanded && !deleted ) {
      last_y = adjust_descendants( last_y, child_start );
    }

    if( parent != null ) {
      last_y = parent.adjust_nodes( last_y, false, "adjust_nodes", (index() + 1) );
    }

    /* If the current node is the last node, update the widget size to match the current height */
    set_ot_height();

    return( last_y );

  }

  /* Adjusts the posy value of all nodes that are descendants of the give node */
  private double adjust_descendants( double last_y, int child_start ) {
    if( expanded ) {
      Node? child = null;
      for( int i=child_start; i<children.length; i++ ) {
        child   = children.index( i );
        child.y = last_y;
        last_y  = child.adjust_descendants( child.last_y, 0 );
      }
      if( child != null ) {
        child.set_ot_height();
      }
    }
    return( last_y );
  }

  public void set_tree_alpha( double value ) {
    alpha = value;
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).set_tree_alpha( value );
    }
  }

  /* Adjusts the position of the text object */
  private void position_text() {
    var zoom = _ot.win.get_zoom_factor();
    var tx   = ((task == NodeTaskMode.NONE) || _ot.tasks_on_right) ? 0 : (task_size + padx);
    var ltx  = (_ot.list_type == NodeListType.NONE) ? 0 : (_lt_width + (padx * zoom));
    name.posx = note.posx = x + (padx * 5) + (depth * indent) + 20 + tx + ltx;
    name.posy = y + pady;
    note.posy = y + (pady * 2) + name.height;
  }

  /* Searches the node tree for a node that matches the given ID */
  public string lookup_id() {
    var str  = index().to_string();
    var node = parent;
    while( !node.is_root() ) {
      str  = node.index().to_string() + "," + str;
      node = node.parent;
    }
    return( str );
  }

  private Node? get_node_by_lookup_id_helper( string[] indices, int index ) {
    if( index < indices.length ) {
      return( children.index( int.parse( indices[index] ) ).get_node_by_lookup_id_helper( indices, (index + 1) ) );
    }
    return( this );
  }

  /* Returns the node associated with the given lookup ID */
  public Node? get_node_by_lookup_id( string str ) {
    if( is_root() ) {
      string[] indices = str.split( "," );
      return( get_node_by_lookup_id_helper( indices, 0 ) );
    }
    return( null );
  }

  /* Propagates the current task information to the children */
  private void propagate_task_down() {
    if( task != NodeTaskMode.DOING ) {
      for( int i=0; i<children.length; i++ ) {
        var child = children.index( i );
        child.update_task( task, true, false );
      }
    }
  }

  /* Updates the task of this parent row based on the status of the children */
  private void update_task_from_children() {
    var value = NodeTaskMode.NONE;
    for( int i=0; i<children.length; i++ ) {
      var child = children.index( i );
      if( child.task != value ) {
        if( value == NodeTaskMode.NONE ) {
          value = child.task;
        } else if( child.task != NodeTaskMode.NONE ) {
          update_task( NodeTaskMode.DOING, false, true );
          return;
        }
      }
    }
    update_task( value, false, true );
  }

  /* Propagates the current task information upwards in the tree until we reach the root node */
  private void propagate_task_up() {
    if( !parent.is_root() ) {
      parent.update_task_from_children();
    }
  }

  /* Propagates the task information both up and down the node tree */
  private void update_task( NodeTaskMode value, bool prop_down, bool prop_up ) {
    if( _task == value ) return;
    var resize = (task == NodeTaskMode.NONE) || (value == NodeTaskMode.NONE);
    _task = value;
    if( resize )    update_height_from_resize();
    if( prop_down ) propagate_task_down();
    if( prop_up )   propagate_task_up();
  }

  /* Returns the root node of this node */
  public Node get_root_node() {
    var parent = _parent;
    var root   = this;
    while( parent != null ) {
      root = parent;
      parent = parent.parent;
    }
    return( root );
  }

  /* Returns the main node of this node */
  public Node? get_main_node() {
    if( is_root() ) return( null );
    var parent = _parent;
    var root   = this;
    while( (parent != null) && !parent.is_root() ) {
      root = parent;
      parent = parent.parent;
    }
    return( root );
  }

  /* Returns the first node in the current node tree */
  public Node? get_first_node() {
    if( is_leaf() || !expanded ) {
      return( this );
    } else {
      return( children.index( 0 ) );
    }
  }

  /* Returns the last node in the current node tree */
  public Node? get_last_node() {
    if( is_leaf() || !expanded ) {
      return( this );
    } else {
      return( children.index( children.length - 1 ).get_last_node() );
    }
  }

  /* Returns the node displayed before this node */
  public Node? get_previous_node() {
    var index = index();
    if( index <= 0 ) {
      return( parent.is_root() ? null : parent );
    } else {
      return( parent.children.index( index - 1 ).get_last_node() );
    }
  }

  /* Returns the node displayed after this node */
  public Node? get_next_node() {
    if( !is_leaf() && expanded ) {
      return( children.index( 0 ) );
    } else {
      var child = this;
      while( child.parent != null ) {
        var index = child.index();
        if( (index + 1) < child.parent.children.length ) {
          return( child.parent.children.index( index + 1 ) );
        }
        child = child.parent;
      }
      return( null );
    }
  }

  /* Returns the sibling node relative to this node */
  private Node? get_sibling( int dir ) {
    var index = index() + dir;
    if( (index < 0) || (index >= parent.children.length) ) {
      return( null );
    } else {
      return( parent.children.index( index ) );
    }
  }

  /* Returns the previous sibling node relative to this node */
  public Node? get_previous_sibling() {
    return( get_sibling( -1 ) );
  }

  /* Returns the previous sibling node relative to this node */
  public Node? get_next_sibling() {
    return( get_sibling( 1 ) );
  }

  /* Returns the first child node, if one exists; otherwise, returns null */
  public Node? get_first_child() {
    return( is_leaf() ? null : children.index( 0 ) );
  }

  /* Returns the last child node, if one exists; otherwise, returns null */
  public Node? get_last_child() {
    return( is_leaf() ? null : children.index( children.length - 1 ) );
  }

  /* Returns the node within this tree that contains the given coordinates */
  public Node? get_containing_node( double x, double y ) {
    if( !is_root() && is_within( x, y ) ) {
      return( this );
    } else if( expanded ) {
      for( int i=0; i<children.length; i++ ) {
        var node = children.index( i ).get_containing_node( x, y );
        if( node != null ) {
          return( node );
        }
      }
    }
    return( null );
  }

  /* Returns the area where we will draw the note icon */
  public void note_bbox( out double x, out double y, out double w, out double h ) {
    x = this.x + (padx * 2) + 10;
    y = this.y + pady + ((name.get_line_height() / 2) - (note_size / 2));
    w = note_size;
    h = note_size;
  }

  /* Returns the area where we will draw the task icon */
  private void task_bbox( out double x, out double y, out double w, out double h ) {
    if( _ot.tasks_on_right ) {
      int win_width, win_height;
      _ot.win.get_size( out win_width, out win_height );
      x = win_width - ((padx * 4) + 20);
    } else {
      x = this.x + (padx * 5) + 20 + (depth * indent);
    }
    y = this.y + pady + ((name.get_line_height() / 2) - (task_size / 2));
    w = task_size;
    h = task_size;
  }

  /* Returns the area where the expander will draw the expander icon */
  private void expander_bbox( out double x, out double y, out double w, out double h ) {
    x = this.x + (padx * 4) + 10 + (depth * indent);
    y = this.y + pady + ((name.get_line_height() / 2) - (expander_size / 2));
    w = expander_size;
    h = expander_size;
  }

  /* Returns true if the given coordinates are within this node */
  public bool is_within( double x, double y ) {
    return( !hidden && Utils.is_within_bounds( x, y, this.x, this.y, width, _h ) );
  }

  /* Returns true if the given coordinates lie within the expander */
  public bool is_within_expander( double x, double y ) {
    if( is_leaf() || hidden ) return( false );
    double ex, ey, ew, eh;
    expander_bbox( out ex, out ey, out ew, out eh );
    return( Utils.is_within_bounds( x, y, ex, ey, ew, eh ) );
  }

  /* Returns true if the given coordinates reside within the note icon boundaries */
  public bool is_within_note_icon( double x, double y ) {
    if( hidden ) return( false );
    double nx, ny, nw, nh;
    note_bbox( out nx, out ny, out nw, out nh );
    return( Utils.is_within_bounds( x, y, nx, ny, nw, nh ) );
  }

  public bool is_within_task( double x, double y ) {
    if( hidden ) return( false );
    double tx, ty, tw, th;
    task_bbox( out tx, out ty, out tw, out th );
    return( (task != NodeTaskMode.NONE) && Utils.is_within_bounds( x, y, tx, ty, tw, th ) );
  }

  /* Returns true if the given coordinates reside within the name text area */
  public bool is_within_name( double x, double y ) {
    return( !hidden && Utils.is_within_bounds( x, y, name.posx, name.posy, _w, name.height ) );
  }

  /* Returns true if the given coordinates reside within the note text area */
  public bool is_within_note( double x, double y ) {
    return( !hidden && Utils.is_within_bounds( x, y, note.posx, note.posy, _w, note.height ) );
  }

  /* Returns true if the given coordinates lie within the attachto area */
  public bool is_within_attachto( double x, double y ) {
    return( !hidden && Utils.is_within_bounds( x, y, this.x, (this.y + 4), width, (_h - 8) ) );
  }

  /* Returns true if the given coordinates lie within the attachabove area */
  public bool is_within_attachabove( double x, double y ) {
    return( !hidden && Utils.is_within_bounds( x, y, this.x, this.y, width, 4 ) );
  }

  /* Change the name font to the given value */
  public void change_name_font( string family, int size, bool recursive = true ) {
    if( !is_root() ) {
      int width, height;
      var zoom_factor = _ot.win.get_zoom_factor();
      _name.set_font( family, size, zoom_factor );
      _lt_layout.set_font_description( _name.get_font_fd() );
      _lt_layout.get_size( out width, out height );
      _lt_width = width / Pango.SCALE;
    }
    if( recursive ) {
      for( int i=0; i<children.length; i++ ) {
        children.index( i ).change_name_font( family, size );
      }
    }
  }

  /* Change the note font to the given value */
  public void change_note_font( string family, int size, bool recursive = true ) {
    if( !is_root() ) {
      var zoom_factor = _ot.win.get_zoom_factor();
      _note.set_font( family, size, zoom_factor );
    }
    if( recursive ) {
      for( int i=0; i<children.length; i++ ) {
        children.index( i ).change_note_font( family, size );
      }
    }
  }

  /*************************/
  /* FILE HANDLING METHODS */
  /*************************/

  /* Saves the current node and its children in XML Outliner format */
  public Xml.Node* save( ref HashMap<int,bool> clone_ids ) {

    Xml.Node* n = new Xml.Node( null, "node" );

    n->new_prop( "expanded", expanded.to_string() );
    n->new_prop( "hidenote", hide_note.to_string() );
    n->new_prop( "task",     _task.to_string() );

    /* Only save out the name/note if we are not a clone or if our clone has not been output yet */
    if( (_clone_id == -1) || !clone_ids.has_key( _clone_id ) ) {
      n->add_child( name.save( "name" ) );
      if( note.text.text != "" ) {
        n->add_child( note.save( "note" ) );
      }
    }

    if( _clone_id != -1 ) {
      n->new_prop( "clone_id", _clone_id.to_string() );
      clone_ids.set( _clone_id, true );
    }

    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    for( int i=0; i<children.length; i++ ) {
      nodes->add_child( children.index( i ).save( ref clone_ids ) );
    }

    n->add_child( nodes );

    return( n );

  }

  /* Loads the current node and its children from XML Outliner format */
  public void load( OutlineTable ot, Xml.Node* n, ref HashMap<int,Node> clone_ids ) {

    string? e = n->get_prop( "expanded" );
    if( e != null ) {
      expanded = bool.parse( e );
    }

    string? h = n->get_prop( "hidenote" );
    if( h != null ) {
      hide_note = bool.parse( h );
    }

    string? t = n->get_prop( "task" );
    if( t != null ) {
      _task = NodeTaskMode.from_string( t );
    }

    string? c = n->get_prop( "clone_id" );
    if( c != null ) {
      var cid = int.parse( c );
      if( !clone_ids.has_key( cid ) ) {
        _clone_id = cid;
        if( cid >= clone_id ) {
          clone_id = cid + 1;
        }
        clone_ids.set( cid, this );
      } else {
        var clone = clone_ids.get( cid );
        _clone_id = cid;
        name.clone( clone.name.text );
        note.clone( clone.note.text );
      }
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "name"  :  name.load( it );  break;
          case "note"  :  note.load( it );  break;
          case "nodes" :  load_nodes( ot, it, ref clone_ids );  break;
        }
      }
    }

  }

  /* Loads the given child node information */
  private void load_nodes( OutlineTable ot, Xml.Node* n, ref HashMap<int,Node> clone_ids ) {

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        var child = new Node( ot );
        add_child( child );
        child.load( ot, it, ref clone_ids );
      }
    }

  }

  /*************************/
  /* TREE HANDLING METHODS */
  /*************************/

  /* Returns the index of this node within its parent */
  public int index() {

    if( _parent != null ) {
      for( int i=0; i<_parent.children.length; i++ ) {
        if( this == _parent.children.index( i ) ) {
          return( i );
        }
      }
    }

    return( -1 );

  }

  /* Adds a child to this node */
  public void add_child( Node child, int index = -1 ) {

    if( index < 0 ) {
      _children.append_val( child );
    } else {
      children.insert_val( index, child );
    }

    child.parent = this;

    var prev = child.get_previous_node();

    child.depth  = this.depth + 1;
    child.x      = 0;
    child.y      = (prev == null) ? 0 : prev.last_y;

    /* Re-draw all nodes */
    child.adjust_nodes( child.last_y, false, "add_child" );

    /* Update the list type values */
    set_list_types();

  }

  /* Removes the child at the given index from this node */
  public void remove_child( Node node ) {

    var prev  = node.get_previous_node();
    var index = node.index();

    node.adjust_nodes( ((prev == null) ? 0 : prev.last_y), true, "remove_child" );
    children.remove_index( index );
    node.parent = null;

    /* Update the list type values */
    set_list_types();

  }

  /* Expands the next unexpanded level of hierachy */
  public void expand_next( Array<Node> nodes ) {
    if( !is_leaf() ) {
      if( !expanded ) {
        _expanded = true;
        nodes.append_val( this );
      } else {
        for( int i=0; i<children.length; i++ ) {
          children.index( i ).expand_next( nodes );
        }
      }
    }
  }

  /* Expand all of the nodes within this node tree */
  public void expand_all( Array<Node> nodes ) {
    if( !expanded ) {
      _expanded = true;
      nodes.append_val( this );
    }
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).expand_all( nodes );
    }
  }

  /* Calculate the maximum depth that is not collapsedd */
  private void get_collapse_next_depth( ref int max_depth ) {
    if( !is_leaf() ) {
      if( expanded ) {
        if( depth > max_depth ) {
          max_depth = depth;
        }
        for( int i=0; i<children.length; i++ ) {
          children.index( i ).get_collapse_next_depth( ref max_depth );
        }
      }
    }
  }

  /* Collapse all nodes that match the maximum depth */
  private void collapse_at_depth( int max_depth, Array<Node> nodes ) {
    if( !is_leaf() ) {
      if( depth == max_depth ) {
        _expanded = false;
        nodes.append_val( this );
      } else {
        for( int i=0; i<children.length; i++ ) {
          children.index( i ).collapse_at_depth( max_depth, nodes );
        }
      }
    }
  }

  /* Collapses the next level of hierarchy */
  public void collapse_next( Array<Node> nodes ) {
    int max_depth = depth;
    get_collapse_next_depth( ref max_depth );
    collapse_at_depth( max_depth, nodes );
  }

  /* Collapses all nodes within this node tree */
  public void collapse_all( Array<Node> nodes ) {
    if( expanded ) {
      _expanded = false;
      nodes.append_val( this );
    }
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).collapse_all( nodes );
    }
  }

  /* Returns true if the node is a root node (has no parent) */
  public bool is_root() {
    return( parent == null );
  }

  /* Returns true if the node is a leaf node (has no children) */
  public bool is_leaf() {
    return( children.length == 0 );
  }

  /* Returns true if we are a descendant of the given node */
  public bool is_descendant_of( Node node ) {
    var current = parent;
    while( !current.is_root() && (current != node) ) {
      current = current.parent;
    }
    return( current == node );
  }

  /* Set the notes display for this node and all descendant nodes */
  public void set_notes_display( bool show ) {
    if( !is_root() && (note.text.text != "") ) {
      _hide_note = !show;
      update_height( false );
    }
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).set_notes_display( show );
    }
  }

  /* Returns true if any notes are shown in this note or any descendants */
  public bool any_notes_shown() {
    if( !_hide_note ) return( true );
    for( int i=0; i<children.length; i++ ) {
      if( children.index( i ).any_notes_shown() ) {
        return( true );
      }
    }
    return( false );
  }

  /* Set the node to display in normal or condensed mode */
  public void set_condensed( bool condensed ) {
    if( !is_root() ) {
      pady = condensed ? 2 : 10;
      position_text();
      update_height( false );
    }
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).set_condensed( condensed );
    }
    if( is_root() ) {
      adjust_nodes( 0, false, "set_condensed" );
    }
  }

  /**************************/
  /* SEARCH/REPLACE METHODS */
  /**************************/

  /* Performs depth first search */
  public void do_search( string pattern ) {

    if( !is_root() ) {
      name.text.do_search( pattern );
      note.text.do_search( pattern );
    }

    for( int i=0; i<children.length; i++ ) {
      children.index( i ).do_search( pattern );
    }

  }

  /* Replaces all matched text with the given string in the specified CanvasText */
  private void replace_all_text( string str, CanvasText ct, ref UndoReplaceAll undo ) {
    var undo_text = new UndoTextReplaceAll( ct );
    ct.text.replace_all( str, ref undo_text );
    if( undo_text.starts.length > 0 ) {
      undo.add_text( undo_text );
    }
  }

  /*
   Replaces all matched text within this node and its descendants with the
   given string.
  */
  public void replace_all( string str, ref UndoReplaceAll undo ) {
    if( !is_root() ) {
      replace_all_text( str, name, ref undo );
      replace_all_text( str, note, ref undo );
    }
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).replace_all( str, ref undo );
    }
  }

  /* Changes the filter based on the given filter function */
  public void filter( NodeFilterFunc? func, ref bool one_hidden, ref bool one_shown ) {
    hidden      = (func != null) && !func( this );
    one_hidden |= _hidden;
    one_shown  |= !_hidden;
    for( int i=0; i<children.length; i++ ) {
      var child = children.index( i );
      child.filter( func, ref one_hidden, ref one_shown );
    }
  }

  /*********************/
  /* NUMBERING METHODS */
  /*********************/

  /* Sets the line type value */
  private void set_list_type() {
    int width, height;
    switch( _ot.list_type ) {
      case NodeListType.OUTLINE :  _lt_layout.set_text( ordered_item() + ".", -1 );     break;
      case NodeListType.SECTION :  _lt_layout.set_text( ordered_section() + ".", -1 );  break;
      default                   :  _lt_layout.set_text( "", -1 );                       break;
    }
    _lt_layout.get_size( out width, out height );
    _lt_width = width / Pango.SCALE;
    position_text();
    update_width();
  }

  /* Used when the associated outline table needs to change the list type of all nodes */
  public void set_list_types() {
    for( int i=0; i<children.length; i++ ) {
      var child = children.index( i );
      child.set_list_type();
      child.set_list_types();
    }
  }

  public string ordered_item() {
    switch( depth ) {
      case 1  :  return( roman_number( index() + 1 ).up() );
      case 2  :  return( letter( index() ).up() );
      default :
        switch( (depth - 3) % 3 ) {
          case 0  :  return( (index() + 1).to_string() );
          case 1  :  return( letter( index() ).down() );
          case 2  :  return( roman_number( index() + 1 ).down() );
          default :  return( "" );
        }
    }
  }

  /* Returns the Roman number to represent the given index */
  private string roman_number( int index ) {

    var      value = "";
    string[] huns  = {"", "C", "CC", "CCC", "CD", "D", "DC", "DCC", "DCCC", "CM"};
    string[] tens  = {"", "X", "XX", "XXX", "XL", "L", "LX", "LXX", "LXXX", "XC"};
    string[] ones  = {"", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"};

    while( index >= 1000 ) {
      value += "M";
      index -= 1000;
    }

    value += huns[index/100];  index = index % 100;
    value += tens[index/10];   index = index % 10;
    value += ones[index];

    return( value );

  }

  /* Returns the letter to represent the given index */
  private string letter( int index ) {

    var      value   = "";
    string[] letters = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"};

    if( index == 0 ) {
      return( "A" );
    } else {
      while( index > 0 ) {
        value = letters[index % 26] + value;
        index = index / 26;
      }
      return( value );
    }

  }

  /* Returns a section number */
  public string ordered_section() {

    if( is_root() ) return( "" );

    var value = (index() + 1).to_string();
    var node  = parent;

    while( !node.is_root() ) {
      value = (node.index() + 1).to_string() + "." + value;
      node  = node.parent;
    }

    return( value );

  }

  /*******************/
  /* DRAWING METHODS */
  /*******************/

  /* Draws the background for the given row */
  public void draw_background( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {


    var background = theme.background;
    var alpha      = this.alpha;
    var tmode      = opts.show_modes ? mode : NodeMode.NONE;

    switch( tmode ) {
      case NodeMode.SELECTED :  background = theme.nodesel_background;  alpha = 0.5;  break;
      case NodeMode.ATTACHTO :  background = theme.attachable_color;    break;
      case NodeMode.HOVER    :  background = theme.nodesel_background;  alpha = 0.1;  break;
      case NodeMode.MOVETO   :  alpha      = 0.3;                       break;
    }

    Utils.set_context_color_with_alpha( ctx, background, alpha );
    ctx.rectangle( _x, _y, _w, _h );
    ctx.fill();

    /* If we are attaching above or below this node, draw the below indicator */
    switch( tmode ) {
      case NodeMode.ATTACHABOVE :
        Utils.set_context_color( ctx, theme.attachable_color );
        ctx.rectangle( _x, (y - 4), _w, 4 );
        ctx.fill();
        break;
      case NodeMode.ATTACHBELOW :
        Utils.set_context_color( ctx, theme.attachable_color );
        ctx.rectangle( _x, (last_y - 4), _w, 4 );
        ctx.fill();
        break;
    }

  }

  /* Draw the expander icon */
  public void draw_expander( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    if( !opts.show_expander ) return;

    double ex, ey, ew, eh;
    var r     = 3;
    var lh    = name.get_line_height();
    var tmode = opts.show_modes ? mode : NodeMode.NONE;
    var color = ((tmode == NodeMode.SELECTED) || (tmode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : theme.symbol_color;

    expander_bbox( out ex, out ey, out ew, out eh );

    Utils.set_context_color_with_alpha( ctx, color, alpha );

    if( children.length == 0 ) {
      var mid = y + pady + (lh / 2);
      if( (depth % 2) == 0 ) {
        ctx.rectangle( (ex + 2), (ey + 2), 6, 6 );
      } else {
        ctx.arc( (ex + 4), mid, r, 0, (2 * Math.PI) );
      }
    } else if( expanded ) {
      ctx.move_to( ex, ey );
      ctx.line_to( (ex + 10), ey );
      ctx.line_to( (ex + 5), (ey + 8) );
      ctx.close_path();
    } else {
      ctx.move_to( ex, ey );
      ctx.line_to( (ex + 8), (ey + 5) );
      ctx.line_to( ex, (ey + 10) );
      ctx.close_path();
    }

    ctx.fill();

  }

  public void draw_depth( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    if( !opts.show_depth || !_ot.show_depth || _parent.is_root() ) return;

    Utils.set_context_color_with_alpha( ctx, theme.symbol_color, 0.5 );
    ctx.set_line_width( 1 );

    if( _ot.min_depth ) {
      var parent = this.parent;
      while( !parent.is_root() ) {
        if( parent.get_next_sibling() != null ) {
          var x = (padx * 4) + 10 + (parent.depth * indent) + (expander_size / 2);
          ctx.move_to( x, _y );
          ctx.line_to( x, (_y + _h) );
          ctx.stroke();
        }
        parent = parent.parent;
      }
    } else {
      for( int i=1; i<_depth; i++ ) {
        var x = (padx * 4) + 10 + (i * indent) + (expander_size / 2);
        ctx.move_to( x, _y );
        ctx.line_to( x, (_y + _h) );
        ctx.stroke();
      }
    }

  }

  /* Draw the task indicator */
  public void draw_task( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    if( task == NodeTaskMode.NONE ) return;

    double tx, ty, tw, th;
    var tmode = opts.show_modes ? mode : NodeMode.NONE;
    var color = ((tmode == NodeMode.SELECTED) || (tmode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : theme.symbol_color;

    task_bbox( out tx, out ty, out tw, out th );

    Utils.set_context_color_with_alpha( ctx, color, alpha );

    ctx.set_line_width( 1 );
    Utilities.cairo_rounded_rectangle( ctx, tx, ty, tw, tw, 2 );
    ctx.stroke();

    switch( task ) {
      case NodeTaskMode.DOING :
        ctx.set_line_width( 3 );
        ctx.set_line_cap( Cairo.LineCap.ROUND );
        ctx.move_to( (tx + 4), (ty + (th / 2)) );
        ctx.line_to( ((tx + tw) - 4), (ty + (th / 2)) );
        ctx.stroke();
        break;
      case NodeTaskMode.DONE :
        ctx.set_line_width( 3 );
        ctx.set_line_cap( Cairo.LineCap.ROUND );
        ctx.move_to( (tx + 3), (ty + (th / 2)) );
        ctx.line_to( (tx + (tw / 3) + 1), ((ty + th) - 4) );
        ctx.line_to( ((tx + tw) - 3), (ty + 3) );
        ctx.stroke();
        break;
    }

  }

  /* Draw the list type to the right of the expander */
  public void draw_list_type( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    if( _ot.list_type == NodeListType.NONE ) return;

    var tmode = opts.show_modes ? mode : NodeMode.NONE;
    var color = ((tmode == NodeMode.SELECTED) || (tmode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : theme.foreground;
    var nh    = name.get_line_height();
    var lh    = Utils.get_line_height( _lt_layout );

    ctx.move_to( (name.posx - (_lt_width + padx)), (name.posy + ((nh - lh) / 2)) );
    Utils.set_context_color_with_alpha( ctx, color, alpha );
    Pango.cairo_show_layout( ctx, _lt_layout );
    ctx.new_path();

  }

  /* Draw the node title */
  public void draw_name( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    var color = theme.foreground;
    var tmode = opts.show_modes ? mode : NodeMode.NONE;

    if( tmode == NodeMode.EDITABLE ) {
      Utils.set_context_color_with_alpha( ctx, theme.root_background, alpha );
      ctx.set_line_width( 1 );
      Utilities.cairo_rounded_rectangle( ctx, (name.posx - (padx / 2)), name.posy, name.max_width, name.height, 4 );
      // ctx.rectangle( (name.posx - (padx / 2)), name.posy, name.max_width, name.height );
      ctx.stroke();
    }

    _name.draw( ctx, theme, (((tmode == NodeMode.SELECTED) || (tmode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : color), alpha, opts.use_theme );

  }

  /* Draw the note icon */
  private void draw_note_icon( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    var tmode = opts.show_modes ? mode : NodeMode.NONE;

    if( !opts.show_note_icon ||
        (((tmode == NodeMode.NONE) && (note.text.text == "")) ||
         (tmode == NodeMode.ATTACHTO) ||
         (tmode == NodeMode.ATTACHBELOW) ||
         (tmode == NodeMode.ATTACHABOVE)) ) return;

    double x, y, w, h;
    double alpha = (((tmode == NodeMode.HOVER) || (tmode == NodeMode.SELECTED)) && (note.text.text == "") && !over_note_icon) ? 0.4 : this.alpha;

    note_bbox( out x, out y, out w, out h );

    initialize_note_icon();

    cairo_set_source_pixbuf( ctx, _note_icon, x, y );
    ctx.paint_with_alpha( alpha );

  }

  /* Draw the note */
  public void draw_note( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    var tmode = opts.show_modes ? mode : NodeMode.NONE;

    if( hide_note || (tmode == NodeMode.MOVETO) ) return;

    var use_select_color = (tmode == NodeMode.SELECTED) || (tmode == NodeMode.ATTACHTO);
    var bg_color         = use_select_color ? theme.nodesel_background : theme.note_background;
    var fg_color         = use_select_color ? theme.nodesel_foreground : theme.note_foreground;

    /* Draw the background color */
    if( opts.show_note_bg ) {
      Utils.set_context_color_with_alpha( ctx, bg_color, alpha );
      // ctx.rectangle( (note.posx - (padx / 2)), note.posy, note.max_width, note.height );
      Utilities.cairo_rounded_rectangle( ctx, (note.posx - (padx / 2)), note.posy, note.max_width, note.height, 4 );
      ctx.fill();
    }

    if( (tmode == NodeMode.NOTEEDIT) || opts.show_note_ol ) {
      Utils.set_context_color_with_alpha( ctx, theme.root_background, alpha );
      ctx.set_line_width( 1 );
      // ctx.rectangle( (note.posx - (padx / 2)), note.posy, note.max_width, note.height );
      Utilities.cairo_rounded_rectangle( ctx, (note.posx - (padx / 2)), note.posy, note.max_width, note.height, 4 );
      ctx.stroke();
    }

    _note.draw( ctx, theme, fg_color, alpha, opts.use_theme );

  }

  /* Draw the node to the screen */
  public void draw( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    var tmode = opts.show_modes ? mode : NodeMode.NONE;

    if( (is_root() && (tmode != NodeMode.MOVETO)) || hidden ) return;

    draw_background( ctx, theme, opts );
    draw_note_icon( ctx, theme, opts );
    draw_expander( ctx, theme, opts );
    draw_depth( ctx, theme, opts );
    draw_task( ctx, theme, opts );
    draw_list_type( ctx, theme, opts );
    draw_name( ctx, theme, opts );
    draw_note( ctx, theme, opts );

  }

  /* Draws the entire node tree */
  public void draw_tree( Cairo.Context ctx, Theme theme, NodeDrawOptions opts ) {

    draw( ctx, theme, opts );

    if( expanded ) {
      for( int i=0; i<children.length; i++ ) {
        children.index( i ).draw_tree( ctx, theme, opts );
      }
    }

  }

}
