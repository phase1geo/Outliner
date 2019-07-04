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
        if( parent != null ) {
          var last = get_last_node();
          var diff = (last.y + last._h) - (y + _h);
          parent.adjust_nodes( diff, (index() + 1) );
        }
      } else if( !value && _expanded ) {
        if( parent != null ) {
          var last = get_last_node();
          var diff = 0 - ((last.y + last._h) - (y + _h));
          parent.adjust_nodes( diff, (index() + 1) );
        }
        _expanded = value;
      }
    }
  }
  public double      alpha    { get; set; default = 1.0; }
  public double      padx     { get; set; default = 5; }
  public double      pady     { get; set; default = 5; }
  public double      indent   { get; set; default = 20; }
  public Node?       parent   { get; set; default = null; }
  public Array<Node> children { get; set; default = new Array<Node>(); }

  /* Constructor */
  public Node( DrawingArea da ) {

    _name = new CanvasText( da, _w );
    _name.resized.connect( update_size );

    _note = new CanvasText( da, _w );
    _note.resized.connect( update_size );

    position_name();

  }

  /* Updates the size of this node */
  private void update_size() {

    var orig_height = _h;

    _h = (padx * 2) + _name.height;

    if( _note.text != "" ) {
      _h += padx + _note.height;
    }

    if( orig_height != _h ) {
      adjust_nodes( (_h - orig_height) );
    }

  }

  /* Adjusts the posy value of all of the nodes displayed below this node */
  private void adjust_nodes( double diff, int child_start = 0 ) {

    adjust_descendants( diff, child_start );

    if( parent != null ) {
      parent.adjust_nodes( diff, (index() + 1) );
    }

  }

  /* Adjusts the posy value of all nodes that are descendants of the give node */
  private void adjust_descendants( double diff, int child_start ) {

    for( int i=child_start; i<children.length; i++ ) {
      children.index( i ).y += diff;
      children.index( i ).adjust_descendants( diff, 0 );
    }

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
  private Node? get_last_node() {
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

    return( Utils.is_within_bounds( x, y, (this.x + padx + (depth * indent)), (this.y + pady), 10, 10 ) );

  }

  /* Returns true if the given coordinates lie within the attach area */
  public bool is_within_attach( double x, double y ) {

    return( Utils.is_within_bounds( x, y, this.x, (this.y + 4), width, ((this.y + _h) - 4) ) );

  }

  /*************************/
  /* FILE HANDLING METHODS */
  /*************************/

  /* Saves the current node and its children in XML Outliner format */
  public Xml.Node* save() {

    Xml.Node* n = new Xml.Node( null, "node" );

    n->new_prop( "expanded", expanded.to_string() );

    n->new_text_child( null, "name", name.text );
    n->new_text_child( null, "note", note.text );

    for( int i=0; i<children.length; i++ ) {
      n->add_child( children.index( i ).save() );
    }

    return( n );

  }

  /* Loads the current node and its children from XML Outliner format */
  public void load( DrawingArea da, Xml.Node* n ) {

    string? e = n->get_prop( "expanded" );
    if( e != null ) {
      expanded = bool.parse( e );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "name"  :  load_name( it );  break;
          case "note"  :  load_note( it );  break;
          case "node"  :
            {
              var child = new Node( da );
              child.load( da, it );
              add_child( child );
            }
            break;
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

    Node last;

    if( index < 0 ) {
      last = get_last_node();
      _children.append_val( child );
    } else {
      if( index == 0 ) {
        last = this;
      } else {
        last = children.index( index - 1 ).get_last_node();
      }
      children.insert_val( index, child );
    }

    child.parent = this;
    child.depth  = this.depth + 1;
    child.y      = last.y + last._h;

    child.adjust_nodes( child._h );

  }

  /* Removes the child at the given index from this node */
  public void remove_child( Node node ) {

    node.adjust_nodes( 0 - node._h );

    node.parent = null;
    children.remove_index( node.index() );

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
      ctx.rectangle( _x, ((_y + _h) - 4), _w, 4 );
      ctx.fill();
    }

  }

  /* Draw the expander icon */
  private void draw_expander( Cairo.Context ctx, Theme theme ) {

    /* We won't draw the expander if we have no children */
    if( children.length == 0 ) return;

    double x = _x + padx + (depth * indent);
    double y = _y + pady;

    Utils.set_context_color_with_alpha( ctx, theme.foreground, alpha );

    ctx.move_to( x, y );

    if( expanded ) {
      ctx.line_to( (x + 10), y );
      ctx.line_to( (x + 5), (y + 10) );
    } else {
      ctx.line_to( (x + 10), (y + 5) );
      ctx.line_to( x, (y + 10) );
    }

    ctx.close_path();
    ctx.fill();

  }

  /* Draw the node title */
  private void draw_name( Cairo.Context ctx, Theme theme ) {

    _name.draw( ctx, theme, theme.foreground, alpha );

  }

  /* Draw the node to the screen */
  private void draw( Cairo.Context ctx, Theme theme ) {

    draw_background( ctx, theme );
    draw_expander( ctx, theme );
    draw_name( ctx, theme );

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
