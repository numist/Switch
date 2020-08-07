/*:
 - Important:
 Playground uses Live View.
 */
import AppKit
import PlaygroundSupport
import ShortcutRecorder

PlaygroundPage.current.needsIndefiniteExecution = true
let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 150, height: 50))
PlaygroundPage.current.liveView = mainView

let control = RecorderControl()
mainView.addSubview(control)
NSLayoutConstraint.activate([
    control.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
    control.centerYAnchor.constraint(equalTo: mainView.centerYAnchor)
])
/*:
 ### Configuring Modifier Flags Requirements
 `RecorderControl` allows you to forbid some modifier flags while require other.

 There are 3 properties that govern this behavior:
 - `allowedModifierFlags` controls what flags *can* be set
 - `requiredModifierFlags` controls what flags *must* be set
 - `allowsEmptyModifierFlags` controls whether no modifier flags are allowed

 - Important:
 The control will validate the settings raising an exception for conflicts like marking the flag both disallowed and required.
 */
//control.set(allowedModifierFlags: [.command, .shift, .control], // ⌥ is not allowed
//    requiredModifierFlags: [.command, .shift], // ⌘ and ⇧ are required
//    allowsEmptyModifierFlags: false) // at least one modifier flag must be set
/*:
 ### Modifier flags only shortcut
 `RecorderControl` can be configured to record a shortcut that has modifier flags (e.g. ⌘) but no key code. It may be useful for apps such as graphic editors as they often alter the behavior based on
 modifier flags.
 */
//control.allowsModifierFlagsOnlyShortcut = true
/*:
 ### Cancelling recording with Esc
 The control is configured by default to cancel recording when the Esc key is pressed with no modifier flags. As a side effect it is therefore impossibe to record the Esc key.
 */
//control.allowsEscapeToCancelRecording = false
/*:
 ### Clearning the recorded value with Delete
 Similarly the control is configured by default to clear the recorded value when the Delete key is pressed with no modifier flags. It has exactly the same side effect but for the Delete key this time.
 */
//control.allowsDeleteToClearShortcutAndEndRecording = false

/*:
 ### Communicating change to the controller
 */
class Controller: NSObject {
    @objc var objectValue: Shortcut?
}
/*:
 Change can be communicated via Target-Action
 */
//extension Controller {
//    @objc func action(sender: RecorderControl) {
//        objectValue = sender.objectValue
//        print("action: \(sender.stringValue)")
//    }
//}
//let target = Controller()
//control.target = target
//control.action = #selector(target.action(sender:))
/*:
 As well as via Cocoa Bindings and NSEditorRegistration
 */
//extension Controller: NSEditorRegistration {
//    func objectDidBeginEditing(_ editor: NSEditor) {
//        print("editor: did begin editing")
//    }
//
//    func objectDidEndEditing(_ editor: NSEditor) {
//        print("editor: did end editing with \((editor as! RecorderControl).stringValue)")
//    }
//}
//let controller = Controller()
//control.bind(.value, to: controller, withKeyPath: "objectValue", options: nil)
/*:
 And via a delegate
 */
//extension Controller: RecorderControlDelegate {
//    func recorderControlShouldBeginRecording(_ aControl: RecorderControl) -> Bool {
//        print("delegate: should begin editing")
//        return true
//    }
//
//    func recorderControlDidBeginRecording(_ aControl: RecorderControl) {
//        print("delegate: did begin editing")
//    }
//
//    func recorderControl(_ aControl: RecorderControl, shouldUnconditionallyAllowModifierFlags aFlags: Bool, forKeyCode aKeyCode: KeyCode) -> Bool {
//        print("delegate: should unconditionally allow modifier flags")
//        return true
//    }
//
//    func recorderControl(_ aControl: RecorderControl, canRecord aShortcut: Shortcut) -> Bool {
//        print("delegate: can record shortcut")
//        return true
//    }
//
//    func recorderControlDidEndRecording(_ aControl: RecorderControl) {
//        objectValue = aControl.objectValue
//        print("delegate: did end editing with \(aControl.stringValue)")
//    }
//}
//let controller = Controller()
//control.delegate = controller

