Switch, Window-Based Context Switching
======================================

Switch is a window-based (as opposed to application-based) context switcher. By default it is bound to using `⌥⇥` and `⌥⇧⇥` to cycle through the visible windows on the current space. When the interface is active, `⌥W` can be used to close windows and `⌥,` used to show a preferences window.

The main interface looks like this:

![Interface Screenshot](http://numist.net/random/switch.png)

This project is functional, but not finished. That said, I use it every day.

[Patches](https://github.com/numist/Switch/pull/new) and [issues](https://github.com/numist/Switch/issues) are welcome. If a window is being improperly shown or omitted from the interface, please include a [snapshot](https://github.com/numist/Switch/wiki/About-Snapshots).

I want it!
----------

Download the [latest release](https://github.com/numist/Switch/releases), put the application bundle in your `/Applications` or `~/Applications` directory, and run it! It will check for updates automatically so you can stay up to date as the project develops.

Switch requires Mac OS X version 11.0 or newer and is still in development. For a list of known issues, check out the [bug tag](https://github.com/numist/Switch/issues?labels=bug&state=open) for general badness and the [quirk tag](https://github.com/numist/Switch/issues?labels=quirk&state=open) for windows being improperly shown/omitted in the interface.

Contributing
------------

To check out the project, its submodules, and open in Xcode:

    git clone git://github.com/numist/Switch.git
    cd Switch/
    open Switch.xcworkspace

`⌘R` should have you up and running! Any changes require Accessibility re-authorization in the Security & Privacy preferences pane—it's useful to just keep it open when iterating.
