Switch, Window-Based Context Switching
======================================

Switch is a window-based (as opposed to application-based) context switcher. By default it is bound to using `⌥⇥` and `⌥⇧⇥` to cycle through the visible windows on the current space. When the interface is active, `⌥W` can be used to close windows and `⌥,` used to show a preferences window. The main interface looks like this:

![Interface Screenshot](http://numist.net/random/switch.png)

This project is functional, but not finished. I'm using it every day, but I could use your help.

Contributions in the form of [beers](mailto:numist@numist.net?cc=pay@square.com&subject=Here%27s%20%245&body=For%20a%20Switch%20beer%21), [patches](https://github.com/numist/Switch/pull/new), and [issues](https://github.com/numist/Switch/issues) are appreciated. If a window is being improperly shown or omitted from the interface, please include a [snapshot](https://github.com/numist/Switch/wiki/About-Snapshots).

Getting Started
---------------

Download the [latest release](https://github.com/numist/Switch/releases), put the application bundle in your `/Applications` or `~/Applications` directory, and run it! It will check for updates automatically so you can stay up to date as the project develops.

Switch requires Mac OS X version 10.9 or newer and is still in development. For a list of known issues, check out the [bug tag](https://github.com/numist/Switch/issues?labels=bug&state=open) for general badness and the [quirk tag](https://github.com/numist/Switch/issues?labels=quirk&state=open) for windows being improperly shown or omitted from the interface.

Contributing
------------

[![Stories in Ready](https://badge.waffle.io/numist/switch.png?label=ready&title=Ready)](http://waffle.io/numist/switch) [![Build Status](https://travis-ci.org/numist/Switch.png?branch=develop)](https://travis-ci.org/numist/Switch)

To check out the project, its submodules, and open in Xcode:

    git clone git://github.com/numist/Switch.git
    cd Switch/
    rake deps
    open Switch.xcworkspace

At this point, `⌘R` should have you up and running!

The release process uses the project `Rakefile`; if you have a Developer ID certificate installed, you should be able to run `rake release` without any issues. Without a Developer ID, the `analyze`, `test`, and `app` targets (and their dependencies) should succeed.

Thanks!
-------

Switch relies on a number of external frameworks, either as [submodules](https://github.com/numist/Switch/tree/develop/Frameworks) or [pods](https://github.com/numist/Switch/tree/develop/Podfile). Thanks to the people responsible for them, you've saved me time and tears.