/*:
 ### Shortcut
 The result of recording is an instance of `Shortcut`, a model class that represents recorded modifier flags and a key code.
 */
//let shortcut = Shortcut(keyEquivalent: "⌥⇧⌘A")!
//assert(shortcut.keyCode == .ansiA)
//assert(shortcut.modifierFlags == [.option, .shift, .command])
/*:
 The `characters` and `charactersIgnoringModifiers` are similar to those of `NSEvent`, and return string-representation of the key code and modifier flags, if available.
 */
//print("Shortcut Characters: \(shortcut.characters!)")
//print("Shortcut Characters Ignoring Modifiers: \(shortcut.charactersIgnoringModifiers!)")
/*:
 Since some of the underlying API is using Carbon, there are properties to get Carbon-representation of the `keyCode` and `modifierFlags`:
 */
//print("Carbon Key Code: \(shortcut.carbonKeyCode)")
//print("Carbon Modifier Flags: \(shortcut.carbonModifierFlags)")

/*:
 ### Shortcut Validation
 The recorded shortcut is often used as either a key equivalent or a global shortcut. In either case you want to avoid assigning the same shortcut to multiple actions. `ShortcutValidator` helps to prevent these conflicts by checking against Main Menu and System Global Shortcuts for you.
 */
//let validator = ShortcutValidator()
//do {
//    try validator.validate(shortcut: Shortcut(keyEquivalent: "⌘Q"))
//}
//catch let error as NSError {
//    print(error.localizedDescription)
//}
/*:
 For convenience the validator implements the `RecorderControlDelegate/recorderControl(_:,canRecord:)`.
 */
//control.delegate = validator

/*:
 ### Cocoa Transformers
 Sometimes it's useful to display a shortcut outside of the recorder control. E.g. in a tooltip or in a label.

 `ShortcutFormatter`, a subclass of `NSFormatter`, can be used in standard Cocoa controls.
 */
//let textField = NSTextField(labelWithString: "")
//textField.formatter = ShortcutFormatter()
//textField.objectValue = Shortcut(keyEquivalent: "⇧⌘A")!
//print(textField.stringValue)
/*:
 A number of transformers, subclasses of `NSValueTransformer`, are available for custom alterations.

 #### KeyCodeTransformer
 `KeyCodeTransformer` is a class-cluster that transforms numeric key codes into `String`.

 Translation of a key code varies across combinations of keyboards and input sources. E.g. `KeyCode.ansiA` corresponds to "a" in the U.S. English input source but to "ф" in the Russian input source. In addition, some keys, like `KeyCode.tab`, have dual representation: as an input character (`\u{9}`) and as a drawable glyph (`⇥`). Some glyphs may be sensitive to layout direction, e.g. `KeyCode.tab` glyph for right-to-left languages is `⇤`.

 - Note:
 The ASCII-capable group is recommended as it provides consistent behavior for all users. It's what `RecorderControl` uses unless `drawsASCIIEquivalentOfShortcut` is set to `false`.

 There are 4 subclasses in the cluster:

 - `SymbolicKeyCodeTransformer`: translates a key code into an input character using current input source
 - `LiteralKeyCodeTransformer`: translates a key code into a drawable glyph using current input source
 - `ASCIISymbolicKeyCodeTransformer`: translates a key code into an input character using ASCII-capable input source
 - `ASCIILiteralKeyCodeTransformer`: translates a key code into a drawable glyph using ASCII-capable input source
 this is the only class in the cluster that *allows reverse transformation*
 */
//print("Symbolic Key Code: \"\(ASCIISymbolicKeyCodeTransformer.shared.transformedValue(KeyCode.tab) as! String)\"")
//print("Literal Key Code: \"\(ASCIILiteralKeyCodeTransformer.shared.transformedValue(KeyCode.tab) as! String)\"")
/*:
 #### ModifierFlagsTransformer
 `ModifierFlagsTransformer` is a class-cluster that transforms of modifier flags into a `String`.

 There are 2 subclasses in the cluster:
 - `SymbolicModifierFlagsTransformer` translates modifier flags into readable words, e.g. Shift-Command
 - `LiteralModifierFlagsTransformer` translates modifier flags into drawable glyphs, e.g. ⇧⌘
 */
