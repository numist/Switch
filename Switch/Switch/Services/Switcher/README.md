#  Window Switching

The files in this directory make up the window switcher service.

``` graphviz
digraph {
	concentrate=true
	Switcher -> SwitcherState [arrowhead="tee"]
	SwitcherState -> WindowInfoGroup [arrowhead="invodot"]
	WindowInfoGroup -> WindowInfo [arrowhead="inv"]
	
	Switcher -> SwitcherWindow [arrowhead="invodot"]
	SwitcherWindow -> SwitcherView [arrowhead="tee"]
	SwitcherView -> WindowView [arrowhead="invodot"]
	
	Switcher -> WindowInfoGroupListPublisher [arrowhead="odot"]
}

```

## `Switcher`

The `Switcher` type represents the service, and exists as connective tissue between a `SwitcherState` and its inputs and outputs:

### State machine inputs

* `Keyboard` hotkey callbacks
* an `EventTap` to monitor the release of the hotkey's modifier(s)
* window list updates posted by `WindowInfoGroupListPublisher`

### State machine outputs

* HAXcessibility for `raise` and `close` operations
* interface presentation, managed by one or more instances of `SwitcherWindow`

## `SwitcherState`

`SwitcherState` contains practically all conditional logic for the switcher, and is tested by `SwitcherStateTests` 

## `WindowInfo`

This value type represents one `NSWindow` displayed on the screen, primarily mirroring information found in each dictionary returned by `CGWindowListCopyWindowInfo`, plus available metadata from `NSRunningApplication` and HAXcessibility.

A list of the system's windows is returned by `get(onScreenOnly:)`. The string returned by `description` is valid Swift source code invoking `init(:)`, for creating an identical instance in unit tests.

## `WindowInfoGroup`

Some visible windows on the system are represented by more than one `NSWindow`. For example, the open/save panel is often a separate window presented by the system on top of the application's window. To account for this system idiom, this value type represents a logical group of windows by storing a "main" `WindowInfo` along with an ordered list (by z-height) of all related `WindowInfo` instances.

Unfortunately window groups can not be determined via public API, so `list(from:)` uses some heuristics to convert a `[WindowInfo]` into a reasonable `[WindowInfoGroup]`, but the heuristics are imperfect and a sufficiently rich source of issues that [the "quirk" label](https://github.com/numist/Switch/issues?q=is%3Aissue+label%3Aquirk) was created to track them.

The corpus of window grouping tests lives in `WindowInfoGroupTests/`, but a lot of porting from Switch 0.0.10 (β) is still required.
