# Outliner

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.phase1geo.outliner"><img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter" /></a>
</p>

![<center><b>Main Window - Dark Solarized Theme</b></center>](https://raw.githubusercontent.com/phase1geo/Outliner/master/data/screenshots/screenshot-solarized-dark.png "Outlining application for Elementary OS")

## Overview

Quickly create outlines and export them in a number of useful formats.

- Quickly create and navigate outlines using the keyboard or mouse.
- Full support for text formatting.
- Add notes to any outline text.
- Close/Hide any group within the outline for increased focus.
- Quick search and replace of any text within the document, including notes.
- View document statistics such as character count, word count and row count.
- Unlimited undo/redo of any change.
- Automatically saves in the background.
- Open multiple outlines with the use of tabs.
- Built-in themes.
- Import from Minder and OPML.
- Export to HTML, Markdown, Minder, OPML, PDF and PlainText.
- Printer support.

## Installation

### Dependencies
These dependencies must be present before building:
 - `meson`
 - `valac`
 - `debhelper`
 - `libgranite-dev`
 - `libgtk-3-dev`
 - `libxml2-dev`
 - `libwebkit2gtk-4.0-dev`
 - `libmarkdown2-dev`

Use the App script to simplify installation by running `./app install-deps`

### Building

```
git clone git@github.com:phase1geo/Outliner.git com.github.phase1geo.outliner && cd com.github.phase1geo.outliner
./app install-deps && ./app install
```

### Deconstruct

```
./app uninstall
```

### Development & Testing

Outliner includes a script to simplify the development process. This script can be accessed in the main project directory through `./app`.

```
Usage:
  ./app [OPTION]

Options:
  clean             Removes build directories (can require sudo)
  generate-i18n     Generates .pot and .po files for i18n (multi-language support)
  install           Builds and installs application to the system (requires sudo)
  install-deps      Installs missing build dependencies
  run               Builds and runs the application
  test              Builds and runs testing for the application
  test-run          Builds application, runs testing and if successful application is started
  uninstall         Removes the application from the system (requires sudo)
```

### License

This project is licensed under the GPL-3.0 License - see the [LICENSE](LICENSE.md) file for details.

<p align="center">
    <a href="https://appcenter.elementary.io/com.github.phase1geo.outliner">
        <img src="https://appcenter.elementary.io/badge.svg">
    </a>
</p>
