/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

using Gee;
using Gtk;

public delegate void KeyCommandFunc( OutlineTable ot );

public enum KeyCommand {
  DO_NOTHING,
  GENERAL_START,
    FILE_START,
      FILE_NEW,
      FILE_OPEN,
      FILE_SAVE,
      FILE_SAVE_AS,
      FILE_PRINT,
    FILE_END,
    TAB_START,
      TAB_GOTO_NEXT,  // 10
      TAB_GOTO_PREV,
      TAB_CLOSE_CURRENT,
    TAB_END,
    UNDO_START,
      UNDO_ACTION,
      REDO_ACTION,
    UNDO_END,
    ZOOM_START,
      ZOOM_IN,
      ZOOM_OUT,  // 20
      ZOOM_ACTUAL,
    ZOOM_END,
    MISCELLANEOUS_START,
      SHOW_PREFERENCES,
      SHOW_SHORTCUTS,
      SHOW_CONTEXTUAL_MENU,
      SEARCH,
      SHOW_ABOUT,
      TOGGLE_FOCUS_MODE,
      EDIT_NOTE,  // 30
      EDIT_SELECTED,
      QUIT,
    MISCELLANEOUS_END,
    CONTROL_PRESSED,
    ESCAPE,
  GENERAL_END,
  NODE_START,
    NODE_EXIST_START,
    NODE_EXIST_END,
    NODE_CLIPBOARD_START,  // 40
      NODE_PASTE_REPLACE,
    NODE_CLIPBOARD_END,
    NODE_VIEW_START,
      NODE_EXPAND_ONE,
      NODE_EXPAND_ALL,
      NODE_COLLAPSE_ONE,
      NODE_COLLAPSE_ALL,
    NODE_VIEW_END,
    NODE_CHANGE_START,
    NODE_CHANGE_END,  // 50
    NODE_SELECT_START,
      NODE_SELECT_TOP,
      NODE_SELECT_BOTTOM,
      NODE_SELECT_PAGE_TOP,
      NODE_SELECT_PAGE_BOTTOM,
      NODE_SELECT_DOWN,
      NODE_SELECT_UP,
      NODE_SELECT_PARENT,
      NODE_SELECT_LAST_CHILD,
      NODE_SELECT_NEXT_SIBLING,  // 60
      NODE_SELECT_PREV_SIBLING,
    NODE_SELECT_END,
    NODE_MOVE_START,
      NODE_INDENT,
      NODE_UNINDENT,
      NODE_MOVE_UP,
      NODE_MOVE_DOWN,
      NODE_MOVE_TO_LABEL_1,
      NODE_MOVE_TO_LABEL_2,
      NODE_MOVE_TO_LABEL_3,
      NODE_MOVE_TO_LABEL_4,
      NODE_MOVE_TO_LABEL_5,
      NODE_MOVE_TO_LABEL_6,
      NODE_MOVE_TO_LABEL_7,
      NODE_MOVE_TO_LABEL_8,
      NODE_MOVE_TO_LABEL_9,
    NODE_MOVE_END,
    NODE_LABEL_START,
      NODE_LABEL_TOGGLE,  // 70
      NODE_LABEL_CLEAR_ALL,
      NODE_LABEL_GOTO_1,
      NODE_LABEL_GOTO_2,
      NODE_LABEL_GOTO_3,
      NODE_LABEL_GOTO_4,
      NODE_LABEL_GOTO_5,
      NODE_LABEL_GOTO_6,
      NODE_LABEL_GOTO_7,
      NODE_LABEL_GOTO_8,
      NODE_LABEL_GOTO_9,
    NODE_LABEL_END,
  NODE_END,
  EDIT_START,
    EDIT_TEXT_START,
      EDIT_INSERT_NEWLINE,
      EDIT_SPLIT_LINE,
      EDIT_INSERT_TAB,
      EDIT_INSERT_EMOJI,
      EDIT_ESCAPE,
      EDIT_BACKSPACE,
      EDIT_DELETE,  // 160
      EDIT_REMOVE_WORD_NEXT,
      EDIT_REMOVE_WORD_PREV,
    EDIT_TEXT_END,
    EDIT_CLIPBOARD_START,
      EDIT_COPY,
      EDIT_CUT,
      EDIT_PASTE,
    EDIT_CLIPBOARD_END,
    EDIT_URL_START,
      EDIT_OPEN_URL,  // 170
      EDIT_ADD_URL,
      EDIT_EDIT_URL,
      EDIT_REMOVE_URL,
    EDIT_URL_END,
    EDIT_CURSOR_START,
      EDIT_CURSOR_CHAR_NEXT,
      EDIT_CURSOR_CHAR_PREV,
      EDIT_CURSOR_UP,
      EDIT_CURSOR_DOWN,  // 150
      EDIT_CURSOR_WORD_NEXT,
      EDIT_CURSOR_WORD_PREV,
      EDIT_CURSOR_FIRST,
      EDIT_CURSOR_LAST,
      EDIT_CURSOR_LINESTART,
      EDIT_CURSOR_LINEEND,
    EDIT_CURSOR_END,
    EDIT_SELECT_START,
      EDIT_SELECT_CHAR_NEXT,
      EDIT_SELECT_CHAR_PREV,  // 160
      EDIT_SELECT_UP,
      EDIT_SELECT_DOWN,
      EDIT_SELECT_WORD_NEXT,
      EDIT_SELECT_WORD_PREV,
      EDIT_SELECT_START_UP,
      EDIT_SELECT_START_HOME,
      EDIT_SELECT_END_DOWN,
      EDIT_SELECT_END_END,
      EDIT_SELECT_LINESTART,
      EDIT_SELECT_LINEEND,  // 170
      EDIT_SELECT_ALL,
      EDIT_SELECT_NONE,
    EDIT_SELECT_END,
    EDIT_MISC_START,
      EDIT_RETURN,
      EDIT_SHIFT_RETURN,
      EDIT_TAB,
      EDIT_SHIFT_TAB,
    EDIT_MISC_END,
  EDIT_END,  // 180
  NUM;

