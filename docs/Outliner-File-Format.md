---
layout: default
title: Outliner File Format
parent: User Guide
nav_order: 15
---

# Outliner File Format

Outliner stores documents in the XML data format.  This page describes the XML nodes and attribute structure for the Outliner file format.  All attributes listed in the description below are optional unless otherwise specified.

## XML Format Description

### Header
Because Outliner documents are XML documents, the first line of the file must be:

`<?xml version="1.0"?>`

### Main Node

- **Parent:**  none

The main node is the `outliner` node which must be the first XML node of the document.  This node may contain the following attributes.

| Attribute | Values | Default | Description |
| - | - | - | - |
| condensed | true<br>false | false | Specifies if the document should be displayed in the condensed format (true) or normal format (false). |
| listtype | none<br>outline<br>section | none | Specifies the outline format displayed to the left of the text in a row.  A value of "none" displays no value.  A value of "outline" displays I., A., 1., a., etc. depending on the depth.  A value of "section" displays section and subsection information in the form of 3., 3.1., 3.1.2., etc. |
| version | ex. 1.8.0 | | Outliner version that output this file type. |
| name-font-family | Font family | Sans | Font family used in the row text. |
| name-font-size | _number_ | 12 | Font size used in the row text. |
| note-font-family | Font family | Sans | Font family used in the note text. |
| note-font-size | _number_ | 12 | Font size used in the note text. |
| show-tasks | true<br>false | false | Controls whether task checkboxes are displayed in the document. |
| show-depth | true<br>false | false | Controls whether depth lines are displayed in the document. |
| markdown | true<br>false | false | Controls whether rich-text formatting is used or Markdown formatting is used. |

### Theme

- **Parent:** `outliner`

The theme node represents which of the built-in themes to use when displaying the document.  The node has a single parameter: `name`.  This attribute can have one of the following values:

- default
- dark
- solarized_light
- solarized_dark

### Nodes

- **Parents:** `outliner` or `node`

This node contains zero or more `node` child nodes where each node is a row within the group.  This node contains no attributes.

### Node

- **Parent:** `nodes`

The `node` XML node represents a single row in the outline.  This XML node contains the following attributes:

| Attribute | Values | Default | Description |
| - | - | - | - |
| expanded | true<br>false | true | If this node has child nodes, this attribute specifies whether those children are displayed in the outline (true) or not (false). |
| hidenote | true<br>false | true | If this node contains a note, specifies if the note should be displayed (false) or hidden (true). |
| task | open<br>doing<br>done<br>none | none | If tasks are enabled, specifies the display of the task checkbutton in the document.  A value of "none" means that a checkbox will not be displayed.  A value of "open" displays an empty checkbox.  A value of "doing" displays a checkbox with a dash within it.  A value of "done" displays a checkbox with a check within it. |

#### Node Data

- **Parent:** `node`

The `name` XML node contains data about the row text including the text itself as well as positional information and rich-text formatting information.  The following attributes are valid for this node; however, all attributes are optional and should not be set for external applications.

| Attribute | Values | Description |
| - | - | - |
| posx | _number_ | Specifies the X dimension position of the row text. |
| poxy | _number_ | Specifies the Y dimension position of the row text. |
| maxwidth | _number_ | Width of the row text in the default window size. |

#### Note Data

- **Parent:** `node`

The `note` XML node contains data about the row note including the text itself as well as positional information and rich-text formatting information.  The following attributes are valid for this node; however, all attributes are optional and should not be set for external applications.

| Attribute | Values | Description |
| - | - | - |
| posx | _number_ | Specifies the X dimension position of the row text. |
| poxy | _number_ | Specifies the Y dimension position of the row text. |
| maxwidth | _number_ | Width of the row text in the default window size. |

##### Node/Note Text

- **Parents:** `name` or `note`

The `text` XML node represents the text of the row text or row note.  This XML node has only one attribute: `data`.  The contents of this attribute is the raw text.

###### Node/Note Formatting Tags

- **Parent:** `text`

These XML nodes represent the various rich-text formatting tags, their start/end positions in the text, and any additional information associated with the formatting tag (i.e., header number, RGB color value, link, etc.).  If the text does not have any text tagged with a given tag, the tag does not need to be displayed in the document.  The following nodes fall within this category.

| Node | Description |
| - | - |
| `bold` | Represents the bold tags in the text. |
| `italics` | Represents the italicized tags in the text. |
| `underline` | Represents the underlined tags in the text. |
| `strikethru` | Represents the stricken tags in the text. |
| `code` | Represents the code tags in the text. |
| `subscript` | Represents the subscript tags in the text. |
| `superscript` | Represents the superscript tags in the text. |
| `header` | Represents header tags in the text.  The value of the `extra` attribute is a value of 1 through 6, representing the size of the header. |
| `color` | Represents font foreground coloring tags in the text.  The value of the `extra` attribute is the RGB value of the color. |
| `hilite` | Represents font background coloring tags in the text.  The value of the `extra` attribute is the RGB value of the color. |
| `url` | Represents link tags in the text.  The value of the `extra` attribute is the URL associated with the link. |

###### Formatting Tag Ranges

- **Parent:** `bold`, `italics`, `underline`, `strikethru`, `code`, `subscript`, `superscript`, `header`, `color`, `hilite` or `url`

The `range` XML node represents a single segment of formatted text for the associated tag.  This node has the following mandatory attributes.  Each `text` node can have one or more `range` nodes.

| Attributes | Value | Description |
| - | - | - |
| start | _number_ | Represents the byte position of the first character in the tag. |
| end | _number_ | Represents the byte position of the character that is one greater than the last character in the tag. |
| extra | _number_<br>_RGB_<br>_URL_ | Only valid for certain types of tags (`header`, `color`, `hilite`, `url`). |

## Labels

- **Parent:** `outliner`

The `labels` XML node contains zero or more labels used within the document.  These will be applied when the document is first displayed.  A document can have up to 9 labels where each label must have a value between 1 and 9, inclusive.  For external applications, this node should be avoided.

### Label

- **Parent:** `labels`

The `label` XML node contains information about a single label.  This node must have the following attributes specified.

| Attribute | Values | Description |
| - | - | - |
| index | 0-8 | Specifies which of the 9 labels this one pertains to. |
| node | _value_ | Specifies which node in the document that this label is associated with.  The value is a comma-separated list of numbers where each number is the child index of its parent and the comma represents a hierarchical depth.  (Example:  3,3,0  The fourth main row, fourth child row of that row, first row of that row). |

## Tags

- **Parent:** `outliner`

The `tags` XML node represents all of the used tags in the document.  This list of tags is used for tag auto-completion and selection.  Each `tags` node can have zero or more `tag` nodes specified within it.

### Tag

- **Parent:** `tags`

The `tag` XML node represents a single tag used in the document.  This node contains the following required attributes.

| Attribute | Value | Description |
| - | - | - |
| value | _tag-text_ | Specifies the name of the tag without the preceding '@' symbol. |
| count | _number_ | Specifies the number of rows that use this tag. |

