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

public class UndoTextReplaceAll {
  public CanvasText         text;
  public Array<UndoTagInfo> tags;
  public UndoTextReplaceAll( CanvasText text ) {
    this.text = text;
    this.tags = new Array<UndoTagInfo>();
  }
  public void add_tags( Array<UndoTagInfo> tags ) {
    this.tags.append_vals( tags, tags.length );
  }
}

public class UndoReplaceAll : UndoItem {

  public string                    search_text  { private set; get; }
  public string                    replace_text { private set; get; }
  public Array<UndoTextReplaceAll> texts        { private set; get; }

  /* Default constructor */
  public UndoReplaceAll( string search_text, string replace_text ) {
    base( _( "replace all" ) );
    this.search_text  = search_text;
    this.replace_text = replace_text;
    this.texts        = new Array<UndoTextReplaceAll>();
  }

  /* Adds a given text */
  public void add_text( UndoTextReplaceAll text ) {
    texts.append_val( text );
  }

  private void replace( CanvasText ct, string remove_text, string add_text, Array<UndoTagInfo> tags ) {
    var remove_chars = remove_text.char_count();
    for( int i=0; i<tags.length; i++ ) {
      var tag = tags.index( i );
      ct.text.replace_text( tag.start, remove_chars, add_text );
    }
    if( add_text == search_text ) {
      ct.text.apply_tags( tags );
    }
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    for( int i=0; i<texts.length; i++ ) {
      var ti = texts.index( i );
      replace( ti.text, replace_text, search_text, ti.tags );
    }
    table.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    for( int i=0; i<texts.length; i++ ) {
      var ti = texts.index( i );
      replace( ti.text, search_text, replace_text, ti.tags );
    }
    table.queue_draw();
  }

}
