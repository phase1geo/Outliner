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
  public Array<int>         starts;
  public Array<UndoTagInfo> tags;
  public UndoTextReplaceAll( CanvasText text ) {
    this.text   = text;
    this.starts = new Array<int>();
    this.tags   = new Array<UndoTagInfo>();
  }
  public void add_tags( int start, Array<UndoTagInfo> tags ) {
    this.starts.append_val( start );
    this.tags.append_vals( tags, tags.length );
    stdout.printf( "In add_tags, tags: %u\n", this.tags.length );
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

  private void replace( UndoTextReplaceAll utra, string remove_text, string add_text ) {
    var remove_chars = remove_text.char_count();
    stdout.printf( "Replace, remove_chars: %d, add_text: %s\n", remove_chars, add_text );
    for( int i=0; i<utra.starts.length; i++ ) {
      utra.text.text.replace_text( utra.starts.index( i ), remove_chars, add_text );
    }
    if( add_text == search_text ) {
      stdout.printf( "Applying tags: %u\n", utra.tags.length );
      utra.text.text.apply_tags( utra.tags );
    }
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( OutlineTable table ) {
    for( int i=0; i<texts.length; i++ ) {
      var ti = texts.index( i );
      replace( ti, replace_text, search_text );
    }
    table.queue_draw();
    table.changed();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( OutlineTable table ) {
    for( int i=0; i<texts.length; i++ ) {
      var ti = texts.index( i );
      replace( ti, search_text, replace_text );
    }
    table.queue_draw();
    table.changed();
  }

}
