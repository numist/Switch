3.3.0 (2020-07-12)
---

Improvements:

- Better German localization by [@J-rg](https://github.com/J-rg)
- Better Italian localization by [@ildede](https://github.com/ildede)
- `SRAXGlobalShortcutMonitor` defaults to listening only; new initializer allows to alter that
- `SRAXGlobalShortcutMonitor` does not uses CGEvent instead of NSEvent API as the latter is not thread safe
- Layout guide constraints for `SRRecorderControl` size are replaced with custom `intrinsicContentSize` 

3.2 (2020-04-17)
---

Improvements:

- Added support for modifier-only shortcuts
- The `*ShortcutMonitor` family of classes considers the `isEnabled` property of its actions before installing any handlers
- The `SRAXGlobalShortcutMonitor` uses Quartz Services to install an event tap via the `CGEvent*` family of functions.  
Unlike `SRGlobalShortcutMonitor`, it can alter handled events but requires the user to grant the Accessibility permission

Fixes:

- The control now shifts the label off the center to avoid clipping if there is enough space
- Better invalidation for re-draws
- Handle and warn when AppKit throws exception because NSEvent's `characters*` properties are accessed from a non-main thread

3.1 (2019-10-19)
---

Improvements:

- Added support for key up events in Shortcut Monitors
- Style can now customize no-value labels and tooltips
- Reviewed and fixed translations to match modern Apple vocabulary
- New and shorter label for the control when there is no value
- New tooltip for the clean button
- New tooltip for the cancel button when there no value: "use old shortcut" does not make sense if there is no old shortcut

Fixes:

- Fix various errors and edge cases in Shortcut Monitors
- Fix undefined behavior warning due to a missing `nullable` in the `-[SRRecorderControl propagateValue:forKey:] definition
- Fix incorrect intrinsic width of the control (was visible only after certain style customizations)
