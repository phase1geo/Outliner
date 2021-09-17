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

public class UndoTitleChange : UndoItem {

  private CanvasText _orig_text;
  private CanvasText _new_text;

  /* Default constructor */
  public UndoTitleChange( OutlineTable ot, CanvasText orig_text ) {
    base( _( "document title change" ) );
    _orig_text = new CanvasText( ot, 0 );
    _new_text  = new CanvasText( ot, 0 );
    _orig_text.copy( orig_text );
    _new_text.copy( ot.title );
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    table.tagger.preedit_load_tags( table.title.text );
    table.title.copy( _orig_text );
    table.tagger.postedit_load_tags( table.title.text );
    table.queue_draw();
    table.changed();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    table.tagger.preedit_load_tags( table.title.text );
    table.title.copy( _new_text );
    table.tagger.postedit_load_tags( table.title.text );
    table.queue_draw();
    table.changed();
  }

}
