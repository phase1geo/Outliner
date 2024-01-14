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

using Gtk;
using Gdk;
using Cairo;
using Gee;

/*
 Returns true if the given node meets a condition that should cause it to be
 displayed; otherwise, the node will be hidden.
*/
public delegate bool NodeFilterFunc( Node node );

public enum FontTarget {
  NAME,  /* Specifies that the font changes target all node names */
  NOTE,  /* Specifies that the font changes target all node notes */
  TITLE  /* Specifies that the font changes the document title */
}

public class OutlineTable : DrawingArea {

  private const double dim_selected   = 0.3;
  private const double dim_unselected = 0.1;

  private Cursor          click_cursor = new Cursor.from_name( "hand2", null );
  private Cursor          text_cursor  = new Cursor.from_name( "text", null );

  private MainWindow      _win;
  private Document        _doc;
  private int             _width;
  private Node?           _selected = null;
  private Node?           _active   = null;
  private bool            _active_to_select;
  private double          _press_x;
  private double          _press_y;
  private double          _motion_x;
  private double          _motion_y;
  private bool            _pressed    = false;
  private int             _press_type = 0;
  private bool            _motion     = false;
  private Theme           _theme;
  private IMMulticontext  _im_context;
  private double          _scroll_adjust = -1;
  private string?         _hilite_color  = null;
  private string?         _font_color    = null;
  private FormatBar?      _format_bar    = null;
  private bool?           _show_format   = null;
  private CanvasText      _orig_text;
  private CanvasText      _orig_title    = null;
  private Node?           _move_parent   = null;
  private int             _move_index    = -1;
  private NodeMenu        _node_menu;
  private bool            _condensed     = false;
  private bool            _debug         = true;
  private NodeDrawOptions _draw_options;
  private NodeListType    _list_type     = NodeListType.NONE;
  private Node            _clone         = null;
  private NodeLabels      _labels;
  private string          _title_family;
  private int             _title_size;
  private string          _name_family;
  private int             _name_size;
  private string          _note_family;
  private int             _note_size;
  private bool            _show_tasks = false;
  private bool            _show_depth = true;
  private bool            _min_depth  = false;
  private Tagger          _tagger;
  private TextCompletion  _completion;
  private bool            _markdown;
  private bool            _parse_urls;
  private bool            _blank_rows;
	private bool            _auto_sizing;
	private int             _auto_size_depth = 1;
  private bool            _filtered   = false;
  private Node?           _focus_node = null;
  private bool            _in_focus_exit = false;
  private CanvasText?     _title         = null;
  private bool            _control_set = false;
  private bool            _shift_set   = false;
  private EventControllerKey _key_controller;

  public MainWindow     win         { get { return( _win ); } }
  public Document       document    { get { return( _doc ); } }
  public UndoBuffer     undo_buffer { get; set; }
  public UndoTextBuffer undo_text   { get; set; }
  public CanvasText     title {
    get {
      return( _title );
    }
  }
  public int width {
    get {
      return( _width );
    }
  }
  public Node? selected {
    get {
      return( _selected );
    }
    set {
      if( _selected != value ) {
        if( _selected != null ) {
          set_node_mode( _selected, NodeMode.NONE );
          _selected.select_mode.disconnect( select_mode_changed );
          _selected.cursor_changed.disconnect( selected_cursor_changed );
          if( (_focus_node != null) && (_selected != _focus_node) && !_selected.is_descendant_of( _focus_node ) ) {
            _selected.alpha = dim_unselected;
          }
        }
        if( value != null ) {
          see( value );
        }
        _selected = value;
        if( _selected != null ) {
          set_node_mode( _selected, NodeMode.SELECTED );
          _selected.select_mode.connect( select_mode_changed );
          _selected.cursor_changed.connect( selected_cursor_changed );
          if( (_focus_node != null) && (_selected != _focus_node) && !_selected.is_descendant_of( _focus_node ) ) {
            _selected.alpha = dim_selected;
          }
        }
        selected_changed();
      }
    }
  }
  public Node root { private set; get; }
  public string? hilite_color {
    get {
      return( _hilite_color );
    }
    set {
      _hilite_color = value;
      update_css();
    }
  }
  public string? font_color {
    get {
      return( _font_color );
    }
    set {
      _font_color = value;
      update_css();
    }
  }
  public bool condensed {
    get {
      return( _condensed );
    }
    set {
      if( _condensed != value ) {
        _condensed = value;
        root.set_condensed( value );
        queue_draw();
      }
    }
  }
  public NodeListType list_type {
    get {
      return( _list_type );
    }
    set {
      if( _list_type != value ) {
        _list_type = value;
        root.set_list_types();
        queue_draw();
        changed();
      }
    }
  }
  public NodeLabels labels {
    get {
      return( _labels );
    }
  }
  public string? title_font_family {
    get {
      return( (_title_family == "") ? null : _title_family );
    }
  }
  public int title_font_size {
    get {
      return( _title_size );
    }
  }
  public string? name_font_family {
    get {
      return( (_name_family == "") ? null : _name_family );
    }
  }
  public int name_font_size {
    get {
      return( _name_size );
    }
  }
  public string? note_font_family {
    get {
      return( (_note_family == "") ? null : _note_family );
    }
  }
  public int note_font_size {
    get {
      return( _note_size );
    }
  }
  public bool show_tasks {
    get {
      return( _show_tasks );
    }
    set {
      if( _show_tasks != value ) {
        _show_tasks = value;
        show_tasks_changed();
        queue_draw();
        changed();
      }
    }
  }
  public bool show_depth {
    get {
      return( _show_depth );
    }
    set {
      if( _show_depth != value ) {
        _show_depth = value;
        queue_draw();
        changed();
      }
    }
  }
  public bool min_depth {
    get {
      return( _min_depth );
    }
  }
  public bool markdown {
    get {
      return( _markdown );
    }
    set {
      if( _markdown != value ) {
        _markdown   = value;
        if( _format_bar != null ) {
          hide_format_bar();
          _format_bar = null;
          show_format_bar();
        }
        markdown_changed();
        queue_draw();
        changed();
      }
    }
  }
  public bool parse_urls {
    get {
      return( _parse_urls );
    }
    set {
      if( _parse_urls != value ) {
        _parse_urls = value;
        parse_urls_changed();
        queue_draw();
        changed();
      }
    }
  }
  public bool blank_rows {
    get {
      return( _blank_rows );
    }
    set {
      if( _blank_rows != value ) {
        _blank_rows = value;
        queue_draw();
        changed();
      }
    }
  }
	public bool auto_sizing {
		get {
			return( _auto_sizing );
		}
		set {
			if( _auto_sizing != value ) {
				_auto_sizing = value;
        auto_size_changed();
				queue_draw();
				changed();
			}
		}
	}
	public int auto_size_depth {
		get {
			return( _auto_size_depth );
		}
	}
  public Tagger tagger {
    get {
      return( _tagger );
    }
  }
  public int top_margin      { get; private set; default = 45; }
  public bool tasks_on_right { get; private set; default = true; }

  /* Allocate static parsers */
  public MarkdownParser markdown_parser { get; private set; }
  public TaggerParser   tagger_parser   { get; private set; }
  public UnicodeParser  unicode_parser  { get; private set; }
  public UrlParser      url_parser      { get; private set; }

  /* Called by this class when a change is made to the table */
  public signal void changed();
  public signal void zoom_changed();
  public signal void theme_changed();
  public signal void selected_changed();
  public signal void cursor_changed();
  public signal void show_tasks_changed();
  public signal void markdown_changed();
  public signal void parse_urls_changed();
  public signal void auto_size_changed();
  public signal void focus_mode( string? msg );
  public signal void nodes_filtered( string? msg );
  public signal void width_changed();

  /* Default constructor */
  public OutlineTable( MainWindow win, GLib.Settings settings ) {

    _win = win;

    /* Create the document for this table */
    _doc = new Document( this, settings );

    /* Create the root node */
    root = new Node.root( this );

    /* Create contextual menu(s) */
    _node_menu = new NodeMenu( win.application, this );

    /* Create the node draw options */
    _draw_options = new NodeDrawOptions();

    /* Create the labels */
    _labels = new NodeLabels();

    /* Create the tags */
    _tagger = new Tagger( this );

    /* Create the parsers */
    tagger_parser   = new TaggerParser( this );
    markdown_parser = new MarkdownParser( this );
    unicode_parser  = new UnicodeParser( this );
    url_parser      = new UrlParser();

    /* Create text completion */
    _completion = new TextCompletion( this );

    /* Set the style context */
    get_style_context().add_class( "canvas" );

    /* Initialize font and other property information from gsettings */
    _title_family    = settings.get_string( "default-title-font-family" );
    _name_family     = settings.get_string( "default-row-font-family" );
    _note_family     = settings.get_string( "default-note-font-family" );
    _title_size      = settings.get_int( "default-title-font-size" );
    _name_size       = settings.get_int( "default-row-font-size" );
    _note_size       = settings.get_int( "default-note-font-size" );
    _show_tasks      = settings.get_boolean( "default-show-tasks" );
    _show_depth      = settings.get_boolean( "default-show-depth" );
    _markdown        = settings.get_boolean( "default-markdown-enabled" );
    _blank_rows      = settings.get_boolean( "enable-blank-rows" );
		_auto_sizing     = settings.get_boolean( "enable-auto-sizing" );
		_auto_size_depth = settings.get_int( "auto-sizing-depth" );
    tasks_on_right   = settings.get_boolean( "checkboxes-on-right" );
    _min_depth       = settings.get_boolean( "minimum-depth-line-display" );
    _parse_urls      = settings.get_boolean( "auto-parse-embedded-urls" );

    /* Handle any changes made to the settings that we don't want to poll on */
    settings.changed.connect(() => {
      tasks_on_right = settings.get_boolean( "checkboxes-on-right" );
      _min_depth     = settings.get_boolean( "minimum-depth-line-display" );
      parse_urls     = settings.get_boolean( "auto-parse-embedded-urls" );
      if( root.children.length > 0 ) {
        root.children.index( 0 ).y = get_top_row_y();
        root.children.index( 0 ).adjust_nodes( root.children.index( 0 ).last_y, false, "gsettings changed" );
      }
      show_tasks_changed();
      queue_draw();
    });

    /* Set the default theme */
    var init_theme = MainWindow.themes.get_theme( settings.get_string( "default-theme" ) );
    _hilite_color = Utils.color_from_rgba( init_theme.hilite );
    set_theme( init_theme );

    /* Allocate memory for the canvas text prior to editing for undo purposes */
    _orig_text = new CanvasText( this, 0 );
    _orig_title = new CanvasText( this, 0 );

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );
    undo_text   = new UndoTextBuffer( this );

