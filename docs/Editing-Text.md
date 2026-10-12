---
layout: default
title: Editing Text
parent: User Guide
nav_order: 6
---

## Editing text

You can edit the text of any displayed row/note simply by clicking the mouse anywhere within the text to set the insertion cursor at that location.  Text and be inserted, deleted and selected using any of the standard keys/shortcuts.

To finish editing text, simply hit the **Escape** key on the keyboard.

## Formatting text

Once text has been selected, a small toolbar will be displayed above the text with a row of buttons for copy, cut and paste as well as various formatting controls that can be applied to the selected text.  If the selected text has any type of formatting already applied, the state of the toolbar will be set to show which formatting options are applied on the text.

To add formatting to the selected text, click on the formatting button.  It will toggle on to indicate that the formatting has been applied.  To remove that formatting from the selected text, click the toggle button again.

### Formatting options

The following formatting options are available:

| Option | Notes |
| --- | --- |
| Bold | Click the button to toggle bold on/off. |
| Italics | Click the button to toggle italicizing on/off. |
| Underline | Click the button to toggle underlining on/off. |
| Strikethrough | Click the button to toggle strikethrough on/off. |
| Code | Click the button to toggle code (monospace) text type on/off. |
| Header | Click the button to select one of the six available header types or clear the header formatting. |
| Link | Click the toggle button to make the selected text a clickable link.  If the selected text contains a valid http, https, or mailto URL, the URL will be automatically entered into the URL field of the popup window; otherwise, the popup window will be displayed, allowing the user to add the URL.  Once a valid URL has been entered, the Apply button will be enabled.  To remove a URL, click the toggle button, remove the URL location and click on the Apply button. |
| Superscript | Click the button to toggle superscript text type on/off. |
| Subscript | Click the button to toggle subscript text type on/off. |
| Highlighting | Click the color button to highlight the background of the selected text to the shown color.  To change the color, simply click on the dropdown button to display the color picker. |
| Font Color | Click the color button to set the forground color of the selected text to the shown color.  To change the color, simply click on the dropdown button to display the color picker. |
| Clear All Formatting | Click the button to clear all formatting of selected text. |

## Markdown

In addition to rich text formatting as specified above, you can also choose to use Markdown syntax formatting options when editing text.  Any text surrounded by the appropriate Markdown syntax will be immediately formatted.  The choice to enable Markdown formatting is available in the **Properties** panel available in the header bar of the application.

The following Markdown syntax is supported (note that not all rich text formatting is available with Markdown):

| Syntax | Description |
| --- | --- |
| **\#** _text_ | Identifies the entire line as a header (you may enter 1 to 6 hash symbols to control header size). |
| **\*\*** _text_ **\*\***<br>**\_\_** _text_ **\_\_** | Emboldens surrounded text. |
| **\*** _text_ **\***<br>**\_** _text_ **\_** | Italicizes surrounded text. |
| **\`** _text_ **\`** | Displays surrounded text in monospace. |
| **-** _text_ <br>**+** _text_<br>**\*** _text_ | Identifies line of text as an unordered list item. |
| _number_ **.** | Identifies line of text as an ordered list item. |
| **\[** _text_ **\](** _url_ **)** | Higlights the text as a clickable link that will load in a web browser when clicked. |
| **\<mailto:** _email-address_ **>** | Highlights the text as a clickable link that will create an email when clicked. |
| **<** _url_ **>** | Highlights the text as a clickable link that will load in a web browser when clicked. |
