Switch, Window-Based Context Switching
======================================

Switch is a window-based (as opposed to application-based) context switcher. By default it is bound to using `⌥⇥` and `⌥⇧⇥` to cycle through the visible windows on the current space. When the interface is active, `⌥W` can be used to close windows and `⌥,` used to show a preferences window. The main interface looks like this:

![Interface Screenshot](http://numist.net/random/switch.png)

This project is functional, but not finished. I'm using it every day, but I could use your help.

Contributions in the form of [beers](mailto:numist@numist.net?cc=pay@square.com&subject=Here%27s%20%245&body=For%20a%20Switch%20beer%21), [patches](https://github.com/numist/Switch/pull/new), and [issues](https://github.com/numist/Switch/issues) are appreciated. If a window is being improperly shown or omitted from the list, please include a [snapshot](https://github.com/numist/Switch/wiki/About-Snapshots).

Getting Started
---------------

Download the [latest release](https://github.com/numist/Switch/releases), put the application bundle in your `/Applications` or `~/Applications` directory, and run it! It will check for updates automatically so you can stay up to date as the project develops.

Switch requires Mac OS X version 10.8 or newer and is still in development. For a list of known issues, check out the [bug tag in Issues](https://github.com/numist/Switch/issues?labels=bug&state=open).

Contributing
------------

To check out the project, its submodules, and open in Xcode:

    git clone git://github.com/numist/Switch.git
    cd Switch/
    git submodule sync
    git submodule update --init --recursive
    open Switch.xcodeproj

At this point, `⌘R` should have you up and running!

**NOTE:** Building Switch requires Mac OS X version 10.8 or newer and Xcode 5.

Thanks!
-------

Switch relies on a number of [external frameworks](https://github.com/numist/Switch/tree/develop/Frameworks), thanks to the people responsible for them, you've saved me time and tears. Special thanks to @robrix.

A number of people have influenced Switch's development without being authors (or perhaps even realizing it). Thanks to:
* [@andymatuschak](https://github.com/andymatuschak)
* [@Catfish_Man](https://twitter.com/Catfish_Man) and the NSCoders in general
* [@gwynne](https://github.com/gwynne)
* [@quicklywilliam](https://github.com/quicklywilliam)
* [@zadr](https://github.com/zadr)