  //-------------------------------------------------------------
  // Returns the string version of this key command.
  public string to_string() {
    switch( this ) {
      case DO_NOTHING                :  return( "none" );
      case GENERAL_START             :  return( "general" );
      case FILE_NEW                  :  return( "file-new" );
      case FILE_OPEN                 :  return( "file-open" );
      case FILE_SAVE                 :  return( "file-save" );
      case FILE_SAVE_AS              :  return( "file-save-as" );
      case FILE_PRINT                :  return( "file-print" );
      case TAB_GOTO_NEXT             :  return( "tab-goto-next" );
      case TAB_GOTO_PREV             :  return( "tab-goto-prev" );
      case TAB_CLOSE_CURRENT         :  return( "tab-close-current" );
      case UNDO_ACTION               :  return( "undo-action" );
      case REDO_ACTION               :  return( "redo-action" );
      case ZOOM_IN                   :  return( "zoom-in" );
      case ZOOM_OUT                  :  return( "zoom-out" );
      case ZOOM_ACTUAL               :  return( "zoom-actual" );
      case SHOW_PREFERENCES          :  return( "show-preferences" );
      case SHOW_SHORTCUTS            :  return( "show-shortcuts" );
      case SHOW_CONTEXTUAL_MENU      :  return( "show-contextual_menu" );
      case SEARCH                    :  return( "search" );
      case SHOW_ABOUT                :  return( "show-about" );
      case TOGGLE_FOCUS_MODE         :  return( "toggle-focus-mode" );
      case EDIT_NOTE                 :  return( "edit-note" );
      case EDIT_SELECTED             :  return( "edit-selected" );
      case QUIT                      :  return( "quit" );
      case CONTROL_PRESSED           :  return( "control" );
      case ESCAPE                    :  return( "escape" );
      case NODE_START                :  return( "node" );
      /*
      case NODE_ADD_ROOT             :  return( "node-add-root" );
      case NODE_ADD_SIBLING_AFTER    :  return( "node-return" );
      case NODE_ADD_SIBLING_BEFORE   :  return( "node-shift-return" );
      case NODE_ADD_CHILD            :  return( "node-tab" );
      case NODE_ADD_PARENT           :  return( "node-shift-tab" );
      case NODE_REMOVE               :  return( "node-remove" );
      case NODE_REMOVE_ONLY          :  return( "node-remove-only" );
      */
      case NODE_PASTE_REPLACE        :  return( "node-paste-replace" );
      // case NODE_CENTER               :  return( "node-center" );
      case NODE_EXPAND_ONE           :  return( "node-expand-one" );
      case NODE_EXPAND_ALL           :  return( "node-expand-all" );
      case NODE_COLLAPSE_ONE         :  return( "node-collapse-one" );
      case NODE_COLLAPSE_ALL         :  return( "node-collapse-all" );
      // case NODE_CHANGE_TASK          :  return( "node-change-task" );
      case NODE_SELECT_TOP           :  return( "node-select-top" );
      case NODE_SELECT_BOTTOM        :  return( "node-select-bottom" );
      case NODE_SELECT_PAGE_TOP      :  return( "node-select-page-top" );
      case NODE_SELECT_PAGE_BOTTOM   :  return( "node-select-page-bottom" );
      case NODE_SELECT_DOWN          :  return( "node-select-down" );
      case NODE_SELECT_UP            :  return( "node-select-up" );
      case NODE_SELECT_PARENT        :  return( "node-select-parent" );
      case NODE_SELECT_LAST_CHILD    :  return( "node-select-last-child" );
      case NODE_SELECT_NEXT_SIBLING  :  return( "node-select-next-sibling" );
      case NODE_SELECT_PREV_SIBLING  :  return( "node-select-prev-sibling" );
      case NODE_INDENT               :  return( "node-indent" );
      case NODE_UNINDENT             :  return( "node-unindent" );
      case NODE_MOVE_UP              :  return( "node-move-up" );
      case NODE_MOVE_DOWN            :  return( "node-move-down" );
      case NODE_MOVE_TO_LABEL_1      :  return( "node-move-to-label-1" );
      case NODE_MOVE_TO_LABEL_2      :  return( "node-move-to-label-2" );
      case NODE_MOVE_TO_LABEL_3      :  return( "node-move-to-label-3" );
      case NODE_MOVE_TO_LABEL_4      :  return( "node-move-to-label-4" );
      case NODE_MOVE_TO_LABEL_5      :  return( "node-move-to-label-5" );
      case NODE_MOVE_TO_LABEL_6      :  return( "node-move-to-label-6" );
      case NODE_MOVE_TO_LABEL_7      :  return( "node-move-to-label-7" );
      case NODE_MOVE_TO_LABEL_8      :  return( "node-move-to-label-8" );
      case NODE_MOVE_TO_LABEL_9      :  return( "node-move-to-label-9" );
      case NODE_LABEL_TOGGLE         :  return( "node-label-toggle" );
      case NODE_LABEL_CLEAR_ALL      :  return( "node-label-clear-all" );
      case NODE_LABEL_GOTO_1         :  return( "node-label-goto-1" );
      case NODE_LABEL_GOTO_2         :  return( "node-label-goto-2" );
      case NODE_LABEL_GOTO_3         :  return( "node-label-goto-3" );
      case NODE_LABEL_GOTO_4         :  return( "node-label-goto-4" );
      case NODE_LABEL_GOTO_5         :  return( "node-label-goto-5" );
      case NODE_LABEL_GOTO_6         :  return( "node-label-goto-6" );
      case NODE_LABEL_GOTO_7         :  return( "node-label-goto-7" );
      case NODE_LABEL_GOTO_8         :  return( "node-label-goto-8" );
      case NODE_LABEL_GOTO_9         :  return( "node-label-goto-9" );
      /*
      case NODE_SWAP_RIGHT           :  return( "node-swap-right" );
      case NODE_SWAP_LEFT            :  return( "node-swap-left" );
      case NODE_SWAP_UP              :  return( "node-swap-up" );
      case NODE_SWAP_DOWN            :  return( "node-swap-down" );
      case NODE_SORT_ALPHABETICALLY  :  return( "node-sort-alphabetically" );
      case NODE_SORT_RANDOMLY        :  return( "node-sort-randomly" );
      case NODE_DETACH               :  return( "node-detach" );
      */
      case EDIT_START                :  return( "editing" );
      case EDIT_INSERT_NEWLINE       :  return( "edit-insert-newline" );
      case EDIT_SPLIT_LINE           :  return( "edit-split-line" );
      case EDIT_INSERT_TAB           :  return( "edit-insert-tab" );
      case EDIT_INSERT_EMOJI         :  return( "edit-insert-emoji" );
      case EDIT_ESCAPE               :  return( "edit-escape" );
      case EDIT_BACKSPACE            :  return( "edit-backspace" );
      case EDIT_DELETE               :  return( "edit-delete" );
      case EDIT_REMOVE_WORD_NEXT     :  return( "edit-remove-word-next" );
      case EDIT_REMOVE_WORD_PREV     :  return( "edit-remove-word-prev" );
      case EDIT_COPY                 :  return( "edit-copy" );
      case EDIT_CUT                  :  return( "edit-cut" );
      case EDIT_PASTE                :  return( "edit-paste" );
      case EDIT_OPEN_URL             :  return( "edit-open-url" );
      case EDIT_ADD_URL              :  return( "edit-add-url" );
      case EDIT_EDIT_URL             :  return( "edit-edit-url" );
      case EDIT_REMOVE_URL           :  return( "edit-remove-url" );
      case EDIT_CURSOR_CHAR_NEXT     :  return( "edit-cursor-char-next" );
      case EDIT_CURSOR_CHAR_PREV     :  return( "edit-cursor-char-prev" );
      case EDIT_CURSOR_UP            :  return( "edit-cursor-up" );
      case EDIT_CURSOR_DOWN          :  return( "edit-cursor-down" );
      case EDIT_CURSOR_WORD_NEXT     :  return( "edit-cursor-word-next" );
      case EDIT_CURSOR_WORD_PREV     :  return( "edit-cursor-word-prev" );
      case EDIT_CURSOR_FIRST         :  return( "edit-cursor-first" );
      case EDIT_CURSOR_LAST          :  return( "edit-cursor-last" );
      case EDIT_CURSOR_LINESTART     :  return( "edit-cursor-linestart" );
      case EDIT_CURSOR_LINEEND       :  return( "edit-cursor-lineend" );
      case EDIT_SELECT_CHAR_NEXT     :  return( "edit-select-char-next" );
      case EDIT_SELECT_CHAR_PREV     :  return( "edit-select-char-prev" );
      case EDIT_SELECT_UP            :  return( "edit-select-up" );
      case EDIT_SELECT_DOWN          :  return( "edit-select-down" );
      case EDIT_SELECT_WORD_NEXT     :  return( "edit-select-word-next" );
      case EDIT_SELECT_WORD_PREV     :  return( "edit-select-word-prev" );
      case EDIT_SELECT_START_UP      :  return( "edit-select-start_up" );
      case EDIT_SELECT_START_HOME    :  return( "edit-select-start_home" );
      case EDIT_SELECT_END_DOWN      :  return( "edit-select-end_down" );
      case EDIT_SELECT_END_END       :  return( "edit-select-end_end" );
      case EDIT_SELECT_LINESTART     :  return( "edit-select-linestart" );
      case EDIT_SELECT_LINEEND       :  return( "edit-select-lineend" );
      case EDIT_SELECT_ALL           :  return( "edit-select-all" );
      case EDIT_SELECT_NONE          :  return( "edit-select-none" );
      case EDIT_RETURN               :  return( "edit-return" );
      case EDIT_SHIFT_RETURN         :  return( "edit-shift-return" );
      case EDIT_TAB                  :  return( "edit-tab" );
      case EDIT_SHIFT_TAB            :  return( "edit-shift-tab" );
      default                        :  stdout.printf( "unhandled: %d\n", this );  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Parses the given string and returns the associated key command
  // enumerated value.
  public static KeyCommand parse( string str ) {
    switch( str ) {
      case "file-new"                  :  return( FILE_NEW );
      case "file-open"                 :  return( FILE_OPEN );
      case "file-save"                 :  return( FILE_SAVE );
      case "file-save-as"              :  return( FILE_SAVE_AS );
      case "file-print"                :  return( FILE_PRINT );
      case "tab-goto-next"             :  return( TAB_GOTO_NEXT );
      case "tab-goto-prev"             :  return( TAB_GOTO_PREV );
      case "tab-close-current"         :  return( TAB_CLOSE_CURRENT );
      case "undo-action"               :  return( UNDO_ACTION );
      case "redo-action"               :  return( REDO_ACTION );
      case "zoom-in"                   :  return( ZOOM_IN );
      case "zoom-out"                  :  return( ZOOM_OUT );
      case "zoom-actual"               :  return( ZOOM_ACTUAL );
      case "show-preferences"          :  return( SHOW_PREFERENCES );
      case "show-shortcuts"            :  return( SHOW_SHORTCUTS );
      case "show-contextual-menu"      :  return( SHOW_CONTEXTUAL_MENU );
      case "search"                    :  return( SEARCH );
      case "show-about"                :  return( SHOW_ABOUT );
      case "toggle-focus-mode"         :  return( TOGGLE_FOCUS_MODE );
      case "edit-note"                 :  return( EDIT_NOTE );
      case "edit-selected"             :  return( EDIT_SELECTED );
      case "quit"                      :  return( QUIT );
      case "control"                   :  return( CONTROL_PRESSED );
      case "escape"                    :  return( ESCAPE );
      /*
      case "node-add-root"             :  return( NODE_ADD_ROOT );
      case "node-return"               :  return( NODE_ADD_SIBLING_AFTER );
      case "node-shift-return"         :  return( NODE_ADD_SIBLING_BEFORE );
      case "node-tab"                  :  return( NODE_ADD_CHILD );
      case "node-shift-tab"            :  return( NODE_ADD_PARENT );
      case "node-remove"               :  return( NODE_REMOVE );
      case "node-remove-only"          :  return( NODE_REMOVE_ONLY );
      case "node-center"               :  return( NODE_CENTER );
      */
      case "node-paste-replace"        :  return( NODE_PASTE_REPLACE );
      case "node-expand-one"           :  return( NODE_EXPAND_ONE );
      case "node-expand-all"           :  return( NODE_EXPAND_ALL );
      case "node-collapse-one"         :  return( NODE_COLLAPSE_ONE );
      case "node-collapse-all"         :  return( NODE_COLLAPSE_ALL );
      // case "node-change-task"          :  return( NODE_CHANGE_TASK );
      case "node-select-top"           :  return( NODE_SELECT_TOP );
      case "node-select-bottom"        :  return( NODE_SELECT_BOTTOM );
      case "node-select-page-top"      :  return( NODE_SELECT_PAGE_TOP );
      case "node-select-page-bottom"   :  return( NODE_SELECT_PAGE_BOTTOM );
      case "node-select-down"          :  return( NODE_SELECT_DOWN );
      case "node-select-up"            :  return( NODE_SELECT_UP );
      case "node-select-parent"        :  return( NODE_SELECT_PARENT );
      case "node-select-last-child"    :  return( NODE_SELECT_LAST_CHILD );
      case "node-select-next-sibling"  :  return( NODE_SELECT_NEXT_SIBLING );
      case "node-select-prev-sibling"  :  return( NODE_SELECT_PREV_SIBLING );
      case "node-indent"               :  return( NODE_INDENT );
      case "node-unindent"             :  return( NODE_UNINDENT );
      case "node-move-down"            :  return( NODE_MOVE_DOWN );
      case "node-move-up"              :  return( NODE_MOVE_UP );
      case "node-move-to-label-1"      :  return( NODE_MOVE_TO_LABEL_1 );
      case "node-move-to-label-2"      :  return( NODE_MOVE_TO_LABEL_2 );
      case "node-move-to-label-3"      :  return( NODE_MOVE_TO_LABEL_3 );
      case "node-move-to-label-4"      :  return( NODE_MOVE_TO_LABEL_4 );
      case "node-move-to-label-5"      :  return( NODE_MOVE_TO_LABEL_5 );
      case "node-move-to-label-6"      :  return( NODE_MOVE_TO_LABEL_6 );
      case "node-move-to-label-7"      :  return( NODE_MOVE_TO_LABEL_7 );
      case "node-move-to-label-8"      :  return( NODE_MOVE_TO_LABEL_8 );
      case "node-move-to-label-9"      :  return( NODE_MOVE_TO_LABEL_9 );
      case "node-label-toggle"         :  return( NODE_LABEL_TOGGLE );
      case "node-label-clear-all"      :  return( NODE_LABEL_CLEAR_ALL );
      case "node-label-goto-1"         :  return( NODE_LABEL_GOTO_1 );
      case "node-label-goto-2"         :  return( NODE_LABEL_GOTO_2 );
      case "node-label-goto-3"         :  return( NODE_LABEL_GOTO_3 );
      case "node-label-goto-4"         :  return( NODE_LABEL_GOTO_4 );
      case "node-label-goto-5"         :  return( NODE_LABEL_GOTO_5 );
      case "node-label-goto-6"         :  return( NODE_LABEL_GOTO_6 );
      case "node-label-goto-7"         :  return( NODE_LABEL_GOTO_7 );
      case "node-label-goto-8"         :  return( NODE_LABEL_GOTO_8 );
      case "node-label-goto-9"         :  return( NODE_LABEL_GOTO_9 );
      /*
      case "node-swap-right"           :  return( NODE_SWAP_RIGHT );
      case "node-swap-left"            :  return( NODE_SWAP_LEFT );
      case "node-swap-up"              :  return( NODE_SWAP_UP );
      case "node-swap-down"            :  return( NODE_SWAP_DOWN );
      case "node-sort-alphabetically"  :  return( NODE_SORT_ALPHABETICALLY );
      case "node-sort-randomly"        :  return( NODE_SORT_RANDOMLY );
      */
      case "edit-insert-newline"       :  return( EDIT_INSERT_NEWLINE );
      case "edit-split-line"           :  return( EDIT_SPLIT_LINE );
      case "edit-insert-tab"           :  return( EDIT_INSERT_TAB );
      case "edit-insert-emoji"         :  return( EDIT_INSERT_EMOJI );
      case "edit-escape"               :  return( EDIT_ESCAPE );
      case "edit-backspace"            :  return( EDIT_BACKSPACE );
      case "edit-delete"               :  return( EDIT_DELETE );
      case "edit-remove-word-next"     :  return( EDIT_REMOVE_WORD_NEXT );
      case "edit-remove-word-prev"     :  return( EDIT_REMOVE_WORD_PREV );
      case "edit-copy"                 :  return( EDIT_COPY );
      case "edit-cut"                  :  return( EDIT_CUT );
      case "edit-paste"                :  return( EDIT_PASTE );
      case "edit-open-url"             :  return( EDIT_OPEN_URL );
      case "edit-add-url"              :  return( EDIT_ADD_URL );
      case "edit-edit-url"             :  return( EDIT_EDIT_URL );
      case "edit-remove-url"           :  return( EDIT_REMOVE_URL );
      case "edit-cursor-char-next"     :  return( EDIT_CURSOR_CHAR_NEXT );
      case "edit-cursor-char-prev"     :  return( EDIT_CURSOR_CHAR_PREV );
      case "edit-cursor-up"            :  return( EDIT_CURSOR_UP );
      case "edit-cursor-down"          :  return( EDIT_CURSOR_DOWN );
      case "edit-cursor-word-next"     :  return( EDIT_CURSOR_WORD_NEXT );
      case "edit-cursor-word-prev"     :  return( EDIT_CURSOR_WORD_PREV );
      case "edit-cursor-first"         :  return( EDIT_CURSOR_FIRST );
      case "edit-cursor-last"          :  return( EDIT_CURSOR_LAST );
      case "edit-cursor-linestart"     :  return( EDIT_CURSOR_LINESTART );
      case "edit-cursor-lineend"       :  return( EDIT_CURSOR_LINEEND );
      case "edit-select-char-next"     :  return( EDIT_SELECT_CHAR_NEXT );
      case "edit-select-char-prev"     :  return( EDIT_SELECT_CHAR_PREV );
      case "edit-select-up"            :  return( EDIT_SELECT_UP );
      case "edit-select-down"          :  return( EDIT_SELECT_DOWN );
      case "edit-select-word-next"     :  return( EDIT_SELECT_WORD_NEXT );
      case "edit-select-word-prev"     :  return( EDIT_SELECT_WORD_PREV );
      case "edit-select-start-up"      :  return( EDIT_SELECT_START_UP );
      case "edit-select-start-home"    :  return( EDIT_SELECT_START_HOME );
      case "edit-select-end-down"      :  return( EDIT_SELECT_END_DOWN );
      case "edit-select-end-end"       :  return( EDIT_SELECT_END_END );
      case "edit-select-linestart"     :  return( EDIT_SELECT_LINESTART );
      case "edit-select-lineend"       :  return( EDIT_SELECT_LINEEND );
      case "edit-select_all"           :  return( EDIT_SELECT_ALL );
      case "edit-select-none"          :  return( EDIT_SELECT_NONE );
      case "edit-return"               :  return( EDIT_RETURN );
      case "edit-shift-return"         :  return( EDIT_SHIFT_RETURN );
      case "edit-tab"                  :  return( EDIT_TAB );
      case "edit-shift-tab"            :  return( EDIT_SHIFT_TAB );
      default                          :  return( DO_NOTHING );
    }
  }

  //-------------------------------------------------------------
  // Returns the label to display in the shortcut preferences for
  // this key command.
  public string shortcut_label() {
    switch( this ) {
      case GENERAL_START             :  return( _( "General" ) );
      case FILE_START                :  return( _( "File Commands" ) );
      case FILE_NEW                  :  return( _( "Create new outline" ) );
      case FILE_OPEN                 :  return( _( "Open saved outline" ) );
      case FILE_SAVE                 :  return( _( "Save outline to current file" ) );
      case FILE_SAVE_AS              :  return( _( "Save outline to new file" ) );
      case FILE_PRINT                :  return( _( "Show print dialog for current outline" ) );
      case TAB_START                 :  return( _( "Tab Commands" ) );
      case TAB_GOTO_NEXT             :  return( _( "Select next tab" ) );
      case TAB_GOTO_PREV             :  return( _( "Select previous tab" ) );
      case TAB_CLOSE_CURRENT         :  return( _( "Close the current mindmap" ) );
      case UNDO_START                :  return( _( "Undo/Redo Commands" ) );
      case UNDO_ACTION               :  return( _( "Undo last action" ) );
      case REDO_ACTION               :  return( _( "Redo last undone action" ) );
      case ZOOM_START                :  return( _( "Zoom Commands" ) );
      case ZOOM_IN                   :  return( _( "Zoom in" ) );
      case ZOOM_OUT                  :  return( _( "Zoom out" ) );
      case ZOOM_ACTUAL               :  return( _( "Zoom to 100%" ) );
      case MISCELLANEOUS_START       :  return( _( "Miscellaneous Commands" ) );
      case SHOW_PREFERENCES          :  return( _( "Show preferences window" ) );
      case SHOW_SHORTCUTS            :  return( _( "Show shortcuts cheatsheet" ) );
      case SHOW_CONTEXTUAL_MENU      :  return( _( "Show contextual menu" ) );
      case SEARCH                    :  return( _( "Display search panel" ) );
      case SHOW_ABOUT                :  return( _( "Show About window" ) );
      case TOGGLE_FOCUS_MODE         :  return( _( "Toggle focus mode" ) );
      case EDIT_NOTE                 :  return( _( "Edit the selected node note" ) );
      case EDIT_SELECTED             :  return( _( "Edit the currently selected node" ) );
      case QUIT                      :  return( _( "Quit the application" ) );
      case NODE_START                :  return( _( "Node" ) );
      case NODE_EXIST_START          :  return( _( "Creation/Deletion Commands" ) );
      case NODE_CLIPBOARD_START      :  return( _( "Clipboard Commands" ) );
      /*
      case NODE_ADD_ROOT             :  return( _( "Add root node" ) );
      case NODE_ADD_SIBLING_AFTER    :  return( _( "Add sibling node after current node" ) );
      case NODE_ADD_SIBLING_BEFORE   :  return( _( "Add sibling node before current node" ) );
      case NODE_ADD_CHILD            :  return( _( "Add child node to current node" ) );
      case NODE_ADD_PARENT           :  return( _( "Add parent node to current node" ) );
      case NODE_REMOVE_ONLY          :  return( _( "Remove selected node only (leave subtree)" ) );
      case NODE_CLIPBOARD_START      :  return( _( "Clipboard Commands" ) );
      */
      case NODE_PASTE_REPLACE        :  return( _( "Replace current row with clipboard content") );
      case NODE_VIEW_START           :  return( _( "View Commands" ) );
      // case NODE_CENTER               :  return( _( "Center current node in map canvas" ) );
      case NODE_EXPAND_ONE           :  return( _( "Expand current row by one level" ) );
      case NODE_EXPAND_ALL           :  return( _( "Expand current row completely" ) );
      case NODE_COLLAPSE_ONE         :  return( _( "Collapse current row by one level" ) );
      case NODE_COLLAPSE_ALL         :  return( _( "Collapse current row completely" ) );
      case NODE_CHANGE_START         :  return( _( "Change Commands" ) );
      // case NODE_CHANGE_TASK          :  return( _( "Change task status of current node" ) );
      case NODE_SELECT_START         :  return( _( "Selection Commands" ) );
      case NODE_SELECT_TOP           :  return( _( "Select top-most row" ) );
      case NODE_SELECT_BOTTOM        :  return( _( "Select bottom-most row" ) );
      case NODE_SELECT_PAGE_TOP      :  return( _( "Select row at the top of the current view" ) );
      case NODE_SELECT_PAGE_BOTTOM   :  return( _( "Select row at the bottom of the current view" ) );
      case NODE_SELECT_DOWN          :  return( _( "Select row below the current row" ) );
      case NODE_SELECT_UP            :  return( _( "Select row above the current row" ) );
      case NODE_SELECT_PARENT        :  return( _( "Select parent of current row" ) );
      case NODE_SELECT_LAST_CHILD    :  return( _( "Select last child row of current row" ) );
      case NODE_SELECT_NEXT_SIBLING  :  return( _( "Select next sibling row of current row" ) );
      case NODE_SELECT_PREV_SIBLING  :  return( _( "Select previous sibling row of current row" ) );
      case NODE_MOVE_START           :  return( _( "Move Commands" ) );
      case NODE_INDENT               :  return( _( "Indent currently selected row" ) );
      case NODE_UNINDENT             :  return( _( "Unindent currently selected row" ) );
      case NODE_MOVE_DOWN            :  return( _( "Move current row down" ) );
      case NODE_MOVE_UP              :  return( _( "Move current row up" ) );
      case NODE_MOVE_TO_LABEL_1      :  return( _( "Move current row to label 1" ) );
      case NODE_MOVE_TO_LABEL_2      :  return( _( "Move current row to label 2" ) );
      case NODE_MOVE_TO_LABEL_3      :  return( _( "Move current row to label 3" ) );
      case NODE_MOVE_TO_LABEL_4      :  return( _( "Move current row to label 4" ) );
      case NODE_MOVE_TO_LABEL_5      :  return( _( "Move current row to label 5" ) );
      case NODE_MOVE_TO_LABEL_6      :  return( _( "Move current row to label 6" ) );
      case NODE_MOVE_TO_LABEL_7      :  return( _( "Move current row to label 7" ) );
      case NODE_MOVE_TO_LABEL_8      :  return( _( "Move current row to label 8" ) );
      case NODE_MOVE_TO_LABEL_9      :  return( _( "Move current row to label 9" ) );
      case NODE_LABEL_START          :  return( _( "Label Commands" ) );
      case NODE_LABEL_TOGGLE         :  return( _( "Toggle label for current row" ) );
      case NODE_LABEL_CLEAR_ALL      :  return( _( "Clear all set labels" ) );
      case NODE_LABEL_GOTO_1         :  return( _( "Select row marked with label-1" ) );
      case NODE_LABEL_GOTO_2         :  return( _( "Select row marked with label-2" ) );
      case NODE_LABEL_GOTO_3         :  return( _( "Select row marked with label-3" ) );
      case NODE_LABEL_GOTO_4         :  return( _( "Select row marked with label-4" ) );
      case NODE_LABEL_GOTO_5         :  return( _( "Select row marked with label-5" ) );
      case NODE_LABEL_GOTO_6         :  return( _( "Select row marked with label-6" ) );
      case NODE_LABEL_GOTO_7         :  return( _( "Select row marked with label-7" ) );
      case NODE_LABEL_GOTO_8         :  return( _( "Select row marked with label-8" ) );
      case NODE_LABEL_GOTO_9         :  return( _( "Select row marked with label-9" ) );
      /*
      case NODE_SWAP_UP              :  return( _( "Swap current node with above node" ) );
      case NODE_SWAP_DOWN            :  return( _( "Swap current node with below node" ) );
      case NODE_SORT_ALPHABETICALLY  :  return( _( "Sort child nodes of current node alphabetically" ) );
      case NODE_SORT_RANDOMLY        :  return( _( "Sort child nodes of current node randomly" ) );
      */
      case EDIT_START                :  return( _( "Text Editing" ) );
      case EDIT_TEXT_START           :  return( _( "Insertion/Deletion Commands" ) );
      case EDIT_INSERT_NEWLINE       :  return( _( "Insert newline character" ) );
      case EDIT_SPLIT_LINE           :  return( _( "Split current line at current character" ) );
      case EDIT_INSERT_TAB           :  return( _( "Insert TAB character" ) );
      case EDIT_INSERT_EMOJI         :  return( _( "Insert emoji" ) );
      case EDIT_REMOVE_WORD_NEXT     :  return( _( "Remove next word" ) );
      case EDIT_REMOVE_WORD_PREV     :  return( _( "Remove previous word" ) );
      case EDIT_CLIPBOARD_START      :  return( _( "Clipboard Commands" ) );
      case EDIT_COPY                 :  return( _( "Copy selected nodes or text" ) );
      case EDIT_CUT                  :  return( _( "Cut selected nodes or text" ) );
      case EDIT_PASTE                :  return( _( "Paste nodes or text from clipboard" ) );
      case EDIT_URL_START            :  return( _( "URL Commands" ) );
      case EDIT_OPEN_URL             :  return( _( "Open URL link at current cursor position" ) );
      case EDIT_ADD_URL              :  return( _( "Add URL link at current cursor position" ) );
      case EDIT_EDIT_URL             :  return( _( "Change URL link at current cursor position" ) );
      case EDIT_REMOVE_URL           :  return( _( "Remove URL link at current cursor position" ) );
      case EDIT_CURSOR_START         :  return( _( "Cursor Commands" ) );
      case EDIT_CURSOR_CHAR_NEXT     :  return( _( "Move cursor to next character" ) );
      case EDIT_CURSOR_CHAR_PREV     :  return( _( "Move cursor to previous character" ) );
      case EDIT_CURSOR_UP            :  return( _( "Move cursor up one line" ) );
      case EDIT_CURSOR_DOWN          :  return( _( "Move cursor down one line" ) );
      case EDIT_CURSOR_WORD_NEXT     :  return( _( "Move cursor to beginning of next word" ) );
      case EDIT_CURSOR_WORD_PREV     :  return( _( "Move cursor to beginning of previous word" ) );
      case EDIT_CURSOR_FIRST         :  return( _( "Move cursor to start of text" ) );
      case EDIT_CURSOR_LAST          :  return( _( "Move cursor to end of text" ) );
      case EDIT_CURSOR_LINESTART     :  return( _( "Move cursor to start of current line" ) );
      case EDIT_CURSOR_LINEEND       :  return( _( "Move cursor to end of current line" ) );
      case EDIT_SELECT_START         :  return( _( "Selection Commands" ) );
      case EDIT_SELECT_CHAR_NEXT     :  return( _( "Add next character to current selection" ) );
      case EDIT_SELECT_CHAR_PREV     :  return( _( "Add previous character to current selection" ) );
      case EDIT_SELECT_UP            :  return( _( "Add line up to current selection" ) );
      case EDIT_SELECT_DOWN          :  return( _( "Add line down to current selection" ) );
      case EDIT_SELECT_WORD_NEXT     :  return( _( "Add next word to current selection" ) );
      case EDIT_SELECT_WORD_PREV     :  return( _( "Add previous word to current selection" ) );
      case EDIT_SELECT_START_UP      :  return( _( "Add start of text to current selection (Control-Up)" ) );
      case EDIT_SELECT_START_HOME    :  return( _( "Add start of text to current selection (Control-Home)" ) );
      case EDIT_SELECT_END_DOWN      :  return( _( "Add end of text to current selection (Control-Down)" ) );
      case EDIT_SELECT_END_END       :  return( _( "Add end of text to current selection (Control-End)" ) );
      case EDIT_SELECT_LINESTART     :  return( _( "Add start of current line to current selection" ) );
      case EDIT_SELECT_LINEEND       :  return( _( "Add end of current line to current selection" ) );
      case EDIT_SELECT_ALL           :  return( _( "Select all text" ) );
      case EDIT_SELECT_NONE          :  return( _( "Deselect all text" ) );
      default                        :  stdout.printf( "label: %d\n", this );  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns function to execute for this key command.
  public KeyCommandFunc get_func() {
    switch( this ) {
      case DO_NOTHING                :  return( do_nothing );
      case FILE_NEW                  :  return( file_new );
      case FILE_OPEN                 :  return( file_open );
      case FILE_SAVE                 :  return( file_save );
      case FILE_SAVE_AS              :  return( file_save_as );
      case FILE_PRINT                :  return( file_print );
      case TAB_GOTO_NEXT             :  return( tab_goto_next );
      case TAB_GOTO_PREV             :  return( tab_goto_prev );
      case TAB_CLOSE_CURRENT         :  return( tab_close_current );
      case UNDO_ACTION               :  return( undo_action );
      case REDO_ACTION               :  return( redo_action );
      case ZOOM_IN                   :  return( zoom_in );
      case ZOOM_OUT                  :  return( zoom_out );
      case ZOOM_ACTUAL               :  return( zoom_actual );
      case SHOW_PREFERENCES          :  return( show_preferences );
      case SHOW_SHORTCUTS            :  return( show_shortcuts );
      case SHOW_CONTEXTUAL_MENU      :  return( show_contextual_menu );
      case SEARCH                    :  return( search );
      case SHOW_ABOUT                :  return( show_about );
      case TOGGLE_FOCUS_MODE         :  return( toggle_focus_mode );
      case EDIT_NOTE                 :  return( edit_note );
      case EDIT_SELECTED             :  return( edit_selected );
      case QUIT                      :  return( quit_application );
      case CONTROL_PRESSED           :  return( control_pressed );
      case ESCAPE                    :  return( escape );
      /*
      case NODE_ADD_ROOT             :  return( node_add_root );
      case NODE_ADD_SIBLING_AFTER    :  return( node_return );
      case NODE_ADD_SIBLING_BEFORE   :  return( node_shift_return );
      case NODE_ADD_CHILD            :  return( node_tab );
      case NODE_ADD_PARENT           :  return( node_shift_tab );
      case NODE_REMOVE               :  return( node_remove );
      case NODE_REMOVE_ONLY          :  return( node_remove_only_selected );
      */
      case NODE_PASTE_REPLACE        :  return( node_paste_replace );
      // case NODE_CENTER               :  return( node_center );
      case NODE_EXPAND_ONE           :  return( node_expand_one );
      case NODE_EXPAND_ALL           :  return( node_expand_all );
      case NODE_COLLAPSE_ONE         :  return( node_collapse_one ); 
      case NODE_COLLAPSE_ALL         :  return( node_collapse_all ); 
      // case NODE_CHANGE_TASK          :  return( node_change_task );
      case NODE_SELECT_TOP           :  return( node_select_top );
      case NODE_SELECT_BOTTOM        :  return( node_select_bottom );
      case NODE_SELECT_PAGE_TOP      :  return( node_select_page_top );
      case NODE_SELECT_PAGE_BOTTOM   :  return( node_select_page_bottom );
      case NODE_SELECT_DOWN          :  return( node_select_down );
      case NODE_SELECT_UP            :  return( node_select_up );
      case NODE_SELECT_PARENT        :  return( node_select_parent );
      case NODE_SELECT_LAST_CHILD    :  return( node_select_last_child );
      case NODE_SELECT_NEXT_SIBLING  :  return( node_select_next_sibling );
      case NODE_SELECT_PREV_SIBLING  :  return( node_select_prev_sibling );
      case NODE_INDENT               :  return( node_indent );
      case NODE_UNINDENT             :  return( node_unindent );
      case NODE_MOVE_DOWN            :  return( node_move_down );
      case NODE_MOVE_UP              :  return( node_move_up );
      case NODE_MOVE_TO_LABEL_1      :  return( node_move_to_label_1 );
      case NODE_MOVE_TO_LABEL_2      :  return( node_move_to_label_2 );
      case NODE_MOVE_TO_LABEL_3      :  return( node_move_to_label_3 );
      case NODE_MOVE_TO_LABEL_4      :  return( node_move_to_label_4 );
      case NODE_MOVE_TO_LABEL_5      :  return( node_move_to_label_5 );
      case NODE_MOVE_TO_LABEL_6      :  return( node_move_to_label_6 );
      case NODE_MOVE_TO_LABEL_7      :  return( node_move_to_label_7 );
      case NODE_MOVE_TO_LABEL_8      :  return( node_move_to_label_8 );
      case NODE_MOVE_TO_LABEL_9      :  return( node_move_to_label_9 );
      case NODE_LABEL_TOGGLE         :  return( node_label_toggle );
      case NODE_LABEL_CLEAR_ALL      :  return( node_label_clear_all );
      case NODE_LABEL_GOTO_1         :  return( node_label_goto_1 );
      case NODE_LABEL_GOTO_2         :  return( node_label_goto_2 );
      case NODE_LABEL_GOTO_3         :  return( node_label_goto_3 );
      case NODE_LABEL_GOTO_4         :  return( node_label_goto_4 );
      case NODE_LABEL_GOTO_5         :  return( node_label_goto_5 );
      case NODE_LABEL_GOTO_6         :  return( node_label_goto_6 );
      case NODE_LABEL_GOTO_7         :  return( node_label_goto_7 );
      case NODE_LABEL_GOTO_8         :  return( node_label_goto_8 );
      case NODE_LABEL_GOTO_9         :  return( node_label_goto_9 );
      /*
      case NODE_SWAP_UP              :  return( node_swap_up );
      case NODE_SWAP_DOWN            :  return( node_swap_down );
      case NODE_SORT_ALPHABETICALLY  :  return( node_sort_alphabetically );
      case NODE_SORT_RANDOMLY        :  return( node_sort_randomly );
      */
      case EDIT_INSERT_NEWLINE       :  return( edit_insert_newline );
      case EDIT_SPLIT_LINE           :  return( edit_split_line );
      case EDIT_INSERT_TAB           :  return( edit_insert_tab );
      case EDIT_INSERT_EMOJI         :  return( edit_insert_emoji );
      case EDIT_ESCAPE               :  return( edit_escape );
      case EDIT_BACKSPACE            :  return( edit_backspace );
      case EDIT_DELETE               :  return( edit_delete );
      case EDIT_REMOVE_WORD_NEXT     :  return( edit_remove_word_next );
      case EDIT_REMOVE_WORD_PREV     :  return( edit_remove_word_previous );
      case EDIT_COPY                 :  return( edit_copy );
      case EDIT_CUT                  :  return( edit_cut );
      case EDIT_PASTE                :  return( edit_paste );
      case EDIT_OPEN_URL             :  return( edit_open_url );
      case EDIT_ADD_URL              :  return( edit_add_url );
      case EDIT_EDIT_URL             :  return( edit_edit_url );
      case EDIT_REMOVE_URL           :  return( edit_remove_url );
      case EDIT_CURSOR_CHAR_NEXT     :  return( edit_cursor_char_next );
      case EDIT_CURSOR_CHAR_PREV     :  return( edit_cursor_char_previous );
      case EDIT_CURSOR_UP            :  return( edit_cursor_up );
      case EDIT_CURSOR_DOWN          :  return( edit_cursor_down );
      case EDIT_CURSOR_WORD_NEXT     :  return( edit_cursor_word_next );
      case EDIT_CURSOR_WORD_PREV     :  return( edit_cursor_word_previous );
      case EDIT_CURSOR_FIRST         :  return( edit_cursor_to_start );
      case EDIT_CURSOR_LAST          :  return( edit_cursor_to_end );
      case EDIT_CURSOR_LINESTART     :  return( edit_cursor_to_linestart );
      case EDIT_CURSOR_LINEEND       :  return( edit_cursor_to_lineend );
      case EDIT_SELECT_CHAR_NEXT     :  return( edit_select_char_next );
      case EDIT_SELECT_CHAR_PREV     :  return( edit_select_char_previous );
      case EDIT_SELECT_UP            :  return( edit_select_up );
      case EDIT_SELECT_DOWN          :  return( edit_select_down );
      case EDIT_SELECT_WORD_NEXT     :  return( edit_select_word_next );
      case EDIT_SELECT_WORD_PREV     :  return( edit_select_word_previous );
      case EDIT_SELECT_START_UP      :  return( edit_select_start_up );
      case EDIT_SELECT_START_HOME    :  return( edit_select_start_home );
      case EDIT_SELECT_END_DOWN      :  return( edit_select_end_down );
      case EDIT_SELECT_END_END       :  return( edit_select_end_end );
      case EDIT_SELECT_LINESTART     :  return( edit_select_linestart );
      case EDIT_SELECT_LINEEND       :  return( edit_select_lineend );
      case EDIT_SELECT_ALL           :  return( edit_select_all );
      case EDIT_SELECT_NONE          :  return( edit_deselect_all );
      case EDIT_RETURN               :  return( edit_return );
      case EDIT_SHIFT_RETURN         :  return( edit_shift_return );
      case EDIT_TAB                  :  return( edit_tab );
      case EDIT_SHIFT_TAB            :  return( edit_shift_tab );
      default                        :  stdout.printf( "Missed %d\n", this );  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a node.
  public bool for_node() {
    return(
      ((NODE_START < this) && (this < NODE_END)) ||
      (this == EDIT_NOTE) ||
      (this == EDIT_COPY) ||
      (this == EDIT_CUT)  ||
      (this == EDIT_PASTE) ||
      (this == ESCAPE)
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid when nothing is selected
  // in the map.
  public bool for_none() {
    switch( this ) {
      // case NODE_ADD_SIBLING_AFTER  :
      // case NODE_ADD_SIBLING_BEFORE :
      case EDIT_PASTE              :
        return( true );
      default :
        return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for editing.
  public bool for_editing() {
    return( (EDIT_START < this) && (this < EDIT_END) );
  }

  //-------------------------------------------------------------
  // Returns a string ID for the map state this this command
  // targets.
  private string target_id() {
    if( for_node() ) {
      return( "0" );
    } else if( for_editing() ) {
      return( "1" );
    } else if( for_none() ) {
      return( "2" );
    } else {
      return( "012" );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the this command and the other command
  // are targetting the same map state.
  public bool target_matches( KeyCommand command ) {
    var mine   = target_id();
    var theirs = command.target_id();
    return( mine.contains( theirs ) || theirs.contains( mine ) );
  }

  //-------------------------------------------------------------
  // Returns true if this key command is able to have a shortcut
  // associated with it.  These should have built-in shortcuts
  // associated with each of them.
  public bool viewable() {
    return(
      (this != DO_NOTHING) &&
      (this != CONTROL_PRESSED) &&
      (this != ESCAPE) &&
      (this != EDIT_ESCAPE) &&
      (this != EDIT_BACKSPACE) &&
      // (this != NODE_REMOVE) &&
      // (this != NODE_REMOVE_ONLY) &&
      (this != EDIT_DELETE) &&
      // (this != NODE_ADD_SIBLING_AFTER) &&
      // (this != NODE_ADD_SIBLING_BEFORE) &&
      // (this != NODE_ADD_CHILD) &&
      // (this != NODE_ADD_PARENT) &&
      (this != EDIT_CURSOR_CHAR_NEXT) &&
      (this != EDIT_CURSOR_CHAR_PREV) &&
      (this != EDIT_CURSOR_UP) &&
      (this != EDIT_CURSOR_DOWN) &&
      (this != EDIT_SELECT_CHAR_NEXT) &&
      (this != EDIT_SELECT_CHAR_PREV) &&
      (this != NODE_SELECT_UP) &&
      (this != NODE_SELECT_DOWN) &&
      // (this != NODE_SWAP_UP) &&
      // (this != NODE_SWAP_DOWN) &&
      ((this < EDIT_MISC_START) || (EDIT_MISC_END < this))
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command can have its shortcut be edited.
  public bool editable() {
    if( viewable() ) {
      switch( this ) {
        case ESCAPE            :
        // case NODE_REMOVE       :
        // case NODE_REMOVE_ONLY  :
        case EDIT_BACKSPACE    :
        case EDIT_DELETE       :
        case EDIT_ESCAPE       :
        case EDIT_RETURN       :
        case EDIT_SHIFT_RETURN :
        case EDIT_TAB          :
        case EDIT_SHIFT_TAB    :
        // case NODE_ADD_SIBLING_AFTER  :
        // case NODE_ADD_SIBLING_BEFORE :
        // case NODE_ADD_CHILD    :
        // case NODE_ADD_PARENT   :
          return( false );
        default :
          return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if this key command is a start of command block.
  public bool is_section_start() {
    switch( this ) {
      case GENERAL_START :
      case NODE_START    :
      case EDIT_START    :  return( true );
      default            :  return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this key command is an end of command block.
  public bool is_section_end() {
    switch( this ) {
      case GENERAL_END :
      case NODE_END    :
      case EDIT_END    :  return( true );
      default          :  return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given key command is a section group
  // start indicator.
  public bool is_group_start() {
    switch( this ) {
      case FILE_START           :
      case TAB_START            :
      case UNDO_START           :
      case ZOOM_START           :
      case MISCELLANEOUS_START  :
      case NODE_EXIST_START     :
      case NODE_CLIPBOARD_START :
      case NODE_VIEW_START      :
      case NODE_CHANGE_START    :
      case NODE_SELECT_START    :
      case NODE_MOVE_START      :
      case NODE_LABEL_START     :
      case EDIT_TEXT_START      :
      case EDIT_CLIPBOARD_START :
      case EDIT_URL_START       :
      case EDIT_CURSOR_START    :
      case EDIT_SELECT_START    :
      case EDIT_MISC_START      :
        return( true );
      default :
        return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given key command is a section group
  // end indicator.
  public bool is_group_end() {
    switch( this ) {
      case FILE_END           :
      case TAB_END            :
      case UNDO_END           :
      case ZOOM_END           :
      case MISCELLANEOUS_END  :
      case NODE_EXIST_END     :
      case NODE_CLIPBOARD_END :
      case NODE_VIEW_END      :
      case NODE_CHANGE_END    :
      case NODE_SELECT_END    :
      case NODE_MOVE_END      :
      case NODE_LABEL_END     :
      case EDIT_TEXT_END      :
      case EDIT_CLIPBOARD_END :
      case EDIT_URL_END       :
      case EDIT_CURSOR_END    :
      case EDIT_SELECT_END    :
      case EDIT_MISC_END      :
        return( true );
      default :
        return( false );
    }
  }

  //-------------------------------------------------------------
  // COMMANDS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // ADMINISTRATIVE FUNCTIONS

  public static void do_nothing( OutlineTable ot ) {}

  public static void control_pressed( OutlineTable ot ) {
    // TODO - map.set_control( true );
  }

  //-------------------------------------------------------------
  // GENERAL FUNCTIONS

  public static void file_new( OutlineTable ot ) {
    ot.win.do_new_file();
  }

  public static void file_open( OutlineTable ot ) {
    ot.win.do_open_file();
  }

  public static void file_save( OutlineTable ot ) {
    if( ot.document.is_saved() ) {
      ot.document.save();
    } else {
      ot.win.save_file( ot, false );
    }
  }

  public static void file_save_as( OutlineTable ot ) {
    ot.win.do_save_as_file();
  }

  public static void file_print( OutlineTable ot ) {
    var print = new ExportPrint();
    print.print( ot, ot.win );
  }

  public static void tab_goto_next( OutlineTable ot ) {
    ot.win.next_tab();
  }

  public static void tab_goto_prev( OutlineTable ot ) {
    ot.win.previous_tab();
  }

  public static void tab_close_current( OutlineTable ot ) {
    ot.win.close_current_tab();
  }

  public static void undo_action( OutlineTable ot ) {
    if( ot.is_node_editable() || ot.is_note_editable() ) {
      ot.undo_text.undo();
    } else {
      ot.undo_buffer.undo();
    }
    ot.grab_focus();
  }

  public static void redo_action( OutlineTable ot ) {
    if( ot.is_node_editable() || ot.is_note_editable() ) {
      ot.undo_text.redo();
    } else {
      ot.undo_buffer.redo();
    }
    ot.grab_focus();
  }

  public static void zoom_in( OutlineTable ot ) {
    ot.win.do_zoom_in();
  }

  public static void zoom_out( OutlineTable ot ) {
    ot.win.do_zoom_out();
  }

  public static void zoom_actual( OutlineTable ot ) {
    ot.win.do_zoom_actual();
  }

  public static void show_preferences( OutlineTable ot ) {
    var prefs = new Preferences( ot.win );
    prefs.present();
  }

  public static void show_shortcuts( OutlineTable ot ) {

    var builder = new Builder.from_resource( "/com/github/phase1geo/outliner/shortcuts/shortcuts.ui" );
    var win     = builder.get_object( "shortcuts" ) as Gtk.ShortcutsWindow;

    win.transient_for = ot.win;
    win.view_name     = null;

    /* Display the most relevant information based on the current state */
    if( ot.selected != null ) {
      if( (ot.selected.mode == NodeMode.EDITABLE) ||
          (ot.selected.mode == NodeMode.NOTEEDIT) ) {
        win.section_name = "text-editing";
      } else {
        win.section_name = "node";
      }
    } else {
      win.section_name = "general";
    }

    win.present();

  }

  public static void show_contextual_menu( OutlineTable ot ) {
    ot.show_contextual_menu();
  }

  public static void search( OutlineTable ot ) {
    ot.win.do_search();
  }

  public static void show_about( OutlineTable ot ) {
    var about = new About( ot.win );
    about.show();
  }

  public static void toggle_focus_mode( OutlineTable ot ) {
    ot.win.toggle_focus_mode();
  }

  public static void edit_note( OutlineTable ot ) {
    if( ot.selected != null ) {
      ot.set_node_mode( ot.selected, NodeMode.NOTEEDIT );
      ot.selected.note.move_cursor_to_end();
      ot.selected.hide_note = false;
      ot.queue_draw();
    }
  }

  public static void edit_selected( OutlineTable ot ) {
    if( ot.selected != null ) {
      ot.set_node_mode( ot.selected, NodeMode.EDITABLE );
      ot.selected.name.move_cursor_to_end();
      ot.queue_draw();
    }
  }

  /*
  public static void show_selected( OutlineTable ot ) {
    ot.see();
  }
  */

  public static void quit_application( OutlineTable ot ) {
    ot.win.destroy();
  }

  public static void escape( OutlineTable ot ) {
    /*
    if( map.is_connection_connecting() ) {
      var current = map.get_current_connection();
      map.connections.remove_connection( current, true );
      map.selected.remove_connection( current );
      map.model.set_attach_node( null );
      map.selected.set_current_node( map.model.last_node );
      map.canvas.last_connection = null;
      map.queue_draw();
    } else {
      map.hide_properties();
    }
    */
  }

  //-------------------------------------------------------------
  // NODE FUNCTIONS
  //-------------------------------------------------------------

  public static void node_select_top( OutlineTable ot ) {
    ot.change_selected( ot.node_top() );
  }

  public static void node_select_bottom( OutlineTable ot ) {
    ot.change_selected( ot.node_bottom() );
  }

  public static void node_select_page_top( OutlineTable ot ) {
    ot.change_selected( ot.node_page_top() );
  }

  public static void node_select_page_bottom( OutlineTable ot ) {
    ot.change_selected( ot.node_page_bottom() );
  }

  public static void node_select_up( OutlineTable ot ) {
    ot.change_selected( ot.node_previous( ot.selected ) );
  }

  public static void node_select_down( OutlineTable ot ) {
    ot.change_selected( ot.node_next( ot.selected ) );
  }

  public static void node_select_parent( OutlineTable ot ) {
    ot.change_selected( ot.node_parent( ot.selected ) );
  }

  public static void node_select_last_child( OutlineTable ot ) {
    ot.change_selected( ot.node_last_child( ot.selected ) );
  }

  public static void node_select_next_sibling( OutlineTable ot ) {
    ot.change_selected( ot.node_next_sibling( ot.selected ) );
  }

  public static void node_select_prev_sibling( OutlineTable ot ) {
    ot.change_selected( ot.node_previous_sibling( ot.selected ) );
  }

  public static void node_indent( OutlineTable ot ) {
    ot.indent();
  }

  public static void node_unindent( OutlineTable ot ) {
    ot.unindent();
  }

  public static void node_move_down( OutlineTable ot ) {
    ot.move_node_down( ot.selected );
  }

  public static void node_move_up( OutlineTable ot ) {
    ot.move_node_up( ot.selected );
  }

  public static void node_move_to_label_1( OutlineTable ot ) {
    ot.move_node_to_label( 0 );
  }

  public static void node_move_to_label_2( OutlineTable ot ) {
    ot.move_node_to_label( 1 );
  }

  public static void node_move_to_label_3( OutlineTable ot ) {
    ot.move_node_to_label( 2 );
  }

  public static void node_move_to_label_4( OutlineTable ot ) {
    ot.move_node_to_label( 3 );
  }

  public static void node_move_to_label_5( OutlineTable ot ) {
    ot.move_node_to_label( 4 );
  }

  public static void node_move_to_label_6( OutlineTable ot ) {
    ot.move_node_to_label( 5 );
  }

  public static void node_move_to_label_7( OutlineTable ot ) {
    ot.move_node_to_label( 6 );
  }

  public static void node_move_to_label_8( OutlineTable ot ) {
    ot.move_node_to_label( 7 );
  }

  public static void node_move_to_label_9( OutlineTable ot ) {
    ot.move_node_to_label( 8 );
  }

  public static void node_label_toggle( OutlineTable ot ) {
    ot.toggle_label();
  }

  public static void node_label_clear_all( OutlineTable ot ) {
    ot.clear_all_labels();
  }

  public static void node_label_goto_1( OutlineTable ot ) {
    ot.goto_label( 0 );
  }

  public static void node_label_goto_2( OutlineTable ot ) {
    ot.goto_label( 1 );
  }

  public static void node_label_goto_3( OutlineTable ot ) {
    ot.goto_label( 2 );
  }

  public static void node_label_goto_4( OutlineTable ot ) {
    ot.goto_label( 3 );
  }

  public static void node_label_goto_5( OutlineTable ot ) {
    ot.goto_label( 4 );
  }

  public static void node_label_goto_6( OutlineTable ot ) {
    ot.goto_label( 5 );
  }

  public static void node_label_goto_7( OutlineTable ot ) {
    ot.goto_label( 6 );
  }

  public static void node_label_goto_8( OutlineTable ot ) {
    ot.goto_label( 7 );
  }

  public static void node_label_goto_9( OutlineTable ot ) {
    ot.goto_label( 8 );
  }

  /*
  public static void node_change_task( OutlineTable ot ) {
    var current = map.get_current_node();
    if( current != null ) {
      if( current.task_enabled() ) {
        if( current.task_done() ) {
          map.model.change_current_task( false, false );
        } else {
          map.model.change_current_task( true, true );
        }
      } else {
        map.model.change_current_task( true, false );
      }
    }
  }

  public static void node_add_root( OutlineTable ot ) {
    map.model.add_root_node();
  }

  //-------------------------------------------------------------
  // Helper function that handles a press of the return key when
  // a node is selected (or is attached to a connecting connection).
  private static void node_return_helper( OutlineTable ot, bool shift ) {
    if( map.is_connection_connecting() && (map.model.attach_node != null) ) {
      map.model.end_connection( map.model.attach_node );
    } else if( map.is_node_selected() ) {
      if( !map.get_current_node().is_root() ) {
        map.model.add_sibling_node( shift );
      } else if( shift ) {
        map.model.add_connected_node();
      } else {
        map.model.add_root_node();
      }
    } else if( map.selected.num_nodes() == 0 ) {
      map.model.add_root_node();
    }
  }

  public static void node_return( OutlineTable ot ) {
    node_return_helper( map, false );
  }

  public static void node_shift_return( OutlineTable ot ) {
    node_return_helper( map, true );
  }

  private static void node_tab_helper( OutlineTable ot, bool shift ) {
    if( map.is_node_selected() ) {
      if( shift ) {
        map.model.add_parent_node();
      } else {
        map.model.add_child_node();
      }
    } else if( map.selected.num_nodes() > 1 ) {
      // map.model.add_summary_node_from_selected();
    }
  }

  public static void node_tab( OutlineTable ot ) {
    node_tab_helper( map, false );
  }

  public static void node_shift_tab( OutlineTable ot ) {
    node_tab_helper( map, true );
  }

  public static void node_center( OutlineTable ot ) {
    map.canvas.center_current_node();
  }
  */

  public static void node_expand_one( OutlineTable ot ) {
    ot.node_expand( false );
  }

  public static void node_expand_all( OutlineTable ot ) {
    ot.node_expand( true );
  }

  public static void node_collapse_one( OutlineTable ot ) {
    ot.node_collapse( false );
  }

  public static void node_collapse_all( OutlineTable ot ) {
    ot.node_collapse( true );
  }

  /*
  public static void node_sort_alphabetically( OutlineTable ot ) {
    map.model.sort_alphabetically();
  }

  public static void node_sort_randomly( OutlineTable ot ) {
    map.model.sort_randomly();
  }

  public static void node_quick_entry_insert( OutlineTable ot ) {
    var quick_entry = new QuickEntry( map, false, map.settings );
    quick_entry.preload( "- " );
  }

  public static void node_quick_entry_replace( OutlineTable ot ) {
    var quick_entry = new QuickEntry( map, true, map.settings );
    var export      = (ExportText)map.win.exports.get_by_name( "text" );
    quick_entry.preload( export.export_node( map, map.get_current_node(), "" ) );
  }

  public static void node_paste_node_link( OutlineTable ot ) {
    map.do_paste_node_link();
  }
  */

  public static void node_paste_replace( OutlineTable ot ) {
    ot.do_paste( true );
  }

  /*
  public static void node_remove( OutlineTable ot ) {
    if( map.selected.num_nodes() > 1 ) {
      map.model.delete_nodes();
    } else {
      Node? next;
      var   current = map.get_current_node();
      if( ((next = map.sibling_node( 1 )) == null) && ((next = map.sibling_node( -1 )) == null) && current.is_root() ) {
        map.model.delete_node();
      } else {
        if( next == null ) {
          next = current.parent;
        }
        map.model.delete_node();
        if( map.select_node( next ) ) {
          map.queue_draw();
        }
      }
    }
  }

  public static void node_remove_only_selected( OutlineTable ot ) {
    map.model.delete_nodes();
  }

  public static void node_detach( OutlineTable ot ) {
    map.model.detach();
  }

  //-------------------------------------------------------------
  // Swaps the current node with the one in the specified direction.
  private static void node_swap( OutlineTable ot, string dir ) {
    var current = map.get_current_node();
    if( current != null ) {
      Node? other = null;
      switch( dir ) {
        case "left"  :  other = map.model.get_node_left( current );   break;
        case "right" :  other = map.model.get_node_right( current );  break;
        case "up"    :  other = map.model.get_node_up( current );     break;
        case "down"  :  other = map.model.get_node_down( current );   break;
        default      :  return;
      }
      if( other != null ) {
        map.swap_nodes( current, other );
      }
    }
  }

  public static void node_swap_left( OutlineTable ot ) {
    node_swap( map, "left" );
  }

  public static void node_swap_right( OutlineTable ot ) {
    node_swap( map, "right" );
  }

  public static void node_swap_up( OutlineTable ot ) {
    node_swap( map, "up" );
  }

  public static void node_swap_down( OutlineTable ot ) {
    node_swap( map, "down" );
  }
  */

  //-------------------------------------------------------------
  // EDITING FUNCTIONS

  //-------------------------------------------------------------
  // Helper function that should be called whenever text changes
  // while editing.
  private static void text_changed( OutlineTable ot ) {
    ot.changed();
    ot.queue_draw();
  }

  //-------------------------------------------------------------
  // Helper function that will insert a given string into the
  // current text context.
  private static void insert_text( OutlineTable ot, string str ) {
    var text = ot.get_current_text();
    if( text != null ) {
      text.insert( str, ot.undo_text );
      text_changed( ot );
    }
  }

  //-------------------------------------------------------------
  // Helper function that moves the cursor in a given direction.
  private static void edit_cursor( OutlineTable ot, string dir ) {
    var text = ot.get_current_text();
    if( text != null ) {
      switch( dir ) {
        case "char-next" :  text.move_cursor( 1 );              break;
        case "char-prev" :  text.move_cursor( -1 );             break;
        case "up"        :  text.move_cursor_vertically( -1 );  break;
        case "down"      :  text.move_cursor_vertically( 1 );   break;
        case "word-next" :  text.move_cursor_by_word( 1 );      break;
        case "word-prev" :  text.move_cursor_by_word( -1 );     break;
        case "start"     :  text.move_cursor_to_start();        break;
        case "end"       :  text.move_cursor_to_end();          break;
        case "linestart" :  text.move_cursor_to_linestart();    break;
        case "lineend"   :  text.move_cursor_to_lineend();      break;
        default          :  return;
      }
      ot.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Helper function that changes the selection in a given direction.
  private static void edit_selection( OutlineTable ot, string dir ) {
    var text = ot.get_current_text();
    if( text != null ) {
      switch( dir ) {
        case "char-next"  :  text.selection_by_char( 1 );          break;
        case "char-prev"  :  text.selection_by_char( -1 );         break;
        case "up"         :  text.selection_vertically( -1 );      break;
        case "down"       :  text.selection_vertically( 1 );       break;
        case "word-next"  :  text.selection_by_word( 1 );          break;
        case "word-prev"  :  text.selection_by_word( -1 );         break;
        case "start-up"   :  text.selection_to_start( false );     break;
        case "start-home" :  text.selection_to_start( true );      break;
        case "end-down"   :  text.selection_to_end( false );       break;
        case "end-end"    :  text.selection_to_end( true );        break;
        case "linestart"  :  text.selection_to_linestart( true );  break;
        case "lineend"    :  text.selection_to_lineend( true );    break;
        case "all"        :  text.set_cursor_all( false );         break;
        case "none"       :  text.clear_selection();               break;
        default           :  return;
      }
      ot.queue_draw();
    }
  }

  public static void edit_escape( OutlineTable ot ) {
    var text = ot.get_current_text();
    if( text != null ) {
      if( ot.completion.shown ) {
        ot.completion.hide();
      } else {
        ot.set_node_mode( ot.selected, NodeMode.SELECTED );
        ot.queue_draw();
      }
    }
  }

  public static void edit_insert_newline( OutlineTable ot ) {
    insert_text( ot, "\n" );
  }

  public static void edit_split_line( OutlineTable ot ) {
    ot.split_text();
  }

  public static void edit_insert_tab( OutlineTable ot ) {
    insert_text( ot, "\t" );
  }

  public static void edit_insert_emoji( OutlineTable ot ) {
    var text = ot.get_current_text();
    if( text != null ) {
      ot.insert_emoji( text );
    }
  }

  public static void edit_backspace( OutlineTable ot ) {
    var text = ot.get_current_text();
    if( text != null ) {
      text.backspace( ot.undo_text );
      text_changed( ot );
    }
  }

  public static void edit_delete( OutlineTable ot ) {
    var text = ot.get_current_text();
    if( text != null ) {
      text.delete( ot.undo_text );
      text_changed( ot );
    }
  }

  public static void edit_remove_word_previous( OutlineTable ot ) {
    var text = ot.get_current_text();
    if( text != null ) {
      text.backspace_word( ot.undo_text );
      text_changed( ot );
    }
  }

  public static void edit_remove_word_next( OutlineTable ot ) {
    var text = ot.get_current_text();
    if( text != null ) {
      text.delete_word( ot.undo_text );
      text_changed( ot );
    }
  }

  public static void edit_cursor_char_next( OutlineTable ot ) {
    edit_cursor( ot, "char-next" );
  }

  public static void edit_cursor_char_previous( OutlineTable ot ) {
    edit_cursor( ot, "char-prev" );
  }

  public static void edit_cursor_up( OutlineTable ot ) {
    edit_cursor( ot, "up" );
  }

  public static void edit_cursor_down( OutlineTable ot ) {
    edit_cursor( ot, "down" );
  }

  public static void edit_cursor_word_next( OutlineTable ot ) {
    edit_cursor( ot, "word-next" );
  }

  public static void edit_cursor_word_previous( OutlineTable ot ) {
    edit_cursor( ot, "word-prev" );
  }

  public static void edit_cursor_to_start( OutlineTable ot ) {
    edit_cursor( ot, "start" );
  }

  public static void edit_cursor_to_end( OutlineTable ot ) {
    edit_cursor( ot, "end" );
  }

  public static void edit_cursor_to_linestart( OutlineTable ot ) {
    edit_cursor( ot, "linestart" );
  }

  public static void edit_cursor_to_lineend( OutlineTable ot ) {
    edit_cursor( ot, "lineend" );
  }

  public static void edit_select_char_next( OutlineTable ot ) {
    edit_selection( ot, "char-next" );
  }

  public static void edit_select_char_previous( OutlineTable ot ) {
    edit_selection( ot, "char-prev" );
  }

  public static void edit_select_up( OutlineTable ot ) {
    edit_selection( ot, "up" );
  }

  public static void edit_select_down( OutlineTable ot ) {
    edit_selection( ot, "down" );
  }

  public static void edit_select_word_next( OutlineTable ot ) {
    edit_selection( ot, "word-next" );
  }

  public static void edit_select_word_previous( OutlineTable ot ) {
    edit_selection( ot, "word-prev" );
  }

  public static void edit_select_start_up( OutlineTable ot ) {
    edit_selection( ot, "start-up" );
  }

  public static void edit_select_start_home( OutlineTable ot ) {
    edit_selection( ot, "start-home" );
  }

  public static void edit_select_end_down( OutlineTable ot ) {
    edit_selection( ot, "end-down" );
  }

  public static void edit_select_end_end( OutlineTable ot ) {
    edit_selection( ot, "end-end" );
  }

  public static void edit_select_linestart( OutlineTable ot ) {
    edit_selection( ot, "linestart" );
  }

  public static void edit_select_lineend( OutlineTable ot ) {
    edit_selection( ot, "lineend" );
  }

  public static void edit_select_all( OutlineTable ot ) {
    edit_selection( ot, "all" );
  }

  public static void edit_deselect_all( OutlineTable ot ) {
    edit_selection( ot, "none" );
  }

  public static void edit_open_url( OutlineTable ot ) {
    /*
    var text = map.get_current_text();
    if( text != null ) {
      int cursor, selstart, selend;
      text.get_cursor_info( out cursor, out selstart, out selend );
      var links = text.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      Utils.open_url( links.index( 0 ).extra );
    }
    */
  }

  public static void edit_add_url( OutlineTable ot ) {
    // map.canvas.url_editor.add_url();
  }

  public static void edit_edit_url( OutlineTable ot ) {
    // map.canvas.url_editor.edit_url();
  }

  public static void edit_remove_url( OutlineTable ot ) {
    // map.canvas.url_editor.remove_url();
  }

  public static void edit_copy( OutlineTable ot ) {
    ot.do_copy();
  }

  public static void edit_cut( OutlineTable ot ) {
    ot.do_cut();
  }

  public static void edit_paste( OutlineTable ot ) {
    ot.do_paste( false );
  }

  private static void edit_return_helper( OutlineTable ot, bool shift ) {
    if( ot.is_note_editable() ) {
      ot.selected.note.insert( "\n", ot.undo_text );
      ot.see( ot.selected );
      ot.queue_draw();
    } else if( ot.is_node_editable() && (shift || ot.completion.shown) ) {
      if( shift ) {
        ot.selected.name.insert( "\n", ot.undo_text );
        ot.see( ot.selected );
      } else {
        ot.completion.select();
      }
      ot.queue_draw();
    } else if( ot.is_title_editable() ) {
      ot.set_title_editable( false );
      ot.selected = ot.root.get_last_node();
      ot.set_node_mode( ot.selected, NodeMode.EDITABLE );
      ot.queue_draw();
    } else if( ot.selected != null ) {
      if( (ot.selected.children.length > 0) && ot.selected.expanded ) {
        ot.add_child_node( 0 );
      } else {
        ot.add_sibling_node( !shift );
      }
    }
  }

  public static void edit_return( OutlineTable ot ) {
    edit_return_helper( ot, false );
  }

  public static void edit_shift_return( OutlineTable ot ) {
    edit_return_helper( ot, true );
  }

  private static void edit_tab_helper( OutlineTable ot, bool shift ) {
    if( ot.completion.shown ) {
      ot.completion.select();
      ot.queue_draw();
    } else if( ot.is_note_editable() && shift ) {
      ot.selected.note.insert( "\t", ot.undo_text );
      ot.see( ot.selected );
      ot.queue_draw();
    } else if( ot.is_title_editable() ) {
      if( shift ) {
        ot.title.insert( "\t", ot.undo_text );
      } else {
        ot.set_title_editable( false );
        ot.selected = ot.root.get_last_node();
        ot.set_node_mode( ot.selected, NodeMode.EDITABLE );
      }
      ot.queue_draw();
    } else if( ot.selected != null ) {
      if( shift ) {
        ot.unindent();
      } else {
        ot.indent();
      }
    }
  }

  public static void edit_tab( OutlineTable ot ) {
    edit_tab_helper( ot, false );
  }

  public static void edit_shift_tab( OutlineTable ot ) {
    edit_tab_helper( ot, true );
  }

}
