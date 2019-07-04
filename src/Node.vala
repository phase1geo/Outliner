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
  MOVETO         // Indicates that the node is being dragged by the user
}

public class Node {

  private CanvasText  _name;
  private CanvasText? _note     = null;
  private double      _x        = 0;
  private double      _y        = 0;
  private double      _w        = 500;
  private double      _h        = 80;
  private int         _depth    = 0;

  /* Properties */
  public NodeMode mode { get; set; default = NodeMode.NONE; }
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
  public bool        expanded { get; set; default = true; }
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

  }

  /* Updates the size of this node */
  private void update_size() {

    _h = (padx * 2) + _name.height;

    if( _note.text != "" ) {
      _h += padx + _note.height;
    }

  }

  /* Adjusts the position of the text object */
  private void position_name() {

    name.posx = x + (padx * 2) + (depth * indent) + 10;
    name.posy = y + pady;

  }

  /* Returns the node within this tree that contains the given coordinates */
  public Node? get_containing_node( double x, double y ) {
    if( is_within( x, y ) ) {
      return( this );
    } else {
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

    if( index < 0 ) {
      _children.append_val( child );
    } else {
      _children.insert_val( index, child );
    }

    child.parent = this;
    child.depth  = this.depth + 1;

  }

  /* Removes the child at the given index from this node */
  public void remove_child( Node node ) {

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
