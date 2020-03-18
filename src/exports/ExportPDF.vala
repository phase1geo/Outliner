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

using Cairo;

public class ExportPDF : Object {

  /* Default constructor */
  public static void export( string fname, OutlineTable table ) {

    /* Get the width and height of the page */
    double page_width  = 8.5 * 72;
    double page_height = 11  * 72;
    double margin      = 0.5 * 72;

    /* Create the drawing surface */
    var surface = new PdfSurface( fname, page_width, page_height );
    var context = new Context( surface );

    /* Calculate the required scaling factor to get the document to fit */
    double width  = (page_width  - (2 * margin)) / table.get_allocated_width();
    double height = (page_height - (2 * margin)) / table.get_allocated_height();
    double sf     = (width < height) ? width : height;

    /* Scale and translate the image */
    context.scale( sf, sf );
    context.translate( margin, margin );

    /* Recreate the image */
    table.draw_all( context );

    /* Draw the page to the PDF file */
    context.show_page();

  }

}
