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
  ATTACHABOVE,   // Shows the node as something that can be attached as a sibling above
  ATTACHBELOW,   // Shows the node as something that can be attached as a sibling below
  MOVETO,        // Indicates that the node is being dragged by the user
  EDITABLE,      // Indicates that the node text is being edited
  NOTEEDIT,      // Indicates that the note text is being edited
  HOVER          // Indicates that the cursor is hovering over this node
}

public class Node {

  private static int next_id = 0;

  private OutlineTable _ot;
  private int          _id        = next_id++;
  private CanvasText   _name;
  private CanvasText   _note;
  private NodeMode     _mode      = NodeMode.NONE;
  private double       _x         = 0;
  private double       _y         = 40;
  private double       _w         = 500;
  private double       _h         = 80;
  private int          _depth     = 0;
  private bool         _expanded  = true;
  private bool         _hide_note = true;

  private static Image _note_icon = null;

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
      if( _mode != value ) {
        var note_was_edited = _mode == NodeMode.NOTEEDIT;
        _mode = value;
        name.edit = (_mode == NodeMode.EDITABLE);
        note.edit = (_mode == NodeMode.NOTEEDIT);
        if( !note.edit && note_was_edited && (note.text.text == "") ) {
          hide_note = true;
        }
        update_height();
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
      if( value != _expanded ) {
        _expanded = value;
        adjust_nodes_all( last_y, false );
      }
    }
  }
  public bool hide_note {
    get {
      return( _hide_note );
    }
    set {
      if( value != _hide_note ) {
        _hide_note = value;
        update_height();
        adjust_nodes_all( last_y, false );
      }
    }
  }
  public double      alpha     { get; set; default = 1.0; }
  public double      padx      { get; set; default = 10; }
  public double      pady      { get; set; default = 10; }
  public double      indent    { get; set; default = 25; }
  public Node?       parent    { get; set; default = null; }
  public Array<Node> children  { get; set; default = new Array<Node>(); }
  public double      last_y    { get { return( _y + _h ); } }

  /* Constructor */
  public Node( OutlineTable ot ) {

    _ot = ot;

    var name_fd = new Pango.FontDescription();
    name_fd.set_size( 12 * Pango.SCALE );

    var note_fd = new Pango.FontDescription();
    note_fd.set_size( 10 * Pango.SCALE );

    _name = new CanvasText( ot, ot.get_allocated_width() );
    _name.resized.connect( update_height );
    _name.select_mode.connect( name_select_mode );
    _name.cursor_changed.connect( name_cursor_changed );
    _name.set_font( name_fd );

    _note = new CanvasText( ot, ot.get_allocated_width() );
    _note.resized.connect( update_height );
    _note.select_mode.connect( note_select_mode );
    _note.cursor_changed.connect( note_cursor_changed );
    _note.set_font( note_fd );

    position_name();
    update_width( (int)ot.get_allocated_width() );

    /* Detect any size changes by the drawing area */
    ot.win.configure_event.connect( window_size_changed );
    ot.zoom_changed.connect( table_zoom_changed );
    ot.theme_changed.connect( table_theme_changed );

  }

  /* Copy constructor */
  public Node.from_node( OutlineTable ot, Node node ) {

    _ot = ot;

    var name_fd = new Pango.FontDescription();
    name_fd.set_size( 12 * Pango.SCALE );

    var note_fd = new Pango.FontDescription();
    note_fd.set_size( 10 * Pango.SCALE );

    _name = new CanvasText( ot, ot.get_allocated_width() );
    _name.resized.connect( update_height );
    _name.select_mode.connect( name_select_mode );
    _name.cursor_changed.connect( name_cursor_changed );
    _name.set_font( name_fd );
    _name.copy( node.name );

    _note = new CanvasText( ot, ot.get_allocated_width() );
    _note.resized.connect( update_height );
    _note.select_mode.connect( note_select_mode );
    _note.cursor_changed.connect( note_cursor_changed );
    _note.set_font( note_fd );
    _note.copy( node.note );

    position_name();
    update_width( (int)ot.get_allocated_width() );

    /* Detect any size changes by the drawing area */
    ot.win.configure_event.connect( window_size_changed );
    ot.zoom_changed.connect( table_zoom_changed );
    ot.theme_changed.connect( table_theme_changed );

  }

  /* Destructor */
  ~Node() {
    _ot.zoom_changed.disconnect( table_zoom_changed );
  }

  /* If the window size changes, adjust our width */
  private bool window_size_changed( EventConfigure e ) {
    int w, h;
    _ot.win.get_size( out w, out h );
    update_width( w );
    return( false );
  }

  /* Updates the size of the name and note information */
  private void table_zoom_changed( int name_size, int note_size, int pady ) {
    _name.set_font_size( name_size );
    _note.set_font_size( note_size );
    this.pady = (double)pady;
  }

  /*
   If the theme has changed, all we need to do is alert the CanvasText to
   rerender the text.
  */
  private void table_theme_changed( Theme theme ) {
    _name.update_size( false );
    _note.update_size( false );
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

  /* Called whenever the canvas width changes */
  private void update_width( int width ) {

    /* Update our width information */
    _w = width;
    _name.max_width = _w - (_name.posx * 2);
    _note.max_width = _w - (_note.posx * 2);

  }

  /* Updates the size of this node */
  private void update_height() {

    var orig_height = _h;

    _h = (pady * 2) + _name.height;

    if( !_hide_note && (mode != NodeMode.MOVETO) ) {
      _h += pady + _note.height;
    }

    if( orig_height != _h ) {
      adjust_nodes_all( last_y, false );
      _ot.see( this );
    }

  }

  /* Adjusts all of the nodes in the document */
  public void adjust_nodes_all( double last_y, bool deleted, int child_start = 0 ) {
    last_y = adjust_nodes( last_y, deleted, child_start );
    _ot.adjust_nodes( get_root_node(), last_y, deleted );
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
    if( expanded ) {
      for( int i=child_start; i<children.length; i++ ) {
        var child = children.index( i );
        child.y = last_y;
        last_y  = child.adjust_descendants( child.last_y, 0 );
      }
    }
    return( last_y );
  }

  /* Adjusts the position of the text object */
  private void position_name() {
    name.posx = note.posx = x + (padx * 5) + (depth * indent) + 36;
    name.posy = y + pady;
    note.posy = y + (pady * 2) + name.height;
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
      return( _ot.get_previous_node( this ) );
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
      return( _ot.get_next_node( child ) );
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

  /* Returns the area where we will draw the note icon */
  private void note_bbox( out double x, out double y, out double w, out double h ) {
    x = this.x + (padx * 2) + 10;
    y = this.y + pady + ((name.get_line_height() / 2) - 8);
    w = 16;
    h = 16;
  }

  /* Returns the area where the expander will draw the expander icon */
  private void expander_bbox( out double x, out double y, out double w, out double h ) {
    x = this.x + (padx * 4) + 26 + (depth * indent);
    y = this.y + pady + ((name.get_line_height() / 2) - 5);
    w = 10;
    h = 10;
  }

  /* Returns true if the given coordinates are within this node */
  public bool is_within( double x, double y ) {
    return( Utils.is_within_bounds( x, y, this.x, this.y, width, _h ) );
  }

  /* Returns true if the given coordinates lie within the expander */
  public bool is_within_expander( double x, double y ) {
    if( !is_leaf() ) {
      double ex, ey, ew, eh;
      expander_bbox( out ex, out ey, out ew, out eh );
      return( Utils.is_within_bounds( x, y, ex, ey, ew, eh ) );
    }
    return( false );
  }

  /* Returns true if the given coordinates reside within the note icon boundaries */
  public bool is_within_note_icon( double x, double y ) {
    double nx, ny, nw, nh;
    note_bbox( out nx, out ny, out nw, out nh );
    return( Utils.is_within_bounds( x, y, nx, ny, nw, nh ) );
  }

  /* Returns true if the given coordinates reside within the name text area */
  public bool is_within_name( double x, double y ) {
    return( Utils.is_within_bounds( x, y, name.posx, name.posy, _w, name.height ) );
  }

  /* Returns true if the given coordinates reside within the note text area */
  public bool is_within_note( double x, double y ) {
    return( Utils.is_within_bounds( x, y, note.posx, note.posy, _w, note.height ) );
  }

  /* Returns true if the given coordinates lie within the attachto area */
  public bool is_within_attachto( double x, double y ) {
    return( Utils.is_within_bounds( x, y, this.x, (this.y + 4), width, (_h - 8) ) );
  }

  /* Returns true if the given coordinates lie within the attachabove area */
  public bool is_within_attachabove( double x, double y ) {
    return( Utils.is_within_bounds( x, y, this.x, this.y, width, 4 ) );
  }

  /*************************/
  /* FILE HANDLING METHODS */
  /*************************/

  /* Saves the current node and its children in XML Outliner format */
  public Xml.Node* save() {

    Xml.Node* n = new Xml.Node( null, "node" );

    n->new_prop( "expanded", expanded.to_string() );
    n->new_prop( "hidenote", hide_note.to_string() );

    n->add_child( name.save( "name" ) );

    if( note.text.text != "" ) {
      n->add_child( note.save( "note" ) );
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

    string? h = n->get_prop( "hidenote" );
    if( h != null ) {
      hide_note = bool.parse( h );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "name"  :  name.load( it );  break;
          case "note"  :  note.load( it );  break;
          case "nodes" :  load_nodes( ot, it );  break;
        }
      }
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

    child.adjust_nodes_all( child.last_y, false );

  }

  /* Removes the child at the given index from this node */
  public void remove_child( Node node ) {

    var prev = node.get_previous_node();

    node.adjust_nodes_all( ((prev == null) ? 0 : prev.last_y), true );
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

  /* Set the notes display for this node and all descendant nodes */
  public void set_notes_display( bool show ) {
    _hide_note = !show;
    if( note.text.text != "" ) {
      update_height();
    }
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).set_notes_display( show );
    }
  }

  /**************************/
  /* SEARCH/REPLACE METHODS */
  /**************************/

  /* Performs depth first search */
  public void do_search( string pattern ) {

    name.text.do_search( pattern );
    note.text.do_search( pattern );

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
    replace_all_text( str, name, ref undo );
    replace_all_text( str, note, ref undo );
    for( int i=0; i<children.length; i++ ) {
      children.index( i ).replace_all( str, ref undo );
    }
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

    /* If we are attaching above or below this node, draw the below indicator */
    switch( mode ) {
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
  private void draw_expander( Cairo.Context ctx, Theme theme ) {

    /* Don't draw the expander if we are moving a node */
    if( mode == NodeMode.MOVETO ) return;

    double ex, ey, ew, eh;
    var r  = 3;
    var lh = name.get_line_height();

    expander_bbox( out ex, out ey, out ew, out eh );

    Utils.set_context_color_with_alpha( ctx, theme.symbol_color, alpha );

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

  /* Draw the node title */
  private void draw_name( Cairo.Context ctx, Theme theme ) {

    RGBA color = theme.foreground;

    if( mode == NodeMode.EDITABLE ) {
      Utils.set_context_color_with_alpha( ctx, theme.root_background, alpha );
      ctx.set_line_width( 1 );
      ctx.rectangle( (name.posx - (padx / 2)), name.posy, name.max_width, name.height );
      ctx.stroke();
    }

    _name.draw( ctx, theme, (((mode == NodeMode.SELECTED) || (mode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : color), alpha );

  }

  private void draw_note_icon( Cairo.Context ctx, Theme theme ) {

    if( (mode == NodeMode.MOVETO) || ((_note.text.text == "") && (mode != NodeMode.HOVER) && (mode != NodeMode.SELECTED) && (mode != NodeMode.NOTEEDIT)) ) return;

    double x, y, w, h;
    double alpha = (((mode == NodeMode.HOVER) || (mode == NodeMode.SELECTED)) && (note.text.text == "")) ? 0.3 : this.alpha;

    note_bbox( out x, out y, out w, out h );

    var pixbuf = new Pixbuf.from_resource( "/com/github/phase1geo/outliner/images/accessories-text-editor-symbolic" );

    cairo_set_source_pixbuf( ctx, pixbuf, x, y );
    ctx.paint_with_alpha( alpha );

  }

  /* Draw the note */
  private void draw_note( Cairo.Context ctx, Theme theme ) {

    if( hide_note || (mode == NodeMode.MOVETO) ) return;

    if( mode == NodeMode.NOTEEDIT ) {
      Utils.set_context_color_with_alpha( ctx, theme.root_background, alpha );
      ctx.set_line_width( 1 );
      ctx.rectangle( (note.posx - (padx / 2)), note.posy, note.max_width, note.height );
      ctx.stroke();
    }

    _note.draw( ctx, theme, (((mode == NodeMode.SELECTED) || (mode == NodeMode.ATTACHTO)) ? theme.nodesel_foreground : theme.note_color), alpha );

  }

  /* Draw the node to the screen */
  public void draw( Cairo.Context ctx, Theme theme ) {

    draw_background( ctx, theme );
    draw_note_icon( ctx, theme );
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
