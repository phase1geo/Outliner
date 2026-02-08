/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Outliner)
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

using GLib;

public class ExportODT : Export {

  //-------------------------------------------------------------
  // Constructor
  public ExportODT() {
    base( "odt", _( "ODT" ), {".odt"}, true, false, false );
  }

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name
  public override bool export( string fname, OutlineTable table ) {
    return( export_with_pandoc( fname, table ) );
  }

}
