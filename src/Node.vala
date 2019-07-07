/*
* Copyright (c) 2019 (https://github.com/phase1geo/Outliner)
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

public enum NodeMode {
  NONE = 0,      // Indicates that this node is nothing special
  SELECTED,      // Selects the node to perform an action on
  ATTACHTO,      // Shows the node as something that can be attached as a child
  ATTACHBELOW,   // Shows the node as something that can be attached as a sibling
  MOVETO,        // Indicates that the node is being dragged by the user
  EDITABLE       // Indicates that the node text is being edited
}

public class Node {

  private CanvasText  _name;
  private NodeMode    _mode     = NodeMode.NONE;
  private CanvasText? _note     = null;
  private double      _x        = 0;
  private double      _y        = 0;
  private double      _w        = 500;
  private double      _h        = 80;
  private int         _depth    = 0;
  private bool        _expanded = true;

  /* Properties */
  public NodeMode mode {
    get {
      return( _mode );
    }
    set {
      _mode = value;
      name.edit = (_mode == NodeMode.EDITABLE);
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
      position_name();
    }
  }
  public double y {
    get {
      return( _y );
    }
    set {
      _y = value;
      position_name();
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
      if( value && !_expanded ) {
        _expanded = value;
        adjust_nodes( last_y, false );
      } else if( !value && _expanded ) {
        _expanded = value;
        adjust_nodes( last_y, false );
      }
    }
  }
  public double      alpha    { get; set; default = 1.0; }
  public double      padx     { get; set; default = 5; }
  public double      pady     { get; set; default = 5; }
  public double      indent   { get; set; default = 20; }
  public Node?       parent   { get; set; default = null; }
  public Array<Node> children { get; set; default = new Array<Node>(); }
  public double      last_y   { get { return( _y + _h ); } }

  /* Constructor */
  public Node( OutlineTable ot ) {

    var name_fd = new Pango.FontDescription();
    name_fd.set_size( 12 * Pango.SCALE );

    var note_fd = new Pango.FontDescription();
    note_fd.set_size( 10 * Pango.SCALE );

    _name = new CanvasText( ot, ot.get_allocated_width() );
    _name.resized.connect( update_height );
    _name.set_font( name_fd );

    _note = new CanvasText( ot, ot.get_allocated_width() );
    _note.resized.connect( update_height );
    _note.set_font( note_fd );

    position_name();
    update_width( ot.get_allocated_width() );

    /* Detect any size changes by the drawing area */
    ot.size_allocate.connect( table_size_changed );
    ot.zoom_changed.connect( table_zoom_changed );

  }

  /* Called whenever the canvas width changes */
  private void table_size_changed( Allocation alloc ) {
    update_width( alloc.width );
  }

  /* Updates the size of the name and note information */
  private void table_zoom_changed( int name_size, int note_size, int pady ) {
    _name.set_font_size( name_size );
    _note.set_font_size( note_size );
    this.pady = (double)pady;
  }

  /* Called whenever the canvas width changes */
  private void update_width( double width ) {

    if( _w == width ) return;

    _w = width;
    _name.max_width = _w - _name.posx;
    _note.max_width = _w - _note.posx;

  }

  /* Updates the size of this node */
  private void update_height() {

    var orig_height = _h;

    _h = (pady * 2) + _name.height;

    if( (_note != null) && (_note.text != "") ) {
      _h += pady + _note.height;
    }

    if( orig_height != _h ) {
      adjust_nodes( last_y, false );
    }

  }

  /* Adjusts the posy value of all of the nodes displayed below this node */
  public double adjust_nodes( double last_y, bool deleted, int child_start = 0 ) {

    if( expanded && !deleted ) {
      last_y = adjust_descendants( last_y, child_start );
    }

    if( parent != null ) {
      last_y = parent.adjust_nodes( last_y, false, (index() + 1) );
    }

    return( last_y );

  }

  /* Adjusts the posy value of all nodes that are descendants of the give node */
  private double adjust_descendants( double last_y, int child_start ) {
    for( int i=child_start; i<children.length; i++ ) {
      var child = children.index( i );
      child.y = last_y;
      last_y  = child.adjust_descendants( child.last_y, 0 );
    }
    return( last_y );
  }

  /* Adjusts the position of the text object */
  private void position_name() {
    name.posx = x + (padx * 2) + (depth * indent) + 10;
    name.posy = y + pady;
  }

  /* Returns the root node of this node */
  public Node get_root_node() {
    var parent = _parent;
    var root   = this;;
    while( parent != null ) {
      root = parent;
      parent = parent.parent;
    }
    return( root );
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
    if( index == -1 ) {
      return( null );
    } else if( index == 0 ) {
      return( parent );
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

  /* Returns the node within this tree that contains the given coordinates */
  public Node? get_containing_node( double x, double y ) {
    if( is_within( x, y ) ) {
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

  /* Returns true if the given coordinates are within this node */
  public bool is_within( double x, double y ) {
    return( Utils.is_within_bounds( x, y, this.x, this.y, width, _h ) );
  }

  /* Returns true if the given coordinates lie within the expander */
  public bool is_within_expander( double x, double y ) {
    if( !is_leaf() ) {
      var lh   = name.get_line_height();
      var mody = this.y + ((lh - 6) / 2);
      return( Utils.is_within_bounds( x, y, (this.x + padx + (depth * indent)), (mody + pady), 10, 10 ) );
    }
    return( false );
  }

  /* Returns true if the given coordinates lie within the attach area */
  public bool is_within_attach( double x, double y ) {
    return( Utils.is_within_bounds( x, y, this.x, this.y, width, (_h - 8) ) );
  }

  /*************************/
  /* FILE HANDLING METHODS */
  /*************************/

  /* Saves the current node and its children in XML Outliner format */
  public Xml.Node* save() {

    Xml.Node* n = new Xml.Node( null, "node" );

    n->new_prop( "expanded", expanded.to_string() );
    n->new_text_child( null, "name", name.text );

    if( note.text != "" ) {
      n->new_text_child( null, "note", note.text );
    }

    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    for( int i=0; i<children.length; i++ ) {
      nodes->add_child( children.index( i ).save() );
    }

    n->add_child( nodes );

    return( n );

  }

  /* Loads the current node and its children from XML Outliner format */
  public void load( OutlineTable ot, Xml.Node* n ) {

    string? e = n->get_prop( "expanded" );
    if( e != null ) {
      expanded = bool.parse( e );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "name"  :  load_name( it );  break;
          case "note"  :  load_note( it );  break;
          case "nodes" :  load_nodes( ot, it );  break;
        }
      }
    }

  }

  /* Loads the node name */
  private void load_name( Xml.Node* n ) {

    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      name.text = n->children->get_content();
    }

  }

  /* Loads the node name */
  private void load_note( Xml.Node* n ) {

    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      note.text = n->children->get_content();
    }

  }

  /* Loads the given child node information */
  private void load_nodes( OutlineTable ot, Xml.Node* n ) {

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        var child = new Node( ot );
        add_child( child );
        child.load( ot, it );
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

    child.adjust_nodes( child.last_y, false );

  }

  /* Removes the child at the given index from this node */
  public void remove_child( Node node ) {

    var prev = node.get_previous_node();

    node.adjust_nodes( ((prev == null) ? 0 : prev.last_y), true );
    children.remove_index( node.index() );
    node.parent = null;

  }

  /* Expand all of the nodes within this node tree */
  public void expand_all() {

    expanded = true;

    for( int i=0; i<children.length; i++ ) {
      children.index( i ).expand_all();
    }

  }

  /* Collapses all nodes within this node tree */
  public void collapse_all() {

    expanded = false;

    for( int i=0; i<children.length; i++ ) {
      children.index( i ).collapse_all();
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

  /*******************/
  /* DRAWING METHODS */
  /*******************/

  /* Draws the background for the given row */
  private void draw_background( Cairo.Context ctx, Theme theme ) {


    RGBA   background = theme.background;
    double alpha      = this.alpha;
    
    switch( mode ) {
      case NodeMode.SELECTED :  background = theme.nodesel_background;  break;
      case NodeMode.ATTACHTO :  background = theme.attachable_color;    break;
      case NodeMode.MOVETO   :  alpha      = 0.3;                       break;
    }

    Utils.set_context_color_with_alpha( ctx, background, alpha );

    ctx.rectangle( _x, _y, _w, _h );
    ctx.fill();

    /* If we are attaching below this node, draw the below indicator */
    if( mode == NodeMode.ATTACHBELOW ) {
      Utils.set_context_color( ctx, theme.attachable_color );
      ctx.rectangle( _x, (last_y - 4), _w, 4 );
      ctx.fill();
    }

  }

  /* Draw the expander icon */
  private void draw_expander( Cairo.Context ctx, Theme theme ) {

    /* Don't draw the expander if we are moving a node */
    if( mode == NodeMode.MOVETO ) return;

    var x  = _x + padx + (depth * indent);
    var y  = _y + pady;
    var r  = 2;
    var lh = name.get_line_height();

    Utils.set_context_color_with_alpha( ctx, theme.symbol_color, alpha );

    if( children.length == 0 ) {
      var mid = y + (lh / 2);
      ctx.arc( (x + 4), mid, r, 0, (2 * Math.PI) );
    } else if( expanded ) {
      var mody = y + ((lh - 6) / 2);
      ctx.move_to( x, mody );
      ctx.line_to( (x + 8), mody );
      ctx.line_to( (x + 4), (mody + 6) );
      ctx.close_path();
    } else {
      var mody = y + ((lh - 6) / 2);
      ctx.move_to( x, mody );
      ctx.line_to( (x + 6), (mody + 4) );
      ctx.line_to( x, (mody + 8) );
      ctx.close_path();
    }

    ctx.fill();

  }

  /* Draw the node title */
  private void draw_name( Cairo.Context ctx, Theme theme ) {

    _name.draw( ctx, theme, (((mode == NodeMode.SELECTED) || (mode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : theme.foreground), alpha );

  }

  /* Draw the note */
  private void draw_note( Cairo.Context ctx, Theme theme ) {

    if( _note.text != "" ) {
      _note.draw( ctx, theme, (((mode == NodeMode.SELECTED) || (mode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : theme.note_color), alpha );
    }

  }

  /* Draw the node to the screen */
  public void draw( Cairo.Context ctx, Theme theme ) {

    draw_background( ctx, theme );
    draw_expander( ctx, theme );
    draw_name( ctx, theme );
    draw_note( ctx, theme );

  }

  /* Draws the entire node tree */
  public void draw_tree( Cairo.Context ctx, Theme theme ) {
    draw( ctx, theme );
    if( expanded ) {
      for( int i=0; i<children.length; i++ ) {
        children.index( i ).draw_tree( ctx, theme );
      }
    }
  }

}
