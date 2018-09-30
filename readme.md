# ![icon](easy-move-resize/Images.xcassets/AppIcon.appiconset/icon_32x32.png) Easy Move+Resize

Easy Move+Resize and an easy `modifier key + mouse move` operation to OSX.

Hold down a modifier (combination) and move you mouse pointer over a window to "grab" it anywhere to move it. Similarly, hold down another modifier (combination) to resize the window as is you were dragging from the bottom right window corner from within anywhere in the window.

For instance, in the follow screencast, holding `fn` and `ctrl` while moving the mouse moves the window, and holding `alt` in addition the window is being resized simply by moving the mouse pointer. This is great for mouse user but is particularly helpful when using a trackpad, where clicking and holding can be a harder gesture to do precisely.

## Usage

# FIXME: update

**Easy Move+Resize** is based on behavior found in many X11/Linux window managers

* `Cmd + Ctrl + Left Mouse` anywhere inside a window, then drag to move
* `Cmd + Ctrl + Right Mouse` anywhere inside a window, then drag to resize
    * the resize direction is determined by which region of the window is clicked.  *i.e.* a right-click in roughly the top-left corner of a window will act as if you grabbed the top left corner, whereas a right-click in roughly the top-center of a window will act as if you grabbed the top of the window
* The choice of modifier keys to hold down to activate dragging or resizing can be customized by toggling the appropriate modifier key name in the application icon menu.
    * Click the menu item to toggle it.
    * All keys toggled to selected must be held down for activation.
    * To restore the modifiers to the default `Cmd + Ctrl` select the `Rest to Defaults` menu item.
* Behavior can be disabled by toggling the `Disabled` item in the application icon menu.

## Installation

* Grab the latest version from the [Releases page](https://github.com/finestructure/easy-move-resize/releases)
* Unzip and run!
* Select **Exit** from the application icon to quit

    ![Icon](asset-sources/doc-img/running-icon.png)

    ![Icon Exit](asset-sources/doc-img/running-icon-exit.png)


## Contributing

[Contributions](contributing.md) welcome!

## Credits

This is a fork of the [original project](https://github.com/dmarcotte/easy-move-resize/releases) by [Daniel Marcotte](https://github.com/dmarcotte). His project uses mouse click based tracking, which I modified to use mouse moving. I initially tried to consolidate both modes and make them a preference but I did not manage to preserve Daniel's functionality.

I believe I was pretty close and the current state is still preserved in the code base. I have simply hidden the configuration options for "mouse click" mode in the preference window.

