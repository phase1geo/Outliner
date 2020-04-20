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

public class UndoNodeUnclone : UndoItem {

  private Node          _node;
  private NodeCloneData _clone_data;
  private NodeCloneData _unclone_data;

  /* Default constructor */
  public UndoNodeUnclone( Node node, NodeCloneData clone_data ) {
    base( _( "unclone item" ) );
    _node         = node;
    _clone_data   = clone_data;
    _unclone_data = node.get_clone_data();
  }

  public override void undo( OutlineTable table ) {
    _node.reclone( _clone_data );
    table.queue_draw();
    table.changed();
  }

  public override void redo( OutlineTable table ) {
    _node.reclone( _unclone_data );
    table.queue_draw();
    table.changed();
  }

}