    /* Add event listeners */
    _key_controller = new EventControllerKey();
    var pri_click_controller = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };
    var sec_click_controller = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    var motion_controller = new EventControllerMotion();

    this.add_controller( _key_controller );
    this.add_controller( pri_click_controller );
    this.add_controller( sec_click_controller );
    this.add_controller( motion_controller );

    _key_controller.key_pressed.connect( on_keypress );
    _key_controller.key_released.connect( on_keyrelease );

    pri_click_controller.pressed.connect( on_primary_press );
    pri_click_controller.released.connect( on_release );
    sec_click_controller.pressed.connect( on_secondary_press );
    motion_controller.motion.connect( on_motion );

    this.set_draw_func( on_draw );

    /* Make sure the drawing area can receive keyboard focus */
    this.can_focus = true;
    this.focusable = true;

    /* Make sure that we us the IMMulticontext input method when editing text only */
    _im_context = new IMMulticontext();
    _im_context.set_client_widget( this );
    _im_context.set_use_preedit( false );
    _im_context.commit.connect( handle_im_commit );
    _im_context.retrieve_surrounding.connect( handle_im_retrieve_surrounding );
    _im_context.delete_surrounding.connect( handle_im_delete_surrounding );
    _key_controller.set_im_context( _im_context );

  }

  /* Attempts to get the size of the outline table */
  public override void size_allocate( int width, int height, int baseline ) {
    _width = width;
    window_size_changed();
    see_internal();
    width_changed();
  }

  /* Called whenever the selection mode changed of the current node */
  private void select_mode_changed( bool name, bool mode ) {
    _show_format = mode;
  }

  /* Called whenever the cursor changes position in the current node */
  private void selected_cursor_changed( bool name ) {
    cursor_changed();
  }

  /* Called whenever we want to change the current selected node's mode */
  public void set_node_mode( Node? node, NodeMode mode ) {
    if( node == null ) return;
    if( node.mode != mode ) {
      if( (node.mode == NodeMode.EDITABLE) && undo_text.undoable() ) {
        undo_buffer.add_item( new UndoNodeName( this, node, _orig_text ) );
        undo_text.clear();
        undo_text.ct = null;
        _im_context.focus_out();
      } else if( (node.mode == NodeMode.NOTEEDIT) && undo_text.undoable() ) {
        undo_buffer.add_item( new UndoNodeNote( this, node, _orig_text ) );
        undo_text.clear();
        undo_text.ct = null;
        _im_context.focus_out();
      }
      if( mode == NodeMode.EDITABLE ) {
        _orig_text.copy( node.name );
        undo_text.ct = node.name;
      } else if( mode == NodeMode.NOTEEDIT ) {
        _orig_text.copy( node.note );
        undo_text.ct = node.note;
      }
      if( (mode == NodeMode.EDITABLE) || (mode == NodeMode.NOTEEDIT) ) {
        if( node.mode != mode ) {
          update_im_cursor( (mode == NodeMode.EDITABLE) ? node.name : node.note );
          // _im_context.commit.connect( handle_im_commit );
          _im_context.focus_in();
          if( mode == NodeMode.EDITABLE ) {
            _tagger.preedit_load_tags( node.name.text );
          }
          set_title_editable( false );
        }
      } else if( (node.mode == NodeMode.EDITABLE) || (node.mode == NodeMode.NOTEEDIT) ) {
        if( node.mode == NodeMode.EDITABLE ) {
          _tagger.postedit_load_tags( node.name.text );
        }
        _im_context.focus_out();
        // _im_context.commit.disconnect( handle_im_commit );
      }
      node.mode = mode;
    }
  }

  /* Called whenever we want to change the editable nature of the document title */
  public void set_title_editable( bool edit ) {
    if( _title == null )  return;
    if( _title.edit != edit ) {
      if( _title.edit && undo_text.undoable() ) {
        undo_buffer.add_item( new UndoTitleChange( this, _orig_title ) );
        undo_text.clear();
        undo_text.ct = null;
        _im_context.focus_out();
        changed();
      }
      if( edit ) {
        _orig_title.copy( _title );
        undo_text.ct = _title;
        update_im_cursor( _title );
        _im_context.focus_in();
        _tagger.preedit_load_tags( _title.text );
        set_node_mode( selected, NodeMode.NONE );
      } else {
        _tagger.postedit_load_tags( _title.text );
        _im_context.focus_out();
      }
      _title.edit = edit;
    }
  }

  /* Returns the y position of the first row in the table (excluding the title) */
  public double get_top_row_y() {
    return( (_title != null) ? (_title.posy + _title.height + 10) : top_margin );
  }

  public void get_window_ys( out int top, out int bottom ) {
    var vp = parent.parent as Viewport;
    var vh = vp.get_allocated_height();
    var sw = parent.parent.parent as ScrolledWindow;
    top    = (int)sw.vadjustment.value;
    bottom = top + vh;
  }

  /* Updates the IM context cursor location based on the canvas text position */
  private void update_im_cursor( CanvasText ct ) {
    int top, bottom;
    get_window_ys( out top, out bottom );
    Gdk.Rectangle rect = {(int)ct.posx, ((int)ct.posy - top), 0, (int)ct.height};
    _im_context.set_cursor_location( rect );
  }

  /* Make sure that the given node is fully in view */
  public void see( Node node ) {
    if( root.children.length == 0 ) return;
    int y1, y2;
    int x, ytop, ybot;
    var vp = parent.parent as Viewport;
    var vh = vp.get_allocated_height();
    get_window_ys( out y1, out y2 );
    if( (y2 - y1) <= 1 ) return;
    switch( node.mode ) {
      case NodeMode.EDITABLE :
        node.name.get_cursor_pos( out x, out ytop, out ybot );
        break;
      case NodeMode.NOTEEDIT :
        node.note.get_cursor_pos( out x, out ytop, out ybot );
        break;
      default :
        ytop = (int)node.y;
        ybot = (int)node.last_y;
        break;
    }
    if( ytop < y1 ) {
      _scroll_adjust = (double)ytop;
    } else if( ybot > y2 ) {
      _scroll_adjust = (double)ybot - vh;
    }
    if( ybot <= get_allocated_height() ) {
      see_internal();
    }
  }

  /*
   Resizes this table such that the last row can be positioned at the top
   of the window.
  */
  public bool resize_table() {

    var last_node = root.get_last_node();
    var last_y    = (int)last_node.last_y;
    var vp        = parent.parent as Viewport;
    var vh        = vp.get_allocated_height();
    var end_y     = (last_y > ((int)last_node.y + vh)) ? last_y : ((int)last_node.y + vh);

    set_size_request( -1, end_y );

    return( false );

  }

  /* Positions the scrolled window such that the given node is placed at the top */
  public void place_at_top( Node node ) {
    var sw = parent.parent.parent as ScrolledWindow;
    sw.vadjustment.value = node.y;
  }

  /* Internal see command that is called after this has been resized */
  private void see_internal() {
    if( _scroll_adjust == -1 ) return;
    var sw = parent.parent.parent as ScrolledWindow;
    sw.vadjustment.value = _scroll_adjust;
    _scroll_adjust = -1;
  }

  /* Returns true if the currently selected node is in the selected state */
  public bool is_node_selected() {
    return( (selected != null) && (selected.mode == NodeMode.SELECTED) );
  }

  /* Returns true if the currently selected node is editable */
  public bool is_node_editable() {
    return( (selected != null) && (selected.mode == NodeMode.EDITABLE) );
  }

  /* Returns true if the currently selected note is editable */
  public bool is_note_editable() {
    return( (selected != null) && (selected.mode == NodeMode.NOTEEDIT) );
  }

  /* Returns true if the title is editable */
  public bool is_title_editable() {
    return( (_title != null) && _title.edit );
  }

  /* Returns true if the currently selected node is joinable */
  public bool is_node_joinable() {
    return( is_node_selected() && (selected.get_previous_node() != null) );
  }

  /* Returns true if the currently selected node is editable and has text selected */
  private bool is_node_text_selected() {
    return( is_node_editable() && selected.name.is_selected() );
  }

  /* Returns true if the currently selected note is editable and has text selected */
  private bool is_note_text_selected() {
    return( is_note_editable() && selected.note.is_selected() );
  }

  /* Returns the node at the given coordinates */
  private Node? node_at_coordinates( double x, double y ) {
    return( root.get_containing_node( x, y ) );
  }

  /* Called when the given coordinates are clicked within a CanvasText item. */
  private bool clicked_in_text( int n_press, double x, double y, Node clicked, CanvasText text, NodeMode select_mode ) {

    var tag   = FormatTag.URL;
    var extra = "";

    /* Set the selected node to the clicked node */
    selected = clicked;

    /*
     If the mouse click was within a URL and the control key was pressed, open
     the URL in an external application.
    */
    if( _control_set && text.is_within_clickable( x, y, out tag, out extra ) ) {
      _active = clicked;
      switch( tag ) {
        case FormatTag.URL :  Utils.open_url( extra );       break;
        case FormatTag.TAG :  _tagger.tag_clicked( extra );  break;
        default            :  break;
      }
      return( false );
    }

    /* Sets the selected mode */
    set_node_mode( selected, select_mode );

    /* Set the cursor or selection */
    switch( n_press ) {
      case 1  :  text.set_cursor_at_char( x, y, _shift_set );  break;
      case 2  :  text.set_cursor_at_word( x, y, _shift_set );  break;
      case 3  :  text.set_cursor_all( false );                 break;
      default :  break;
    }

    return( true );

  }

  /* Selects the node at the given coordinates */
  private bool set_current_at_position( int n_press, double x, double y ) {

    var clicked = node_at_coordinates( x, y );;

    _active           = null;
    _active_to_select = false;

    if( clicked != null ) {
      if( clicked.is_within_expander( x, y ) ) {
        _active = clicked;
        return( false );
      } else if( clicked.is_within_note_icon( x, y ) ) {
        _active = clicked;
        return( false );
      } else if( clicked.is_within_task( x, y ) ) {
        _active = clicked;
        return( false );
      } else if( clicked.is_within_name( x, y ) ) {
        return( clicked_in_text( n_press, x, y, clicked, clicked.name, NodeMode.EDITABLE ) );
      } else if( clicked.is_within_note( x, y ) ) {
        return( clicked_in_text( n_press, x, y, clicked, clicked.note, NodeMode.NOTEEDIT ) );
      } else {
        _active           = clicked;
        _active_to_select = true;
      }
    } else if( _title.is_within( x, y ) ) {
      set_title_editable( true );
      switch( n_press ) {
        case 1  :  _title.set_cursor_at_char( x, y, _shift_set );  break;
        case 2  :  _title.set_cursor_at_word( x, y, _shift_set );  break;
        case 3  :  _title.set_cursor_all( false );                 break;
        default :  break;
      }
    } else {
      selected = null;
    }

    return( true );

  }

  /* Changes the name font of the document to the given value */
  private void change_name_font( string? family = null, int? size = null ) {
    if( family != null ) {
      _name_family = family;
    }
    if( size != null ) {
      _name_size = size;
    }
    root.change_name_font( family, size );
    queue_draw();
    changed();
  }

  /* Changes the note font of the document to the given value */
  private void change_note_font( string? family = null, int? size = null ) {
    if( family != null ) {
      _note_family = family;
    }
    if( size != null ) {
      _note_size = size;
    }
    root.change_note_font( family, size );
    queue_draw();
    changed();
  }

  /* Changes the note font of the document to the given value */
  private void change_title_font( string? family = null, int? size = null ) {
    if( family != null ) {
      _title_family = family;
    }
    if( size != null ) {
      _title_size = size;
    }
    var zoom_factor = win.get_zoom_factor();
    _title.set_font( family, size, zoom_factor );
    queue_draw();
    changed();
  }

  /* Called to change the font of the given type */
  public void change_font( FontTarget target, string? family = null, int? size = null ) {
    switch( target ) {
      case FontTarget.NAME  :  change_name_font( family, size );  break;
      case FontTarget.NOTE  :  change_note_font( family, size );  break;
      case FontTarget.TITLE :  change_title_font( family, size );  break;
    }
  }

  /* Changes the text selection for the specified canvas text element */
  private void change_selection( CanvasText ct, double x, double y ) {
    switch( _press_type ) {
      case 1  :  ct.set_cursor_at_char( x, y, true );  break;
      case 2  :  ct.set_cursor_at_word( x, y, true );  break;
      default :  break;
    }
    queue_draw();
  }

  /* Handle primary button press event */
  private void on_primary_press( int n_press, double x, double y ) {

    grab_focus();

    _press_x    = x;
    _press_y    = y;
    _pressed    = set_current_at_position( n_press, x, y );
    _press_type = n_press;
    _motion     = false;
    queue_draw();

    /* Update the format bar display */
    update_format_bar( "on_press" );

  }

  /* Handle a secondary button press event */
  private void on_secondary_press( int n_press, double x, double y ) {

    /* Display the contextual menu */
    show_contextual_menu();

    /* Update the format bar display */
    update_format_bar( "on_press" );

  }

  /* Handle mouse motion */
  private void on_motion( double ex, double ey ) {

    _motion   = true;
    _motion_x = ex;
    _motion_y = ey;

    /* Handles the focus on exit button */
    var prev_in_focus_exit = _in_focus_exit;
    _in_focus_exit = false;

    if( is_within_focus_exit( ex, ey ) ) {
      _in_focus_exit = true;
      set_tooltip_markup( Utils.tooltip_with_accel( _( "Exit Focus Mode" ), "F2" ) );
      queue_draw();
    } else if( prev_in_focus_exit ) {
      set_tooltip_markup( null );
      queue_draw();
    }

    if( _pressed ) {

      /* If we are moving a clicked row for the first time, handle it */
      if( _active_to_select && (_active != null) ) {
        selected          = _active;
        _move_parent      = selected.parent;
        _move_index       = selected.index();
        _active           = null;
        _active_to_select = false;
        set_node_mode( selected, NodeMode.MOVETO );
        selected.parent.remove_child( selected );
      }

      if( selected != null ) {

        /* If we are dragging out a text selection, handle it here */
        if( (selected.mode == NodeMode.EDITABLE) || (selected.mode == NodeMode.NOTEEDIT) ) {
          change_selection( ((selected.mode == NodeMode.EDITABLE) ? selected.name : selected.note), ex, ey );

        /* Otherwise, we are moving the current node */
        } else {
          selected.y = ey;
          var current = node_at_coordinates( ex, ey );
          if( current != null ) {
            if( current.is_within_attachto( ex, ey ) ) {
              set_node_mode( current, NodeMode.ATTACHTO );
              selected.depth = current.depth + 1;
            } else if( current.is_within_attachabove( ex, ey ) ) {
              set_node_mode( current, NodeMode.ATTACHABOVE );
              var prev_node = current.get_previous_node();
              selected.depth = (prev_node != null) ? prev_node.depth : 0;
            } else {
              set_node_mode( current, NodeMode.ATTACHBELOW );
              selected.depth = current.depth;
            }
            if( current != _active ) {
              if( _active != null ) {
                set_node_mode( _active, NodeMode.NONE );
              }
              _active = current;
            }
          }
          queue_draw();
        }

      }

    } else {

      var tag   = FormatTag.URL;
      var extra = "";

      /* Get the current node */
      var current = node_at_coordinates( ex, ey );

      /* Check the location of the cursor and update the UI appropriately */
      if( current != null ) {
        var orig_over = current.over_note_icon;
        current.over_note_icon = false;
        set_tooltip_markup( null );
        if( current.is_within_note_icon( ex, ey ) ) {
          current.over_note_icon = true;
          set_tooltip_markup( current.hide_note ? _( "Show note" ) : _( "Hide note" ) );
          set_cursor( null );
        } else if( current.is_within_expander( ex, ey ) ) {
          if( current.children.length > 0 ) {
            set_tooltip_markup( _( "%u subrows" ).printf( current.children.length ) );
          }
        } else if( current.is_within_task( ex, ey ) ) {
          set_cursor( click_cursor );
        } else if( current.is_within_name( ex, ey ) ) {
          if( _control_set && !is_node_editable() && current.name.is_within_clickable( ex, ey, out tag, out extra ) ) {
            set_cursor( click_cursor );
            if( tag == FormatTag.URL ) {
              set_tooltip_markup( extra );
            }
          } else {
            set_cursor( text_cursor );
          }
        } else if( current.is_within_note( ex, ey ) ) {
          if( _control_set && !is_note_editable() && current.note.is_within_clickable( ex, ey, out tag, out extra ) && (tag == FormatTag.URL) ) {
            set_cursor( click_cursor );
            set_tooltip_markup( extra );
          } else {
            set_cursor( text_cursor );
          }
        } else {
          set_cursor( null );
        }
        if( orig_over != current.over_note_icon ) {
          queue_draw();
        }
      } else if( (_title != null) && _title.is_within( ex, ey ) ) {
        set_cursor( text_cursor );
      } else {
        set_cursor( null );
      }

      /* If the current node is not the active node, set the mode to HOVER */
      if( current != _active ) {
        if( (_active != null) && (_active != selected) ) {
          _active.over_note_icon = false;
          set_node_mode( _active, NodeMode.NONE );
        }
        if( (current != selected) && (current != null) ) {
          set_node_mode( current, NodeMode.HOVER );
        }
        _active = current;
        queue_draw();
      }

    }

  }

  /* Handles the release of the mouse button */
  private void on_release( int n_press, double x, double y ) {

    if( _pressed ) {

      /* Handles a click on the focus mode exit button */
      if( _in_focus_exit ) {
        _in_focus_exit = false;
        win.action_focus_mode();
      }

      /* Handle a node move */
      if( _motion ) {
        if( _active != null ) {
          switch( _active.mode ) {
            case NodeMode.ATTACHTO :
              _active.add_child( selected );
              undo_buffer.add_item( new UndoNodeMove( selected, _move_parent, _move_index ) );
              break;
            case NodeMode.ATTACHABOVE :
              _active.parent.add_child( selected, _active.index() );
              undo_buffer.add_item( new UndoNodeMove( selected, _move_parent, _move_index ) );
              break;
            case NodeMode.ATTACHBELOW :
              _active.parent.add_child( selected, (_active.index() + 1) );
              undo_buffer.add_item( new UndoNodeMove( selected, _move_parent, _move_index ) );
              break;
          }
          set_node_mode( selected, NodeMode.SELECTED );
          set_node_mode( _active, NodeMode.NONE );
          _active           = null;
          _active_to_select = false;
          queue_draw();
          changed();
        } else if( selected.mode == NodeMode.MOVETO ) {
          _move_parent.add_child( selected, _move_index );
          set_node_mode( selected, NodeMode.SELECTED );
          queue_draw();
          changed();
        }
      } else if( _active != null ) {
        selected = _active;
        queue_draw();
      }

    } else {

      /* If the user clicked in an expander, toggle the expander */
      if( !_motion ) {
        if( _active != null ) {
          if( _active.is_within_expander( x, y ) ) {
            toggle_expand( _active );
          } else if( _active.is_within_note_icon( x, y ) ) {
            if( _control_set ) {
              toggle_notes( _active );
            } else {
              toggle_note( _active, true );
            }
          } else if( _active.is_within_task( x, y ) ) {
            _active.task = (_active.task == NodeTaskMode.OPEN) ? NodeTaskMode.DONE : NodeTaskMode.OPEN;
            queue_draw();
            changed();
          }
        }
      }

    }

    /* Update the format bar state */
    update_format_bar( "on_release" );

    _pressed = false;

  }

  /*
   Returns true if the following key was found to be pressed (regardless of
   keyboard layout).
  */
  private bool has_key( uint[] kvs, uint key ) {
    foreach( uint kv in kvs ) {
      if( kv == key ) return( true );
    }
    return( false );
  }

  /* Handles keypress events */
  private bool on_keypress( uint keyval, uint keycode, ModifierType state ) {

    /* Figure out which modifiers were used */
    var control    = (bool)(state & ModifierType.CONTROL_MASK);
    var shift      = (bool)(state & ModifierType.SHIFT_MASK);
    var nomod      = !(control || shift);
    KeymapKey[] ks = {};
    uint[] kvs     = {};

    Display.get_default().map_keycode( keycode, out ks, out kvs );

    /* If there is a current node or connection selected, operate on it */
    if( (selected != null) || is_title_editable() ) {
      if( control ) {
        if( !shift && has_key( kvs, Key.c ) )              { do_copy(); }
        else if( !shift && has_key( kvs, Key.x ) )         { do_cut(); }
        else if( !shift && has_key( kvs, Key.v ) )         { do_paste( false ); }
        else if(  shift && has_key( kvs, Key.V ) )         { do_paste( true ); }
        else if( has_key( kvs, Key.Return ) )              { handle_control_return( shift ); }
        else if( has_key( kvs, Key.Tab ) )                 { handle_control_tab(); }
        else if( has_key( kvs, Key.Right ) )               { handle_control_right( shift ); }
        else if( has_key( kvs, Key.Left ) )                { handle_control_left( shift ); }
        else if( has_key( kvs, Key.Up ) )                  { handle_control_up( shift ); }
        else if( has_key( kvs, Key.Down ) )                { handle_control_down( shift ); }
        else if( has_key( kvs, Key.Home ) )                { handle_control_home( shift ); }
        else if( has_key( kvs, Key.End ) )                 { handle_control_end( shift ); }
        else if( has_key( kvs, Key.BackSpace ) )           { handle_control_backspace(); }
        else if( has_key( kvs, Key.Delete ) )              { handle_control_delete(); }
        else if( !shift && has_key( kvs, Key.period ) )    { handle_control_period(); }
        else if( !shift && has_key( kvs, Key.slash ) )     { handle_control_slash(); }
        else if( !shift && has_key( kvs, Key.@1 ) )        { handle_control_number( 0 ); }
        else if( !shift && has_key( kvs, Key.@2 ) )        { handle_control_number( 1 ); }
        else if( !shift && has_key( kvs, Key.@3 ) )        { handle_control_number( 2 ); }
        else if( !shift && has_key( kvs, Key.@4 ) )        { handle_control_number( 3 ); }
        else if( !shift && has_key( kvs, Key.@5 ) )        { handle_control_number( 4 ); }
        else if( !shift && has_key( kvs, Key.@6 ) )        { handle_control_number( 5 ); }
        else if( !shift && has_key( kvs, Key.@7 ) )        { handle_control_number( 6 ); }
        else if( !shift && has_key( kvs, Key.@8 ) )        { handle_control_number( 7 ); }
        else if( !shift && has_key( kvs, Key.@9 ) )        { handle_control_number( 8 ); }
        else if(  shift && has_key( kvs, Key.A ) )         { handle_control_a( true ); }
        else if(  shift && has_key( kvs, Key.B ) )         { handle_control_b( true ); }
        else if(  shift && has_key( kvs, Key.T ) )         { handle_control_t( true ); }
        else if( !shift && has_key( kvs, Key.backslash ) ) { handle_control_backslash(); }
        else if( !shift && has_key( kvs, Key.a ) )         { handle_control_a( false ); }
        else if( !shift && has_key( kvs, Key.b ) )         { handle_control_b( false ); }
        else if( !shift && has_key( kvs, Key.d ) )         { handle_control_d(); }
        else if( !shift && has_key( kvs, Key.h ) )         { handle_control_h(); }
        else if( !shift && has_key( kvs, Key.i ) )         { handle_control_i(); }
        else if( !shift && has_key( kvs, Key.j ) )         { handle_control_j(); }
        else if( !shift && has_key( kvs, Key.k ) )         { handle_control_k(); }
        else if( !shift && has_key( kvs, Key.t ) )         { handle_control_t( false ); }
        else if( !shift && has_key( kvs, Key.u ) )         { handle_control_u(); }
        else if( !shift && has_key( kvs, Key.w ) )         { handle_control_w(); }
      } else if( nomod || shift ) {
        if( has_key( kvs, Key.BackSpace ) )                 { handle_backspace(); }
        else if( has_key( kvs, Key.Delete ) )               { handle_delete(); }
        else if( has_key( kvs, Key.Escape ) )               { handle_escape(); }
        else if( has_key( kvs, Key.Return ) )               { handle_return( shift ); }
        else if( has_key( kvs, Key.Tab ) )                  { handle_tab( shift ); }
        else if( has_key( kvs, Key.Right ) )                { handle_right( shift ); }
        else if( has_key( kvs, Key.Left ) )                 { handle_left( shift ); }
        else if( has_key( kvs, Key.Home ) )                 { handle_home( shift ); }
        else if( has_key( kvs, Key.End ) )                  { handle_end( shift ); }
        else if( has_key( kvs, Key.Up ) )                   { handle_up( shift ); }
        else if( has_key( kvs, Key.Down ) )                 { handle_down( shift ); }
        else if( has_key( kvs, Key.Page_Up ) )              { handle_pageup(); }
        else if( has_key( kvs, Key.Page_Down ) )            { handle_pagedn(); }
        else if( has_key( kvs, Key.Control_L ) )            { handle_control( true ); }
        else if( has_key( kvs, Key.Control_R ) )            { handle_control( true ); }
        else if( has_key( kvs, Key.Shift_L ) )              { _shift_set = true; }
        else if( has_key( kvs, Key.Shift_R ) )              { _shift_set = true; }
        else if( !shift && has_key( kvs, Key.a ) )          { change_selected( node_parent( selected ) ); }
        else if(  shift && has_key( kvs, Key.B ) )          { change_selected( node_bottom() ); }
        else if( !shift && has_key( kvs, Key.c ) )          { change_selected( node_last_child( selected ) ); }
        else if( !shift && has_key( kvs, Key.e ) )          { edit_selected( true ); }
        else if(  shift && has_key( kvs, Key.E ) )          { edit_selected( false ); }
        else if( !shift && has_key( kvs, Key.f ) )          { focus_on_selected(); }
        else if( !shift && has_key( kvs, Key.h ) )          { unindent(); }
        else if(  shift && has_key( kvs, Key.H ) )          { place_at_top( selected ); }
        else if( !shift && has_key( kvs, Key.j ) )          { change_selected( node_next( selected ) ); }
        else if( !shift && has_key( kvs, Key.k ) )          { change_selected( node_previous( selected ) ); }
        else if( !shift && has_key( kvs, Key.l ) )          { indent(); }
        else if( !shift && has_key( kvs, Key.n ) )          { change_selected( node_next_sibling( selected ) ); }
        else if( !shift && has_key( kvs, Key.p ) )          { change_selected( node_previous_sibling( selected ) ); }
        else if( !shift && has_key( kvs, Key.t ) )          { rotate_task(); }
        else if(  shift && has_key( kvs, Key.T ) )          { change_selected( node_top() ); }
        else if(  shift && has_key( kvs, Key.numbersign ) ) { toggle_label(); }
        else if(  shift && has_key( kvs, Key.asterisk ) )   { clear_all_labels(); }
        else if( !shift && has_key( kvs, Key.@1 ) )         { goto_label( 0 ); }
        else if( !shift && has_key( kvs, Key.@2 ) )         { goto_label( 1 ); }
        else if( !shift && has_key( kvs, Key.@3 ) )         { goto_label( 2 ); }
        else if( !shift && has_key( kvs, Key.@4 ) )         { goto_label( 3 ); }
        else if( !shift && has_key( kvs, Key.@5 ) )         { goto_label( 4 ); }
        else if( !shift && has_key( kvs, Key.@6 ) )         { goto_label( 5 ); }
        else if( !shift && has_key( kvs, Key.@7 ) )         { goto_label( 6 ); }
        else if( !shift && has_key( kvs, Key.@8 ) )         { goto_label( 7 ); }
        else if( !shift && has_key( kvs, Key.@9 ) )         { goto_label( 8 ); }
        else if(  shift && has_key( kvs, Key.at ) )         { tagger.show_add_ui(); }
        else if( has_key( kvs, Key.F10 ) )                  { if( shift ) show_contextual_menu(); }
        else if( has_key( kvs, Key.Menu ) )                 { show_contextual_menu(); }
        else {
          // _im_context.filter_keypress( _key_controller.get_current_event() );
        }
      }
    } else {
      if( !control ) {
        if( shift && has_key( kvs, Key.asterisk ) ) { clear_all_labels(); }
        else if( !shift && has_key( kvs, Key.@1 ) ) { goto_label( 0 ); }
        else if( !shift && has_key( kvs, Key.@2 ) ) { goto_label( 1 ); }
        else if( !shift && has_key( kvs, Key.@3 ) ) { goto_label( 2 ); }
        else if( !shift && has_key( kvs, Key.@4 ) ) { goto_label( 3 ); }
        else if( !shift && has_key( kvs, Key.@5 ) ) { goto_label( 4 ); }
        else if( !shift && has_key( kvs, Key.@6 ) ) { goto_label( 5 ); }
        else if( !shift && has_key( kvs, Key.@7 ) ) { goto_label( 6 ); }
        else if( !shift && has_key( kvs, Key.@8 ) ) { goto_label( 7 ); }
        else if( !shift && has_key( kvs, Key.@9 ) ) { goto_label( 8 ); }
        else if( !shift && has_key( kvs, Key.j ) )  { handle_down( shift ); }
        else if( !shift && has_key( kvs, Key.k ) )  { handle_up( shift ); }
        else if( has_key( kvs, Key.Up ) )           { handle_up( shift ); }
        else if( has_key( kvs, Key.Down ) )         { handle_down( shift ); }
        else if( has_key( kvs, Key.Control_L ) )    { handle_control( true ); }
        else if( has_key( kvs, Key.Control_R ) )    { handle_control( true ); }
        else if( has_key( kvs, Key.Shift_L ) )      { _shift_set = true; }
        else if( has_key( kvs, Key.Shift_R ) )      { _shift_set = true; }
        else if( has_key( kvs, Key.Escape ) )       { handle_escape(); }
      }
    }

    /* Update the format bar state, if necessary */
    update_format_bar( "on_keypress" );

    return( true );

  }

  /* Called whenever a key is released */
  private void on_keyrelease( uint keyval, uint keycode, ModifierType state ) {
    switch( keyval ) {
      case Key.Control_L :
      case Key.Control_R :
        handle_control( false );
        break;
      case Key.Shift_L :
      case Key.Shift_R :
        _shift_set = false;
        break;
    }
  }

  /* Handles holding down the Control key only */
  private void handle_control( bool pressed ) {
    var tag   = FormatTag.URL;
    var extra = "";
    var current = node_at_coordinates( _motion_x, _motion_y );
    if( current != null ) {
      if( !is_node_editable() && current.name.is_within_clickable( _motion_x, _motion_y, out tag, out extra ) ) {
        if( pressed ) {
          set_cursor( click_cursor );
        } else {
          set_cursor( text_cursor );
        }
      } else if( !is_note_editable() && current.note.is_within_clickable( _motion_x, _motion_y, out tag, out extra ) && (tag == FormatTag.URL) ) {
        if( pressed ) {
          set_cursor( click_cursor );
        } else {
          set_cursor( text_cursor );
        }
      }
    }
    _control_set = pressed;
  }

  /* Displays the contextual menu based on what is currently selected */
  private void show_contextual_menu() {
    if( (selected != null) && (selected.mode == NodeMode.SELECTED) ) {
      _node_menu.show( _motion_x, _motion_y );
    }
  }

  /* Expands or collapses the current node's children */
  public void toggle_expand( Node node ) {
    var nodes = new Array<Node>();
    node.expanded = !node.expanded;
    if( !node.expanded && selected.is_descendant_of( node ) ) {
      selected = node;
    }
    nodes.append_val( node );
    undo_buffer.add_item( new UndoNodeExpander( node, nodes ) );
    queue_draw();
    changed();
  }

  /* Shows or hides all notes within the given node's tree */
  public void toggle_notes( Node node ) {
    node.set_notes_display( !node.any_notes_shown() );
    node.adjust_nodes( node.last_y, false, "toggle_notes" );
    see( node );
    queue_draw();
    changed();
  }

  /* Shows or hides the note field associated with the given node's tree */
  public void toggle_note( Node node, bool edit ) {
    node.hide_note = !node.hide_note;
    if( node.note.text.text == "" ) {
      selected = node;
      set_node_mode( selected, (node.hide_note || !edit) ? NodeMode.SELECTED : NodeMode.NOTEEDIT );
    }
    queue_draw();
    changed();
  }

  /* Creates a serialized version of the node for copy */
  public string serialize_node_for_copy( Node node ) {
    string    str;
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "olnode" );
    var       clone_ids = new HashMap<int,bool>();
    doc->set_root_element( root );
    root->add_child( node.save( ref clone_ids ) );
    doc->dump_memory( out str );
    delete doc;
    return( str );
  }

  /* Takes an XML string as input and populates the passed node with its contents */
  public void deserialize_node_for_paste( string str, Node node ) {
    Xml.Doc* doc       = Xml.Parser.parse_doc( str );
    var      clone_ids = new HashMap<int,Node>();
    if( doc == null ) return;
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        node.load( this, it, ref clone_ids );
      }
    }
    delete doc;
  }

  /* Serializes the selected text for copy */
  public string? serialize_text_for_copy( CanvasText ct ) {
    var ft = ct.get_selected_formatted_text( this );
    if( ft != null ) {
      string    str;
      Xml.Doc*  doc  = new Xml.Doc( "1.0" );
      Xml.Node* root = new Xml.Node( null, "oltext" );
      doc->set_root_element( root );
      root->add_child( ft.save() );
      doc->dump_memory( out str );
      delete doc;
      return( str );
    }
    return( null );
  }

  /* Deserializes the XML string and inserts it into the given canvas text */
  public void deserialize_text_for_paste( string str, CanvasText ct, bool replace ) {
    Xml.Doc* doc = Xml.Parser.parse_doc( str );
    if( doc == null ) return;
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        var ft = new FormattedText( this );
        ft.load( it );
        if( replace ) {
          ct.text.copy( ft );
        } else {
          ct.insert_formatted_text( ft, undo_text );
        }
      }
    }
  }

  /* Returns a copy of the currently selected nodes */
  public void get_nodes_for_clipboard( out Array<Node> nodes ) {
    nodes = new Array<Node>();
    if( selected != null ) {
      nodes.append_val( selected );
    }
  }

  /* Copies the given node to the designated node clipboard */
  public void copy_selected_node() {
    OutlinerClipboard.copy_nodes( this );
  }

  /*
   Copies the selected text to the clipboard.  TBD - This will not include
   text formatting at this point.
  */
  private void copy_selected_text( CanvasText ct ) {

    /* Store the text for Outliner text copy */
    var ftext = serialize_text_for_copy( ct );
    var text  = ct.get_selected_text();

    /* Copy both the formatted text and unformatted text */
    OutlinerClipboard.copy_text( ftext, text );

  }

  /* Handles a copy operation on a node or selected text */
  public void do_copy() {
    if( selected == null ) return;
    switch( selected.mode ) {
      case NodeMode.SELECTED :  copy_selected_node();   break;
      case NodeMode.EDITABLE :  copy_selected_text( selected.name );  break;
      case NodeMode.NOTEEDIT :  copy_selected_text( selected.note );  break;
    }
  }

  /* Clones the given node and its subtree */
  public void clone_node( Node node ) {
    _clone = node;
  }

  /* Converts the given node from a cloned node to an uncloned node */
  public void unclone_node( Node node ) {
    var clone_data = node.get_clone_data();
    node.unclone();
    undo_buffer.add_item( new UndoNodeUnclone( node, clone_data ) );
  }

  /* Copies the given node to the clipboard and then removes it from the document */
  public void cut_selected_node() {
    copy_selected_node();
    undo_buffer.add_item( new UndoNodeCut( selected ) );
    delete_node( selected );
  }

  /*
   Copies the currently selected text to the clipboard and then removes
   it from the given CanvasText object.
  */
  private void cut_selected_text( CanvasText ct ) {
    copy_selected_text( ct );
    ct.backspace( undo_text );
    queue_draw();
  }

  /* Handles a cut operation on a node or selected text */
  public void do_cut() {
    if( selected == null ) return;
    switch( selected.mode ) {
      case NodeMode.SELECTED :  cut_selected_node();  break;
      case NodeMode.EDITABLE :  cut_selected_text( selected.name );  break;
      case NodeMode.NOTEEDIT :  cut_selected_text( selected.note );  break;
    }
  }

  /* Inserts the given node relative to the currently selected row */
  private void insert_node_from_selected( bool below, Node node ) {
    if( below ) {
      if( selected.children.length > 0 ) {
        insert_node( selected, node, 0 );
      } else {
        insert_node( selected.parent, node, (selected.index() + 1) );
      }
    } else {
      insert_node( selected.parent, node, selected.index() );
    }
  }


  /* Clones the entire tree */
  private void clone_tree( Node src_node, out Node cloned_node ) {

    cloned_node = new Node.clone_from_node( this, src_node );

    for( int i=0; i<src_node.children.length; i++ ) {
      Node child;
      clone_tree( src_node.children.index( i ), out child );
      cloned_node.add_child( child );
    }

  }

  public void paste_clone( bool below ) {

    /* Clone the clone node */
    Node node;
    clone_tree( _clone, out node );

    /* Insert the node into the appropriate position in the table */
    insert_node_from_selected( below, node );

    /* Add an undo item for this operation */
    undo_buffer.add_item( new UndoNodePaste( node ) );

    queue_draw();
    changed();
    see( node );

  }

  /* Pastes the text into the provided CanvasText */
  public void paste_text( string text, bool shift ) {
    if( selected != null ) {
      if( shift ) {
        _orig_text.copy( selected.name );
        selected.name.text.set_text( text );
        selected.name.text.changed();
        undo_buffer.add_item( new UndoNodeName( this, selected, _orig_text ) );
      } else if( is_node_editable() ) {
        selected.name.insert( text, undo_text );
      } else if( is_note_editable() ) {
        selected.note.insert( text, undo_text );
      } else {
        var node = create_node( text );
        selected.add_child( node );
        undo_buffer.add_item( new UndoNodeInsert( node ) );
        selected = node;
      }
      queue_draw();
      changed();
    }
  }

  /* Pastes the formatted text into the provided CanvasText */
  public void paste_formatted_text( string text, bool shift ) {
    if( selected != null ) {
      if( shift ) {
        _orig_text.copy( selected.name );
        deserialize_text_for_paste( text, selected.name, true );
        undo_buffer.add_item( new UndoNodeName( this, selected, _orig_text ) );
      } else if( is_node_editable() ) {
        deserialize_text_for_paste( text, selected.name, false );
      } else if( is_note_editable() ) {
        deserialize_text_for_paste( text, selected.note, false );
      } else {
        var node = create_node();
        selected.add_child( node );
        deserialize_text_for_paste( text, node.name, true );
        undo_buffer.add_item( new UndoNodeInsert( node ) );
        selected = node;
      }
      queue_draw();
      changed();
    }
  }

  /* Pastes the given string as a tree of nodes */
  public void paste_node( string text, bool shift ) {

    /* Create the new node from the clipboard */
    var node = new Node( this );
    deserialize_node_for_paste( text, node );

    if( shift ) {
      var orig_node = selected;
      replace_node( orig_node, node );
      undo_buffer.add_item( new UndoNodeReplace( orig_node, node ) );
    } else {
      insert_node_from_selected( true, node );
      undo_buffer.add_item( new UndoNodePaste( node ) );
    }

    queue_draw();
    changed();
    see( node );

  }

  /* Handles a paste operation of a node or text to the table */
  public void do_paste( bool shift ) {
    OutlinerClipboard.paste( this, shift );
  }

  /* Handles a backspace keypress */
  private void handle_backspace() {
    if( is_node_editable() ) {
      if( selected.name.text.text == "" ) {
        var prev = node_previous( selected );
        if( prev != null ) {
          delete_current_node();
          selected = prev;
          set_node_mode( selected, NodeMode.EDITABLE );
          selected.name.move_cursor_to_end();
          _im_context.reset();
        }
      } else {
        selected.name.backspace( undo_text );
        see( selected );
        _im_context.reset();
        queue_draw();
      }
    } else if( is_note_editable() ) {
      selected.note.backspace( undo_text );
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      _title.backspace( undo_text );
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      delete_current_node();
    }
  }

  /* Deletes from the current cursor to the beginning of the current word */
  private void handle_control_backspace() {
    if( is_node_editable() ) {
      selected.name.backspace_word( undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.backspace_word( undo_text );
      see( selected );
      queue_draw();
    } else if( is_title_editable() ) {
      _title.backspace_word( undo_text );
      queue_draw();
    } else if( is_node_joinable() ) {
      join_row();
    }
  }

  /* Handles a delete keypress */
  private void handle_delete() {
    if( is_node_editable() ) {
      selected.name.delete( undo_text );
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.delete( undo_text );
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      _title.delete( undo_text );
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      delete_current_node();
    }
  }

  /* Deletes from the current cursor to the end of the current word */
  private void handle_control_delete() {
    if( is_node_editable() ) {
      selected.name.delete_word( undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.delete_word( undo_text );
      see( selected );
      queue_draw();
    } else if( is_title_editable() ) {
      _title.delete_word( undo_text );
      queue_draw();
    }
  }

  /* Handles an escape keypress */
  private void handle_escape() {
    if( is_node_editable() || is_note_editable() ) {
      if( _completion.shown ) {
        _completion.hide();
      } else {
        set_node_mode( selected, NodeMode.SELECTED );
        _im_context.reset();
        queue_draw();
        changed();
      }
    } else if( is_title_editable() ) {
      set_title_editable( false );
    } else if( root.alpha < 1.0 ) {
      focus_leave();
    }
  }

  /* Handles a return keypress */
  private void handle_return( bool shift ) {
    if( is_note_editable() ) {
      selected.note.insert( "\n", undo_text );
      see( selected );
      queue_draw();
    } else if( is_node_editable() && (shift || _completion.shown) ) {
      if( shift ) {
        selected.name.insert( "\n", undo_text );
        see( selected );
        queue_draw();
      } else {
        _completion.select();
        queue_draw();
      }
    } else if( is_title_editable() ) {
      set_title_editable( false );
      selected = root.get_last_node();
      set_node_mode( selected, NodeMode.EDITABLE );
      queue_draw();
    } else if( selected != null ) {
      if( (selected.children.length > 0) && selected.expanded ) {
        add_child_node( 0 );
      } else {
        add_sibling_node( !shift );
      }
    }
  }

  /* Splits the text at the current cursor position */
  private void split_text() {
    if( is_node_editable() ) {
      var sel    = selected;
      var curpos = selected.name.cursor;
      var title  = selected.name.text.text.substring( curpos );
      var endpos = selected.name.text.text.length;
      var index  = selected.index() + 1;
      var tags   = selected.name.text.get_tags_in_range( curpos, endpos );
      var node   = create_node( title, tags );
      var num_children = selected.children.length;
      selected.name.text.remove_text( curpos, (endpos - curpos ) );
      insert_node( sel.parent, node, index );
      for( int i=0; i<num_children; i++ ) {
        var child = sel.children.index( 0 );
        sel.remove_child( child );
        node.add_child( child );
      }
      _im_context.reset();
      undo_buffer.add_item( new UndoNodeSplit( selected ) );
    }
  }

  /* Joins the current row with the row above it */
  public void join_row() {
    var sel          = selected;
    var prev         = selected.get_previous_node();
    var sel_children = sel.children.length;
    undo_buffer.add_item( new UndoNodeJoin( sel, prev ) );
    prev.name.text.set_text( prev.name.text.text + " " );
    prev.name.text.insert_formatted_text( prev.name.text.text.length, sel.name.text );
    for( int i=0; i<sel_children; i++ ) {
      var child = sel.children.index( 0 );
      sel.remove_child( child );
      prev.add_child( child );
    }
    sel.parent.remove_child( sel );
    selected = prev;
    queue_draw();
    changed();
  }

  /* Handles a Control-Return keypress */
  private void handle_control_return( bool shift ) {
    if( is_node_editable() && !shift ) {
      split_text();
    } else if( is_note_editable() ) {
      selected.note.insert( "\n", undo_text );
      queue_draw();
    } else if( is_title_editable() ) {
      _title.insert( "\n", undo_text );
      queue_draw();
    }
  }

  /* Handles a tab key hit when a node is selected */
  private void handle_tab( bool shift ) {
    if( is_node_editable() && _completion.shown && !shift ) {
      _completion.select();
      queue_draw();
    } else if( is_note_editable() && shift ) {
      selected.note.insert( "\t", undo_text );
      see( selected );
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.insert( "\t", undo_text );
      } else {
        set_title_editable( false );
        selected = root.get_last_node();
        set_node_mode( selected, NodeMode.EDITABLE );
      }
      queue_draw();
    } else if( selected != null ) {
      if( shift ) {
        unindent();
      } else {
        indent();
      }
    }
  }

  /* Handles a Control-Tab keypress */
  private void handle_control_tab() {
    if( is_node_editable() ) {
      selected.name.insert( "\t", undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.insert( "\t", undo_text );
      see( selected );
      queue_draw();
    } else if( is_title_editable() ) {
      _title.insert( "\t", undo_text );
      queue_draw();
    }
  }

  /* Handles a right arrow keypress */
  private void handle_right( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_char( 1 );
      } else {
        selected.name.move_cursor( 1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_char( 1 );
      } else {
        selected.note.move_cursor( 1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_by_char( 1 );
      } else {
        _title.move_cursor( 1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      if( !selected.is_leaf() ) {
        var nodes = new Array<Node>();
        if( shift ) {
          selected.expand_all( nodes );
        } else {
          if( !selected.expanded ) {
            selected.collapse_all( nodes );
          }
          selected.expand_next( nodes );
        }
        selected.adjust_nodes( selected.last_y, false, "expand next" );
        undo_buffer.add_item( new UndoNodeExpander( selected, nodes ) );
        queue_draw();
        changed();
      }
    }
  }

  /* Handles a Control-Right arrow keypress */
  private void handle_control_right( bool shift ) {
    if( is_node_selected() ) {
      indent();
    } else if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_word( 1 );
      } else {
        selected.name.move_cursor_by_word( 1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_word( 1 );
      } else {
        selected.note.move_cursor_by_word( 1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_by_word( 1 );
      } else {
        _title.move_cursor_by_word( 1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /* Handles a left arrow keypress */
  private void handle_left( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_char( -1 );
      } else {
        selected.name.move_cursor( -1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_char( -1 );
      } else {
        selected.note.move_cursor( -1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_by_char( -1 );
      } else {
        _title.move_cursor( -1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      if( !selected.is_leaf() && selected.expanded ) {
        var nodes = new Array<Node>();
        if( shift ) {
          selected.collapse_all( nodes );
        } else {
          selected.collapse_next( nodes );
        }
        selected.adjust_nodes( selected.last_y, false, "left key" );
        undo_buffer.add_item( new UndoNodeExpander( selected, nodes ) );
        queue_draw();
        changed();
      }
    }
  }

  /* Handles a Control-left arrow keypress */
  private void handle_control_left( bool shift ) {
    if( is_node_selected() ) {
      unindent();
    } else if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_by_word( -1 );
      } else {
        selected.name.move_cursor_by_word( -1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_by_word( -1 );
      } else {
        selected.note.move_cursor_by_word( -1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_by_word( -1 );
      } else {
        _title.move_cursor_by_word( -1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /* Handles an up arrow keypress */
  private void handle_up( bool shift ) {
    if( is_node_editable() ) {
      if( _completion.shown ) {
        _completion.up();
      } else {
        if( shift ) {
          selected.name.selection_vertically( -1 );
        } else {
          selected.name.move_cursor_vertically( -1 );
        }
        undo_text.mergeable = false;
        see( selected );
        _im_context.reset();
        queue_draw();
      }
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_vertically( -1 );
      } else {
        selected.note.move_cursor_vertically( -1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_vertically( -1 );
      } else {
        _title.move_cursor_vertically( -1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      var node = shift ? node_top() : node_previous( selected );
      if( node != null ) {
        selected = node;
        queue_draw();
      }
    } else {
      int y1, y2;
      get_window_ys( out y1, out y2 );
      var node = node_at_coordinates( 0, y2 );
      if( node != null ) {
        selected = node;
      } else {
        selected = root.get_last_node();
      }
      queue_draw();
    }
  }

  /* Moves the specified node down the document by one row.  Returns true if successful. */
  public bool move_node_up( Node node ) {
    var prev = node.get_previous_node();
    if( prev != null ) {
      var orig_parent = node.parent;
      var orig_index  = node.index();
      node.parent.remove_child( node );
      prev.parent.add_child( node, prev.index() );
      undo_buffer.add_item( new UndoNodeMove( node, orig_parent, orig_index ) );
      queue_draw();
      changed();
      see( node );
      return( true );
    }
    return( false );
  }

  /* Moves the specified node down the document by one row.  Returns true if successful. */
  public bool move_node_down( Node node ) {
    var next = node.get_last_node().get_next_node();
    if( next != null ) {
      var orig_parent = node.parent;
      var orig_index  = node.index();
      node.parent.remove_child( node );
      if( next.children.length == 0 ) {
        next.parent.add_child( node, (next.index() + 1) );
      } else {
        next.add_child( node, 0 );
      }
      undo_buffer.add_item( new UndoNodeMove( node, orig_parent, orig_index ) );
      queue_draw();
      changed();
      see( node );
      return( true );
    }
    return( false );
  }

  /* Moves the selected node to the top of the document.  Returns true if successful. */
  public bool move_node_to_top( Node node ) {
    if( node != root.children.index( 0 ) ) {
      var orig_parent = node.parent;
      var orig_index  = node.index();
      node.parent.remove_child( node );
      root.add_child( node, 0 );
      undo_buffer.add_item( new UndoNodeMove( node, orig_parent, orig_index ) );
      queue_draw();
      changed();
      see( node );
      return( true );
    }
    return( false );
  }

  /* Moves the selected node to the bottom of the document.  Returns true if successful. */
  public bool move_node_to_bottom( Node node ) {
    var last = root.get_last_node();
    if( node.get_last_node() != last ) {
      var orig_parent = node.parent;
      var orig_index  = node.index();
      node.parent.remove_child( node );
      last.parent.add_child( node, (last.index() + 1) );
      undo_buffer.add_item( new UndoNodeMove( node, orig_parent, orig_index ) );
      queue_draw();
      changed();
      see( node );
      return( true );
    }
    return( false );
  }

  /*
   Moves the given node as a sibling to its parent.  If shift is true, it will
   be place above the parent; otherwise, it will be placed below the parent.
  */
  public bool move_node_to_parent( Node node, bool shift ) {
    if( !node.parent.is_root() ) {
      var parent      = node.parent;
      var orig_parent = node.parent;
      var orig_index  = node.index();
      parent.remove_child( node );
      parent.parent.add_child( node, (parent.index() + (shift ? 0 : 1)) );
      undo_buffer.add_item( new UndoNodeMove( node, orig_parent, orig_index ) );
      queue_draw();
      changed();
      see( node );
      return( true );
    }
    return( false );
  }

  /* Handles a Control-Up arrow keypress */
  private void handle_control_up( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_start( false );
      } else {
        selected.name.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_start( false );
      } else {
        selected.note.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_to_start( false );
      } else {
        _title.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      if( shift ) {
        // TBD
      } else {
        move_node_up( selected );
      }
    }
  }

  /* Handles down arrow keypress */
  private void handle_down( bool shift ) {
    if( is_node_editable() ) {
      if( _completion.shown ) {
        _completion.down();
      } else {
        if( shift ) {
          selected.name.selection_vertically( 1 );
        } else {
          selected.name.move_cursor_vertically( 1 );
        }
        undo_text.mergeable = false;
        see( selected );
        _im_context.reset();
        queue_draw();
      }
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_vertically( 1 );
      } else {
        selected.note.move_cursor_vertically( 1 );
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_vertically( 1 );
      } else {
        _title.move_cursor_vertically( 1 );
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      var node = node_next( selected );
      if( node != null ) {
        selected = node;
        queue_draw();
      }
    } else {
      int y1, y2;
      get_window_ys( out y1, out y2 );
      var node = node_at_coordinates( 0, y1 );
      if( node != null ) {
        selected = node;
        queue_draw();
      }
    }
  }

  /* Handles Control-Down arrow keypress */
  private void handle_control_down( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_end( false );
      } else {
        selected.name.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_end( false );
      } else {
        selected.note.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_to_end( false );
      } else {
        _title.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    } else if( selected != null ) {
      if( shift ) {
        // TBD
      } else {
        move_node_down( selected );
      }
    }
  }

  /* Handles a Control-slash keypress */
  private void handle_control_slash() {
    if( is_node_editable() ) {
      selected.name.set_cursor_all( false );
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.set_cursor_all( false );
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      _title.set_cursor_all( false );
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /* Handles a Control-backslash keypress */
  private void handle_control_backslash() {
    if( is_node_editable() ) {
      selected.name.clear_selection();
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.clear_selection();
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      _title.clear_selection();
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /*
   Handles a Control-number keypress which moves the currently selected
   row within the labeled row (if one exists)
  */
  public void handle_control_number( int label ) {
    if( is_node_selected() ) {
      var parent = _labels.get_node( label );
      if( (parent != null) && (parent != selected) && (parent != selected.parent) && !parent.is_descendant_of( selected ) ) {
        var orig_parent = selected.parent;
        var orig_index  = selected.index();
        selected.parent.remove_child( selected );
        parent.add_child( selected );
        undo_buffer.add_item( new UndoNodeMove( selected, orig_parent, orig_index ) );
        queue_draw();
        changed();
        see( selected );
      }
    }
  }

  /* Called whenever the period key is entered with the control key */
  private void handle_control_period() {
    if( is_node_editable() ) {
      insert_emoji( selected.name );
    } else if( is_note_editable() ) {
      insert_emoji( selected.note );
    } else if( is_title_editable() ) {
      insert_emoji( _title );
    }
  }

  /* Selects all text */
  private void handle_control_a( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.set_cursor_none();
      } else {
        selected.name.set_cursor_all( false );
      }
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.set_cursor_none();
      } else {
        selected.note.set_cursor_all( false );
      }
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.set_cursor_none();
      } else {
        _title.set_cursor_all( false );
      }
      _im_context.reset();
      queue_draw();
    } else if( is_node_selected() ) {
      move_node_to_parent( selected, shift );
    }
  }

  /* Causes selected text to be bolded */
  private void handle_control_b( bool shift ) {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.BOLD, null, undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.BOLD, null, undo_text );
      see( selected );
      queue_draw();
    } else if( shift && is_node_selected() ) {
      move_node_to_bottom( selected );
    }
  }

  /* This is just used from debugging purposes */
  private void handle_control_d() {
    if( !_debug ) return;
    if( selected != null ) {
      // stdout.printf( "RTF: %s\n", ExportRTF.from_text( selected.name.text ) );
    }
  }

  /* Toggles the show all notes status given the state of the currently selected node */
  private void handle_control_h() {
    set_notes_display( !root.any_notes_shown() );
  }

  /* Causes selected text to be italicized */
  private void handle_control_i() {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.ITALICS, null, undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.ITALICS, null, undo_text );
      see( selected );
      queue_draw();
    }
  }

  /* If the current node is selected, moves the node down */
  private void handle_control_j() {
    if( is_node_selected() ) {
      move_node_down( selected );
    }
  }

  /* If the current node is selected, moves the node up */
  private void handle_control_k() {
    if( is_node_selected() ) {
      move_node_up( selected );
    }
  }

  /* Causes selected text to be underlined */
  private void handle_control_u() {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.UNDERLINE, null, undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.UNDERLINE, null, undo_text );
      see( selected );
      queue_draw();
    }
  }

  /* Causes selected text to be striken */
  private void handle_control_t( bool shift ) {
    if( is_node_text_selected() ) {
      selected.name.add_tag( FormatTag.STRIKETHRU, null, undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_text_selected() ) {
      selected.note.add_tag( FormatTag.STRIKETHRU, null, undo_text );
      see( selected );
      queue_draw();
    } else if( shift && is_node_selected() ) {
      move_node_to_top( selected );
    }
  }

  /* Closes the current tab, requesting a save if necessary */
  private void handle_control_w() {
    win.close_current_tab();
  }

  /* Handles a Control-Home keypress */
  private void handle_control_home( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_start( true );
      } else {
        selected.name.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_start( true );
      } else {
        selected.note.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_to_start( true );
      } else {
        _title.move_cursor_to_start();
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /* Handles a Home keypress */
  private void handle_home( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_linestart( true );
      } else {
        selected.name.move_cursor_to_linestart();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_linestart( true );
      } else {
        selected.note.move_cursor_to_linestart();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_to_linestart( true );
      } else {
        _title.move_cursor_to_linestart();
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /* Handles a Control-End keypress */
  private void handle_control_end( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_end( true );
      } else {
        selected.name.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_end( true );
      } else {
        selected.note.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_to_end( true );
      } else {
        _title.move_cursor_to_end();
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /* Handles an End keypress */
  private void handle_end( bool shift ) {
    if( is_node_editable() ) {
      if( shift ) {
        selected.name.selection_to_lineend( true );
      } else {
        selected.name.move_cursor_to_lineend();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_note_editable() ) {
      if( shift ) {
        selected.note.selection_to_lineend( true );
      } else {
        selected.note.move_cursor_to_lineend();
      }
      undo_text.mergeable = false;
      see( selected );
      _im_context.reset();
      queue_draw();
    } else if( is_title_editable() ) {
      if( shift ) {
        _title.selection_to_lineend( true );
      } else {
        _title.move_cursor_to_lineend();
      }
      undo_text.mergeable = false;
      _im_context.reset();
      queue_draw();
    }
  }

  /* Moves the selection down by a page */
  private void handle_pageup() {
    if( is_node_selected() ) {
      var vp   = parent.parent as Viewport;
      var vh   = vp.get_allocated_height();
      var sw   = parent.parent.parent as ScrolledWindow;
      var y1   = sw.vadjustment.value;
      sw.vadjustment.value = y1 - vh;
      if( y1 == sw.vadjustment.value ) {
        change_selected( node_top() );
      } else {
        var node = node_at_coordinates( 0, (sw.vadjustment.value + vh) );
        if( node != null ) {
          selected = node;
          queue_draw();
        }
      }
    }
  }

  /* Moves the selection up by a page */
  private void handle_pagedn() {
    if( is_node_selected() ) {
      var vp = parent.parent as Viewport;
      var vh = vp.get_allocated_height();
      var sw = parent.parent.parent as ScrolledWindow;
      var y1 = sw.vadjustment.value;
      sw.vadjustment.value = y1 + vh;
      if( y1 == sw.vadjustment.value ) {
        change_selected( node_bottom() );
      } else {
        var node = node_at_coordinates( 0, sw.vadjustment.value );
        if( node != null ) {
          selected = node;
          queue_draw();
        }
      }
    }
  }

  /* Called by the input method manager when the user has a string to commit */
  private void handle_im_commit( string str ) {
    insert_user_text( str );
  }

  /* Inserts user text for the editable CanvasText widget */
  private bool insert_user_text( string str ) {
    if( !str.get_char( 0 ).isprint() ) return( false );
    if( is_node_editable() ) {
      selected.name.insert( str, undo_text );
      see( selected );
      queue_draw();
    } else if( is_note_editable() ) {
      selected.note.insert( str, undo_text );
      see( selected );
      queue_draw();
    } else if( is_title_editable() ) {
      _title.insert( str, undo_text );
      queue_draw();
    } else {
      return( false );
    }
    return( true );
  }

  /* Helper class for the handle_im_retrieve_surrounding method */
  private void retrieve_surrounding_in_text( CanvasText ct ) {
    var text = ct.text.text;
    _im_context.set_surrounding( text, text.length, ct.cursor );
  }

  /* Called in IMContext callback of the same name */
  private bool handle_im_retrieve_surrounding() {
    if( is_node_editable() ) {
      retrieve_surrounding_in_text( selected.name );
      return( true );
    } else if( is_note_editable() ) {
      retrieve_surrounding_in_text( selected.note );
      return( true );
    } else if( is_title_editable() ) {
      retrieve_surrounding_in_text( _title );
      return( true );
    }
    return( false );
  }

  /* Helper class for the handle_im_delete_surrounding method */
  private void delete_surrounding_in_text( CanvasText ct, int offset, int chars ) {
    int cursor, selstart, selend;
    ct.get_cursor_info( out cursor, out selstart, out selend );
    var startpos = cursor - offset;
    var endpos   = startpos + chars;
    ct.delete_range( startpos, endpos, undo_text );
  }

  /* Called in IMContext callback of the same name */
  private bool handle_im_delete_surrounding( int offset, int nchars ) {
    if( is_node_editable() ) {
      delete_surrounding_in_text( selected.name, offset, nchars );
      return( true );
    } else if( is_note_editable() ) {
      delete_surrounding_in_text( selected.note, offset, nchars );
      return( true );
    } else if( is_title_editable() ) {
      delete_surrounding_in_text( _title, offset, nchars );
      return( true );
    }
    return( false );
  }

  /* Toggles the label */
  public void toggle_label() {
    var label = _labels.get_label_for_node( selected );
    if( label == -1 ) {
      _labels.set_next_label( selected );
    } else {
      _labels.set_label( null, label );
    }
    queue_draw();
    changed();
  }

  /* Jumps to the given label */
  public void goto_label( int label ) {
    var node = _labels.get_node( label );
    if( (node != null) && !node.hidden ) {
      selected = node;
      queue_draw();
    }
  }

  /* Clears all of the labels */
  public void clear_all_labels() {
    _labels.clear_all();
    queue_draw();
    changed();
  }

  private Node? node_parent( Node node ) {
    do {
      node = node.parent;
    } while( !node.is_root() && node.hidden );
    return( node.is_root() ? null : node );
  }

  private Node? node_top() {
    var node = root.get_first_node();
    while( (node != null) && node.hidden ) {
      node = node.get_next_node();
    }
    return( node );
  }

  private Node? node_bottom() {
    var node = root.get_last_node();
    while( (node != null) && node.hidden ) {
      node = node.get_previous_node();
    }
    return( node );
  }

  private Node? node_last_child( Node node ) {
    var n = node.get_last_child();
    while( (n != null) && n.hidden ) {
      n = node_previous_sibling( n );
    }
    return( n );
  }

  private Node? node_next( Node node ) {
    var n = node.get_next_node();
    while( (n != null) && n.hidden ) {
      n = n.get_next_node();
    }
    return( n );
  }

  private Node? node_previous( Node node ) {
    var n = node.get_previous_node();
    while( (n != null) && n.hidden ) {
      n = n.get_previous_node();
    }
    return( n );
  }

  private Node? node_next_sibling( Node node ) {
    var n = node.get_next_sibling();
    while( (n != null) && n.hidden ) {
      n = n.get_next_sibling();
    }
    return( n );
  }

  /*
   Returns the node that is the sibling above the current one.  If the current
   node is the top-most node, return null.
  */
  private Node? node_previous_sibling( Node? node ) {
    var n = node.get_previous_sibling();
    while( (n != null) && n.hidden ) {
      n = n.get_previous_sibling();
    }
    return( n );
  }

  /* Edit the selected node */
  public void edit_selected( bool title ) {
    if( selected == null ) return;
    if( title ) {
      set_node_mode( selected, NodeMode.EDITABLE );
      selected.name.move_cursor_to_end();
    } else {
      set_node_mode( selected, NodeMode.NOTEEDIT );
      selected.note.move_cursor_to_end();
      selected.hide_note = false;
    }
    queue_draw();
  }

  /* Change the selected node to the given node */
  public void change_selected( Node? node ) {
    if( (node == null) || node.is_root() ) return;
    selected = node;
    queue_draw();
    see( selected );
  }

  /* Changes the task status by one */
  public void rotate_task() {
    if( selected == null ) return;
    switch( selected.task ) {
      case NodeTaskMode.NONE  :  selected.task = NodeTaskMode.OPEN;   break;
      case NodeTaskMode.OPEN  :  selected.task = NodeTaskMode.DOING;  break;
      case NodeTaskMode.DOING :  selected.task = NodeTaskMode.DONE;   break;
      case NodeTaskMode.DONE  :  selected.task = NodeTaskMode.NONE;   break;
    }
    queue_draw();
    changed();
  }

  /* Called by the Tagger class to actually add the tag to the currently selected row */
  public void add_tag( string tag ) {
    if( selected == null ) return;
    var name = selected.name;
    _orig_text.copy( name );
    tagger.preedit_load_tags( name.text );
    name.text.insert_text( name.text.text.length, (" @" + tag) );
    name.text.changed();
    tagger.postedit_load_tags( name.text );
    undo_buffer.add_item( new UndoNodeName( this, selected, _orig_text ) );
    changed();
  }

  /*************************/
  /* MISCELLANEOUS METHODS */
  /*************************/

  /* Handles the emoji insertion process for the given text item */
  private void insert_emoji( CanvasText text ) {
    int x, ytop, ybot;
    text.get_cursor_pos( out x, out ytop, out ybot );
    Gdk.Rectangle rect = {x, (ytop + ((ybot - ytop) / 2)), 1, 1};
    var emoji = new EmojiChooser() {
      pointing_to = rect
    };
    emoji.set_parent( this );
    emoji.popup();
    emoji.emoji_picked.connect((txt) => {
      text.insert( txt, undo_text );
      grab_focus();
      queue_draw();
    });
  }

  /* Returns the currently applied heme */
  public Theme get_theme() {
    return( _theme );
  }

  /* Sets the theme to the given value */
  public void set_theme( Theme theme, bool save = true ) {

    _theme = theme;

    /* Update the theme */
    update_theme();

    if( save ) {
      changed();
    }

  }

  /* Updates the CSS for the current outline table */
  private void update_css() {
    StyleContext.add_provider_for_display(
      win.get_display(),
      _theme.get_css_provider(),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
  }

  /* Updates the current them in the UI */
  public void update_theme() {

    /* Update the CSS */
    update_css();

    /* Change the theme of the formatted text */
    FormattedText.set_theme( _theme );

    /* Indicate that the theme has changed to anyone listening */
    theme_changed();

    /* Update all nodes */
    queue_draw();

  }

  private void title_resized() {
    if( root.children.length > 0 ) {
      root.children.index( 0 ).y = get_top_row_y();
      root.children.index( 0 ).adjust_nodes( root.children.index( 0 ).last_y, false, "gsettings changed" );
      queue_draw();
    }
  }

  private void create_title( bool edit ) {

    _title = new CanvasText.with_text( this, get_allocated_width(), _( "Title" ) );
    _title.posy = top_margin;
    _title.set_font( _title_family, _title_size );
    _title.set_alignment( Pango.Alignment.CENTER );
    _title.resized.connect( title_resized );

    title_resized();

    if( edit ) {
      set_title_editable( true );
      _title.set_cursor_all( false );
    }

  }

  /*
   Called whenever the window size is changed.  Adjusts the title text
   field to match the window width.
  */
  private void window_size_changed() {

    if( _title == null ) return;

    var rmargin = 20;

    /* Update our width information */
    _title.max_width = _width - (_title.posx + rmargin);

  }

  /* Creates a new, unnamed document */
  public void initialize_for_new() {

    /* Initialize variables */
    _press_type = 0;

    Idle.add(() => {

      /* Create the main idea node */
      var node = new Node( this );
      insert_node( root, node, 0 );
      selected = null;

      /* Create the title */
      create_title( true );

      queue_draw();

      return( false );

    });

  }

  /* Sets up the canvas for an opened file */
  public void initialize_for_open() {

    /* Create a new root node */
    root = new Node( this );

    /* Clear the undo buffer */
    undo_buffer.clear();

    /* Clear the selection */
    selected = null;

    /* Initialize variables */
    _press_type = 0;

  }

  /*
   If the format bar needs to be created, create it.  Place it at the current
   cursor position and make sure that it is visible.
  */
  private void show_format_bar() {

    /* If the format bar is currently displayed, just reposition it */
    if( _format_bar == null ) {
      _format_bar = new FormatBar( this );
    }

    int selstart, selend, cursor;
    var text = (selected.mode == NodeMode.EDITABLE) ? selected.name : selected.note;

    text.get_cursor_info( out cursor, out selstart, out selend );

    /* Position the popover */
    double left, top, bottom;
    int    line;
    text.get_char_pos( cursor, out left, out top, out bottom, out line );

    /* If this is the first line of the first row, change the popover point to the bottom of the text */
    if( (selected == root.children.index( 0 )) && (line == 0) ) {
      Gdk.Rectangle rect = {(int)left, (int)bottom, 1, 1};
      _format_bar.pointing_to = rect;
      _format_bar.position    = PositionType.BOTTOM;
    } else {
      Gdk.Rectangle rect = {(int)left, (int)top, 1, 1};
      _format_bar.pointing_to = rect;
      _format_bar.position    = PositionType.TOP;
    }

    _format_bar.popup();

  }

  /* Hides the format bar if it is currently visible and destroys it */
  private void hide_format_bar() {
    if( _format_bar != null ) {
      Utils.hide_popover( _format_bar );
      _format_bar = null;
    }
  }

  /* Shows/Hides the formatting toolbar */
  private void update_format_bar( string? msg ) {

    if( _debug && (msg != null) ) {
      // stdout.printf( "In update_format_bar, msg: %s\n", msg );
    }

    /* If we have nothing to do, just return */
    if( _show_format == null ) return;

    /* Update the format bar */
    if( _show_format ) {
      show_format_bar();
    } else {
      hide_format_bar();
    }

    /* Clear the show format indicator */
    _show_format = null;

  }

  /* Calculates the statistics for the current node */
  private void update_node_statistics( Node node,
    ref int char_count, ref int word_count, ref int row_count,
    ref int tasks_open, ref int tasks_doing, ref int tasks_done
  ) {
    var name = node.name.text.text;
    var note = node.note.text.text;
    char_count += (name.char_count() + note.char_count());
    word_count += (name.strip().split_set( " \t\r\n" ).length +
                   note.strip().split_set( " \t\r\n" ).length);
    row_count++;
    switch( node.task ) {
      case NodeTaskMode.OPEN  :  tasks_open++;  break;
      case NodeTaskMode.DOING :  tasks_doing++;  break;
      case NodeTaskMode.DONE  :  tasks_done++;   break;
    }
    for( int i=0; i<node.children.length; i++ ) {
      update_node_statistics( node.children.index( i ),
        ref char_count, ref word_count, ref row_count,
        ref tasks_open, ref tasks_doing, ref tasks_done );
    }
  }

  /* Calculate all of the document statistics and return them */
  public void calculate_statistics(
    out int char_count, out int word_count, out int row_count,
    out int tasks_open, out int tasks_doing, out int tasks_done
  ) {
    char_count  = 0;
    word_count  = 0;
    row_count   = 0;
    tasks_open  = 0;
    tasks_doing = 0;
    tasks_done  = 0;
    for( int i=0; i<root.children.length; i++ ) {
      update_node_statistics( root.children.index( i ),
        ref char_count, ref word_count, ref row_count,
        ref tasks_open, ref tasks_doing, ref tasks_done );
    }
  }

  /***************************/
  /* FILE LOAD/STORE METHODS */
  /***************************/

  /* Loads the table information from the given XML node */
  public void load( Xml.Node* n ) {

    var c = n->get_prop( "condensed" );
    if( c != null ) {
      _condensed = bool.parse( c );
    }

    var lt = n->get_prop( "listtype" );
    if( lt != null ) {
      _list_type = NodeListType.parse( lt );
    }

    var t = n->get_prop( "show-tasks" );
    if( t != null ) {
      _show_tasks = bool.parse( t );
    }

    var d = n->get_prop( "show-depth" );
    if( d != null ) {
      _show_depth = bool.parse( d );
    }

    var m = n->get_prop( "markdown" );
    if( m != null ) {
      _markdown = bool.parse( m );
    }

    var br = n->get_prop( "blank-rows" );
    if( br != null ) {
      _blank_rows = bool.parse( br );
    }

		var ah = n->get_prop( "auto-sizing" );
		if( ah != null ) {
			_auto_sizing = bool.parse( ah );
		}

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "title"  :
            create_title( false );
            _title.load( it );
            break;
          case "theme"  :  load_theme( it );  break;
          case "nodes"  :  load_nodes( it );  break;
          case "labels" :  _labels.load( this, it );  break;
          case "tags"   :  _tagger.load( it );  break;
        }
      }
    }

    /* Adjust the nodes if we have a title */
    if( _title != null ) {
      title_resized();
    }

    /* Update the size of this widget */
    Timeout.add( 50, resize_table );

    /* Draw everything */
    queue_draw();

  }

  /* Loads the given theme from XML format */
  private void load_theme( Xml.Node* n ) {

    string? name = n->get_prop( "name" );
    if( name != null ) {
      set_theme( MainWindow.themes.get_theme( name ), false );
    }

  }

  /* Loads all of the nodes from the outliner XML document */
  private void load_nodes( Xml.Node* n ) {

    var i = 0;
    var clone_ids = new HashMap<int,Node>();

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        var node = new Node( this );
        root.add_child( node, i++ );
        node.load( this, it, ref clone_ids );
      }
    }

  }

  /* Saves the table information to the given XML node */
  public void save( Xml.Node* n ) {

    n->set_prop( "version",     Outliner.version );
    n->set_prop( "condensed",   _condensed.to_string() );
    n->set_prop( "listtype",    list_type.to_string() );
    n->set_prop( "show-tasks",  _show_tasks.to_string() );
    n->set_prop( "show-depth",  _show_depth.to_string() );
    n->set_prop( "markdown",    _markdown.to_string() );
    n->set_prop( "blank-rows",  _blank_rows.to_string() );
		n->set_prop( "auto-sizing", _auto_sizing.to_string() );

    if( _title != null ) {
      n->add_child( _title.save( "title" ) );
    }

    n->add_child( save_theme() );
    n->add_child( save_nodes() );
    n->add_child( _labels.save() );
    n->add_child( _tagger.save() );

  }

  /* Saves the theme information in XML format */
  private Xml.Node* save_theme() {

    Xml.Node* theme = new Xml.Node( null, "theme" );

    theme->new_prop( "name", _theme.name );

    return( theme );

  }

  /* Saves the nodes in XML format and returns the <nodes> node */
  private Xml.Node* save_nodes() {

    Xml.Node* n = new Xml.Node( null, "nodes" );

    var clone_ids = new HashMap<int,bool>();

    for( int i=0; i<root.children.length; i++ ) {
      n->add_child( root.children.index( i ).save( ref clone_ids ) );
    }

    return( n );

  }

  /**************************/
  /* SEARCH-RELATED METHODS */
  /**************************/

  /* Perform a depth-first search for the given search pattern */
  public void do_search( string pattern ) {
    root.do_search( pattern );
    queue_draw();
  }

  /* Replaces the current match */
  public void replace_current( string replace ) {
    if( is_node_editable() ) {
      selected.name.insert( replace, undo_text );
      queue_draw();
      changed();
    } else if( is_note_editable() ) {
      selected.note.insert( replace, undo_text );
      queue_draw();
      changed();
    } else if( is_title_editable() ) {
      _title.insert( replace, undo_text );
      queue_draw();
      changed();
    }
  }

  /* Replaces all matched text within the document with the given string */
  public void replace_all( string search, string replace ) {
    var undo = new UndoReplaceAll( search, replace );
    root.replace_all( replace, ref undo );
    undo_buffer.add_item( undo );
    queue_draw();
    changed();
  }

  /* Enters focus mode for the selected mode */
  public void focus_on_selected() {
    root.set_tree_alpha( dim_unselected );
    selected.set_tree_alpha( 1.0 );
    _focus_node = selected;
    place_at_top( selected );
    focus_mode( _( "In Focus Mode.  Hit the Escape key to exit." ) );
    queue_draw();
  }

  /* Return to unfocused mode */
  public void focus_leave() {
    root.set_tree_alpha( 1.0 );
    focus_mode( null );
    _focus_node = null;
    queue_draw();
  }

  /* Filters the rows that match the given NodeFilterFunc */
  public void filter_nodes( string msg, bool show_parent, NodeFilterFunc? func ) {
    _filtered = false;
    for( int i=0; i<root.children.length; i++ ) {
      var shown = false;
      root.children.index( i ).filter( func, ref _filtered, ref shown );
      root.children.index( i ).hidden &= !show_parent || !shown;
    }
    if( _filtered || (func == null) ) {
      root.adjust_nodes( 0, false, "filter_nodes" );
      queue_draw();
      if( selected != null ) {
        see( selected );
      }
    }
    if( _filtered && (func != null) ) {
      nodes_filtered( msg + " " + _( "Hit the Escape key to exit." ) );
    } else {
      nodes_filtered( null );
    }
  }

  /*******************/
  /* AUTO-COMPLETION */
  /*******************/

  /* Displays the auto-completion widget with the given list of values */
  public void show_auto_completion( GLib.List<TextCompletionItem> values, int start_pos, int end_pos ) {
    if( is_node_editable() ) {
      _completion.show( selected.name, values, start_pos, end_pos );
    } else if( is_note_editable() ) {
      _completion.show( selected.note, values, start_pos, end_pos );
    } else {
      _completion.hide();
    }
  }

  /* Hides the auto-completion widget from view */
  public void hide_auto_completion() {
    _completion.hide();
  }

  /************************/
  /* TREE-RELATED METHODS */
  /************************/

  /* Creates a new node that is ready to be edited */
  private Node create_node( string? title = null, Array<UndoTagInfo>? tags = null ) {

    var node = new Node( this );

    if( title != null ) {
      node.name.text.set_text( title );
    }

    if( tags != null ) {
      node.name.text.apply_tags( tags );
    }

    return( node );

  }

  /* Inserts the given node into the given parent at the specified index */
  public void insert_node( Node parent, Node node, int index ) {
    parent.add_child( node, index );
    selected = node;
    queue_draw();
    changed();
    see( node );
  }

  /* Replaces the current row with the specified row */
  public void replace_node( Node orig_node, Node new_node ) {
    var was_selected = (orig_node == selected);
    var parent       = orig_node.parent;
    var index        = orig_node.index();
    parent.remove_child( orig_node );
    parent.add_child( new_node, index );
    if( was_selected ) {
      selected = new_node;
    }
  }

  /* Adds a sibling node of the currently selected node */
  public void add_sibling_node( bool below, string? title = null, Array<UndoTagInfo>? tags = null ) {
    if( (selected == null) || selected.is_root() ) return;
    var index = selected.index() + (below ? 1 : 0);
    var sel   = selected;
    var node  = create_node( title, tags );
    insert_node( sel.parent, node, index );
    set_node_mode( selected, NodeMode.EDITABLE );
    undo_buffer.add_item( new UndoNodeInsert( node ) );
  }

  /* Adds a child node of the currently selected node */
  public void add_child_node( int index = -1 ) {
    if( selected == null ) return;
    if( index == -1 ) {
      index = (int)selected.children.length;
    }
    var sel  = selected;
    var node = create_node();
    insert_node( sel, node, index );
    set_node_mode( selected, NodeMode.EDITABLE );
    undo_buffer.add_item( new UndoNodeInsert( node ) );
  }

  /* Removes the specified node from the table */
  public void delete_node( Node node ) {
    var was_selected = (node == selected);
    var next         = node.get_next_sibling() ?? node.get_previous_node();
    node.parent.remove_child( node );
    if( was_selected ) {
      selected = next;
    }
    queue_draw();
    changed();
    see( next );
  }

  /* Removes the selected node from the table */
  public void delete_current_node() {
    if( selected == null ) return;
    if( (root.children.length == 1) && (selected == root.children.index( 0 )) ) {
      var node = new Node( this );
      undo_buffer.add_item( new UndoNodeDelete( selected, node ) );
      delete_node( selected );
      insert_node( root, node, 0 );
      set_node_mode( selected, NodeMode.EDITABLE );
    } else {
      undo_buffer.add_item( new UndoNodeDelete( selected, null ) );
      delete_node( selected );
    }
    queue_draw();
    changed();
  }

  /* Returns true if the currently selected row is indentable */
  public bool indentable() {
    return( (selected != null) && (selected.index() > 0) );
  }

  /* Returns true if the currently selected row is unindentable */
  public bool unindentable() {
    return( (selected != null) && !selected.parent.is_root() );
  }

  /* Returns true if a node has been cloned that can be pasted */
  public bool cloneable() {
    return( _clone != null );
  }

  /*
   Indents the specified node such that it becomes the child of the sibling
   node above it.
  */
  public void indent_node( Node node ) {
    var index = node.index();
    if( index == 0 ) return;
    var parent = node.parent;
    parent.remove_child( node );
    parent.children.index( index - 1 ).add_child( node );
    queue_draw();
    changed();
  }

  /*
   Indents the currently selected row such that it becomes the child of the
   sibling row above it
  */
  public void indent() {
    if( selected == null ) return;
    undo_buffer.add_item( new UndoNodeIndent( selected ) );
    indent_node( selected );
  }

  /*
   Removes the specified node from its parent and places itself just below its
   parent.
  */
  public void unindent_node( Node node ) {
    if( node.parent.is_root() ) return;
    var parent       = node.parent;
    var index        = node.index();
    var parent_index = parent.index();
    var grandparent  = parent.parent;
    parent.remove_child( node );
    grandparent.add_child( node, (parent_index + 1) );
    var num_siblings = parent.children.length;
    for( int i=index; i<num_siblings; i++ ) {
      var child = parent.children.index( index );
      parent.remove_child( child );
      node.add_child( child, -1 );
    }
    see( selected );
    queue_draw();
    changed();
  }

  /*
   Removes the currently selected row from its parent and places itself just
   below its parent.
  */
  public void unindent() {
    if( selected == null ) return;
    undo_buffer.add_item( new UndoNodeUnindent( selected ) );
    unindent_node( selected );
  }

  /* Set the notes display for all nodes to the given value */
  public void set_notes_display( bool show ) {
    root.set_notes_display( show );
    root.children.index( 0 ).adjust_nodes( root.children.index( 0 ).last_y, false, "set_notes_display" );
    see( selected );
    queue_draw();
    changed();
  }

  /*******************/
  /* DRAWING METHODS */
  /*******************/

  /* Draw the available nodes */
  public void on_draw( DrawingArea da, Context ctx, int width, int height ) {
    draw_background( ctx );
    draw_exit_focus_mode( ctx );
    draw_all( ctx );
  }

  /* Draw the background from the stylesheet */
  private void draw_background( Context ctx ) {
    get_style_context().render_background( ctx, 0, 0, get_allocated_width(), get_allocated_height() );
  }

  /* Returns true if the coordinates are within the focus exit */
  private bool is_within_focus_exit( double x, double y ) {
    if( win.settings.get_boolean( "focus-mode" ) ) {
      var width = get_allocated_width();
      return( Utils.is_within_bounds( x, y, (width - 45), 15, 30, 30 ) );
    }
    return( false );
  }

  /* Draws the focus mode exit icon */
  private void draw_exit_focus_mode( Context ctx ) {
    if( win.settings.get_boolean( "focus-mode" ) ) {
      var width = get_allocated_width();
      Utils.set_context_color_with_alpha( ctx, _theme.symbol_color, (_in_focus_exit ? 1.0 : 0.5) );
      ctx.set_line_width( 4 );
      ctx.arc( (width - 30), 30, 15, 0, (2 * Math.PI) );
      ctx.move_to( (width - 35), 25 );
      ctx.line_to( (width - 25), 35 );
      ctx.move_to( (width - 25), 25 );
      ctx.line_to( (width - 35), 35 );
      ctx.stroke();
    }
  }

  /* Draws the document suitable for printing */
  public void print_all( Context ctx, bool include_title, Theme theme, NodeDrawOptions draw_options ) {
    if( include_title && (_title != null) ) {
      _title.draw( ctx, theme, theme.title_foreground, 1.0, draw_options.use_theme );
    }
    root.draw_tree( ctx, theme, draw_options );
  }

  /* Draws all of the root node trees */
  public void draw_all( Context ctx ) {
    if( _title != null ) {
      _title.draw( ctx, _theme, _theme.title_foreground, 1.0, _draw_options.use_theme );
    }
    root.draw_tree( ctx, _theme, _draw_options );
    if( (selected != null) && !selected.hidden ) {
      selected.draw( ctx, _theme, _draw_options );
    }
    _labels.draw( ctx, _theme );
  }

}