//let flags: NSEvent.ModifierFlags = [.shift, .command]
//print("Symbolic Modifier Flags: \"\(SymbolicModifierFlagsTransformer.shared.transformedValue(flags.rawValue) as! String)\"")
//print("Literal Modifier Flags: \"\(LiteralModifierFlagsTransformer.shared.transformedValue(flags.rawValue) as! String)\"")
/*:
 #### Transformers
 Both are helper classes that can transform instances of `Shortcut` into Cocoa's `keyEquivalent` and `keyEquivalentModifierMask`. This allows to bind key paths leading to a `Shortcut` to Cocoa controls directly from Interface Builder.
 */
//print("Key Equivalent: \"\(KeyEquivalentTransformer.shared.transformedValue(shortcut) as! String)\"")
//print("Key Equivalent Modifier Mask: \"\(KeyEquivalentModifierMaskTransformer.shared.transformedValue(shortcut) as! UInt)\"")

/*:
 ### Shortcut Monitoring
 `GlobalShortcutMonitor` and `LocalShortcutMonitor` allows to perform actions in response to key events. Instance of either class can associate a shortcut (an object or a KVO path) with an action (a selector or a block).

 `GlobalShortcutMonitor` tries to register a system-wide hot key that can be triggered from any app.
*/
//let shortcut = Shortcut(keyEquivalent: "⌘A")
//let action = ShortcutAction(shortcut: Shortcut(keyEquivalent: "⌥⇧⌘A")!) { action in
//    print("Handle global shortcut")
//    return true
//}
//let globalMonitor = GlobalShortcutMonitor()
//globalMonitor.addAction(action, forKeyEvent: .down)
/*:
 `LocalShortcutMonitor` requires you to call the `handle(_:, withTarget:)` method with a key event and an optional target (for selector).

 `LocalShortcutMonitor` is designed to be used from:
 - `NSResponder/keyDown(with:)`
 - `NSResponder/keyUp(with:)`
 - `NSResponder/performKeyEquivalent(with:)`
 - `NSResponder/flagsChanged(with:)`
 - `NSEvent/addLocalMonitorForEvents(matching:handler:)`
 - `NSEvent/addGlobalMonitorForEvents(matching:handler:)`
 */
//let shortcut = Shortcut(keyEquivalent: "⌥⇧⌘A")!
//let action = ShortcutAction(shortcut: shortcut) { action in
//    print("Handle local shortcut")
//    return true
//}
//let event = NSEvent.keyEvent(with: .keyDown,
//                             location: NSPoint(x: 0, y: 0),
//                             modifierFlags: shortcut.modifierFlags,
//                             timestamp: 0,
//                             windowNumber: 0,
//                             context: nil,
//                             characters: "A",
//                             charactersIgnoringModifiers: "a",
//                             isARepeat: false,
//                             keyCode: UInt16(shortcut.keyCode.rawValue))!
//let localMonitor = LocalShortcutMonitor()
//localMonitor.addAction(action, forKeyEvent: .down)
//localMonitor.handle(event, withTarget: nil)
/*:
 It can be used to recognize and handle `keyCode`-less shortcuts
 */
//let event = NSEvent.keyEvent(with: .flagsChanged,
//                             location: NSPoint(x: 0, y: 0),
//                             modifierFlags: [.shift, .command],
//                             timestamp: 0,
//                             windowNumber: 0,
//                             context: nil,
//                             characters: "A",
//                             charactersIgnoringModifiers: "a",
//                             isARepeat: false,
//                             keyCode: UInt16(kVK_Command))!
//let shortcut = Shortcut(event: event)!
//let action = ShortcutAction(shortcut: shortcut) { action in
//    print("Handle local shortcut")
//    return true
//}
//let localMonitor = LocalShortcutMonitor()
//localMonitor.addAction(action, forKeyEvent: .down)
//localMonitor.handle(event, withTarget: nil)
