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

public class NodeLabels {

  private const int    _num_nodes = 9;
  private Array<Node?> _nodes;

  /* Constructor */
  public NodeLabels() {
    _nodes      = new Array<Node?>();
    _nodes.data = {null, null, null, null, null, null, null, null, null};
  }

  /* Returns true if there is at least one label available */
  public bool label_available() {
    var in_use = 0;
    for( int i=0; i<_num_nodes; i++ ) {
      in_use += (_nodes.index( i ) != null) ? 1 : 0;
    }
    return( in_use < _num_nodes );
  }

  /* Sets the given label to the specified node */
  public void set_label( Node? node, int label ) {
    if( label < 0 ) return;
    assert( label < _num_nodes );
    if( node != null ) {
      var prev_label = get_label_for_node( node );
      if( prev_label != -1 ) {
        set_label( null, prev_label );
      }
    }
    _nodes.data[label] = node;
  }

  /* Sets the given node to the next available label */
  public void set_next_label( Node node ) {
    var prev_label = get_label_for_node( node );
    if( prev_label != -1 ) return;
    for( int i=0; i<_num_nodes; i++ ) {
      if( _nodes.data[i] == null ) {
        _nodes.data[i] = node;
        return;
      }
    }
  }

  /* Removes all labels */
  public void clear_all() {
    for( int i=0; i<_num_nodes; i++ ) {
      _nodes.data[i] = null;
    }
  }

  /* Returns the node associated with the label if one exists; otherwise, returns null */
  public Node? get_node( int label ) {
    return( _nodes.index( label ) );
  }

  /*
   Returns label specified for the given node, if it exists; otherwise,
   returns -1.
  */
  public int get_label_for_node( Node node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == node ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Save the labels to the XML file */
  public Xml.Node* save() {
    Xml.Node* labels = new Xml.Node( null, "labels" );
    for( int i=0; i<_num_nodes; i++ ) {
      if( _nodes.index( i ) != null ) {
        Xml.Node* label = new Xml.Node( null, "label" );
        label->new_prop( "index", i.to_string() );
        label->new_prop( "node", _nodes.index( i ).lookup_id() );
        labels->add_child( label );
      }
    }
    return( labels );
  }

  private void load_label( OutlineTable ot, Xml.Node* lbl ) {
    var index = 0;
    var i     = lbl->get_prop( "index" );
    if( i != null ) {
      index = int.parse( i );
    }
    var n = lbl->get_prop( "node" );
    if( n != null ) {
      set_label( ot.root.get_node_by_lookup_id( n ), index );
    }
  }

  /* Loads the labels */
  public void load( OutlineTable ot, Xml.Node* n ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "label") ) {
        load_label( ot, it );
      }
    }
  }

  /* Draws the label on the canvas to the left of its node */
  private void draw_label( Cairo.Context ctx, int label, Theme theme ) {

    Cairo.TextExtents extents;
    ctx.set_font_size( 12 );
	  ctx.text_extents( label.to_string(), out extents );
	
    var node = _nodes.index( label );

    double nx, ny, nw, nh;
    node.note_bbox( out nx, out ny, out nw, out nh );

    var cx = (nx - node.padx) - (nw / 2);
    var cy = ny + (nh / 2);
    var tx = cx - (extents.width / 2) - 1;
    var ty = ny + ((nh - extents.height) / 2) + extents.height;

    /* Display the label shape */
    Utils.set_context_color_with_alpha( ctx, theme.foreground, node.alpha );
    ctx.arc( cx, cy, (nw / 2), 0, (2 * Math.PI) );
    ctx.fill();

    /* Display the label text */
    Utils.set_context_color_with_alpha( ctx, theme.background, node.alpha );
    ctx.move_to( tx, ty );
    ctx.show_text( (label + 1).to_string() );

  }

  /* Draws the labels on the specifed context */
  public void draw( Cairo.Context ctx, Theme theme ) {
    for( int i=0; i<_num_nodes; i++ ) {
      if( _nodes.index( i ) != null ) {
        draw_label( ctx, i, theme );
      }
    }
  }

}
