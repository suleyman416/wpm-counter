# WPM Counter

A words per minute counter for macOS. It shows your live typing speed in a small floating counter at the bottom right of the screen.

## Features

- Shows real time typing speed while you type in any application.
- Automatically fades out when you stop typing.
- Menu bar icon to pause the counter, change themes, or change idle timeout.
- Filters out key repeats when holding keys down.
- Ignores keyboard shortcuts like Command and Control.
- Requires two keystrokes to trigger so single keys like fullscreen do not show the counter.

## Requirements

- macOS 13.0 or later.
- Accessibility permission enabled in System Settings.

## Install

Run the install script in Terminal:

```bash
./install.sh
```

This builds the app, copies it to ~/Applications, and sets it to launch on login.

To uninstall:

```bash
./uninstall.sh
```

## How to Build

To build the app bundle manually:

```bash
./build_app.sh
```

The output will be in build/WPMCounter.app.

## Permissions

The app needs Accessibility access to detect keystroke timing across applications:

1. Open System Settings.
2. Go to Privacy and Security, then Accessibility.
3. Turn on the switch next to WPM Counter.

## License

MIT
