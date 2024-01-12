using Gtk;

/* Meant to be a replacement for the Granite.Widgets.ModeButton class */
public class ModeGroup : Box {

  private Array<ToggleButton> _buttons;

  public int selected {
    get {
      return( get_active_button() );
    }
    set {
      set_active_button( value );
    }
  }

  public signal void changed();

  /* Constructor */
  public ModeGroup() {
    Object( orientation: Orientation.HORIZONTAL, spacing: 0 );
    _buttons = new Array<ToggleButton>();
  }

  /* Adds the given mode button to the current list */
  private void add_mode_button( ToggleButton button, string? tooltip ) {
    if( tooltip != null ) {
      button.set_tooltip_text( tooltip );
    }
    button.set_group( (_buttons.length == 0) ? null : _buttons.index( 0 ) );
    button.notify["active"].connect(() => {
      if( button.active ) {
        changed();
      }
    });
    _buttons.append_val( button );
    append( button );
  }

  /* Adds a mode button with the given text */
  public void add_mode_text( string text, string? tooltip = null ) {
    var button = new ToggleButton() {
      label = text
    };
    add_mode_button( button, tooltip );
  }

  /* Adds a mode button with the given icon name */
  public void add_mode_image( string name, string? tooltip = null ) {
    var button = new ToggleButton() {
      icon_name = name
    };
    add_mode_button( button, tooltip );
  }

  /* Returns the index of the currently active mode */
  private int get_active_button() {
    for( int i=0; i<_buttons.length; i++ ) {
      var button = _buttons.index( i );
      if( button.active ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Set the mode to the current index */
  private void set_active_button( int index ) {
    _buttons.index( index ).active = true;
  }

}
