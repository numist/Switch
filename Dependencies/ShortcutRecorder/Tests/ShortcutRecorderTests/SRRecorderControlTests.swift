//
//  Copyright 2018 ShortcutRecorder Contributors
//  CC BY 4.0
//

import Cocoa
import XCTest

import ShortcutRecorder


class Delegate: NSObject, RecorderControlDelegate {
    var shouldBegingRecording = true
}


class SRRecorderControlTests: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "shortcut")
    }

    func testCellIsNil() {
        XCTAssertNil(RecorderControl().cell)
    }

    func testEnabled() {
        let c = RecorderControl()
        XCTAssertTrue(c.isEnabled)
        c.isEnabled = false
        XCTAssertFalse(c.isEnabled)
    }

    func testRefusesFirstResponder() {
        let c = RecorderControl()
        XCTAssertFalse(c.refusesFirstResponder)
        c.refusesFirstResponder = true
        XCTAssertTrue(c.refusesFirstResponder)
    }

    func testTag() {
        let c = RecorderControl()
        XCTAssertEqual(c.tag, 0)
        c.tag = 42
        XCTAssertEqual(c.tag, 42)
    }

    func testAcceptsFirstResponder() {
        let c = RecorderControl()
        XCTAssertTrue(c.acceptsFirstResponder)

        c.isEnabled = false
        c.refusesFirstResponder = false
        XCTAssertFalse(c.acceptsFirstResponder)

        c.isEnabled = false
        c.refusesFirstResponder = true
        XCTAssertFalse(c.acceptsFirstResponder)

        c.isEnabled = true
        c.refusesFirstResponder = false
        XCTAssertTrue(c.acceptsFirstResponder)

        c.isEnabled = true
        c.refusesFirstResponder = true
        XCTAssertFalse(c.acceptsFirstResponder)
    }

    func testComaptibilityBindingAndModelChange() {
        let v = RecorderControl()
        v.bind(NSBindingName.value, to: NSUserDefaultsController.shared, withKeyPath: "values.shortcut", options: nil)
        let keyCode: UInt16 = 0
        let modifierFlags: NSEvent.ModifierFlags = [.command, .option]
        let objectValue: [ShortcutKey: Any] = [ShortcutKey.keyCode: keyCode, ShortcutKey.modifierFlags: modifierFlags.rawValue]
        UserDefaults.standard.set(objectValue as NSDictionary, forKey: "shortcut")
        XCTAssertEqual(v.objectValue![.keyCode] as! UInt16, keyCode)
        XCTAssertEqual(v.objectValue![.modifierFlags] as! UInt, modifierFlags.rawValue)
        XCTAssertTrue(v.value(forKey: "isCompatibilityModeEnabled") as! Bool)
    }

    func testComaptibilityBindingAndViewChangeWithDictionary() {
        let v = RecorderControl()
        v.bind(NSBindingName.value, to: NSUserDefaultsController.shared, withKeyPath: "values.shortcut", options: nil)
        let keyCode: UInt16 = 0
        let modifierFlags: NSEvent.ModifierFlags = [.command, .option]
        let objectValue: [ShortcutKey: Any] = [ShortcutKey.keyCode: keyCode, ShortcutKey.modifierFlags: modifierFlags.rawValue]
        v.setValue(objectValue as NSDictionary, forKey: "objectValue")
        XCTAssertEqual(UserDefaults.standard.value(forKeyPath: "shortcut.keyCode") as! UInt16, keyCode)
        XCTAssertEqual(UserDefaults.standard.value(forKeyPath: "shortcut.modifierFlags") as! UInt, modifierFlags.rawValue)
        XCTAssertTrue(v.value(forKey: "isCompatibilityModeEnabled") as! Bool)
    }

    func testComaptibilityBindingAndViewChangeWithShortcut() {
        let v = RecorderControl()
        v.bind(NSBindingName.value, to: NSUserDefaultsController.shared, withKeyPath: "values.shortcut", options: nil)
        let keyCode = KeyCode.ansiA
        let modifierFlags: NSEvent.ModifierFlags = [.command, .option]
        let objectValue = Shortcut(code: keyCode, modifierFlags: modifierFlags, characters: nil, charactersIgnoringModifiers: nil)
        v.setValue(objectValue, forKey: "objectValue")
        XCTAssertEqual(UserDefaults.standard.value(forKeyPath: "shortcut.keyCode") as! UInt16, keyCode.rawValue)
        XCTAssertEqual(UserDefaults.standard.value(forKeyPath: "shortcut.modifierFlags") as! UInt, modifierFlags.rawValue)
        XCTAssertTrue(v.value(forKey: "isCompatibilityModeEnabled") as! Bool)
    }

    func testStyleIsCopied() {
        let s = RecorderControlStyle()
        let v1 = RecorderControl()
        let v2 = RecorderControl()

        v1.style = s
        v2.style = s

        XCTAssertFalse(v1.style === v2.style)
    }

    func testObjectValueAffectsDictionaryValueKVO() {
        let v = RecorderControl()
        var calls: [[NSDictionary?]] = []

        let observation = v.observe(\RecorderControl.dictionaryValue, options: [.old, .new]) { (_, change) in
            calls.append([change.oldValue as? NSDictionary, change.newValue as? NSDictionary])
        }

        defer {
            observation.invalidate()
        }

        let s1 = Shortcut(code: KeyCode.ansiA,
                          modifierFlags: .command,
                          characters: "A",
                          charactersIgnoringModifiers: "a")
        v.objectValue = s1
        let s2 = Shortcut(code: KeyCode.ansiB,
                          modifierFlags: .command,
                          characters: "B",
                          charactersIgnoringModifiers: "b")
        v.objectValue = s2

        let expected = [[nil, s1.dictionaryRepresentation], [s1.dictionaryRepresentation, s2.dictionaryRepresentation]]
        XCTAssertTrue((calls as NSArray).isEqual(to: expected))
    }

    func testSettingStyleDoesntCauseLazyLoading() {
        class Control: RecorderControl {
            let expectation = XCTestExpectation(description: "makeDefaultStyle", isInverted: true)

            override func makeDefaultStyle() -> RecorderControlStyle {
                expectation.fulfill()
                return super.makeDefaultStyle()
            }
        }

        let control = Control()
        control.style = RecorderControlStyle()
        wait(for: [control.expectation], timeout: 0)
    }

    func testSettingStyleNotifications() {
        class Style: RecorderControlStyle {
            let prepareForRecorderControlExpectation = XCTestExpectation(description: "prepareForRecorderControl",
                                                                         assertForOverFulfill: true)
            let recorderControlAppearanceDidChangeExpectation = XCTestExpectation(description: "recorderControlAppearanceDidChange",
                                                                                  assertForOverFulfill: true)

            override func prepareForRecorderControl(_ aControl: RecorderControl) {
                prepareForRecorderControlExpectation.fulfill()
                super.prepareForRecorderControl(aControl)
            }

            override func recorderControlAppearanceDidChange(_ aReason: Any?) {
                recorderControlAppearanceDidChangeExpectation.fulfill()
                super.recorderControlAppearanceDidChange(aReason)
            }
        }

        let control = RecorderControl()
        control.style = Style()
        wait(for: [(control.style as! Style).prepareForRecorderControlExpectation,
                   (control.style as! Style).recorderControlAppearanceDidChangeExpectation], timeout: 0, enforceOrder: true)
    }

    func testUserInterfaceLayoutDirectionKVO() {
        let control = RecorderControl()
        let leftToRight = RecorderControlStyle.Components(appearance: .unspecified,
                                                          accessibility: [],
                                                          layoutDirection: .leftToRight,
                                                          tint: .unspecified)
        let rightToLeft = RecorderControlStyle.Components(appearance: .unspecified,
                                                          accessibility: [],
                                                          layoutDirection: .rightToLeft,
                                                          tint: .unspecified)

        control.style = RecorderControlStyle(identifier: nil, components: leftToRight)
        var expectation = keyValueObservingExpectation(for: control, keyPath: "userInterfaceLayoutDirection",
                                                       expectedValue: NSUserInterfaceLayoutDirection.rightToLeft.rawValue)
        control.style = RecorderControlStyle(identifier: nil, components: rightToLeft)
        wait(for: [expectation], timeout: 0)
        expectation = keyValueObservingExpectation(for: control, keyPath: "userInterfaceLayoutDirection",
                                                   expectedValue: NSUserInterfaceLayoutDirection.leftToRight.rawValue)
        control.style = RecorderControlStyle(identifier: nil, components: leftToRight)
        wait(for: [expectation], timeout: 0)
    }

    func testAppearanceKVO() {
        let control = RecorderControl()
        let aqua = RecorderControlStyle.Components(appearance: .aqua,
                                                   accessibility: [],
                                                   layoutDirection: .unspecified,
                                                   tint: .unspecified)
        let darkAqua = RecorderControlStyle.Components(appearance: .darkAqua,
                                                       accessibility: [],
                                                       layoutDirection: .unspecified,
                                                       tint: .unspecified)

        control.style = RecorderControlStyle(identifier: nil, components: aqua)
        var expectation = keyValueObservingExpectation(for: control, keyPath: "appearance",
                                                       expectedValue: NSAppearance(named: .darkAqua))
        control.style = RecorderControlStyle(identifier: nil, components: darkAqua)
        wait(for: [expectation], timeout: 0)
        expectation = keyValueObservingExpectation(for: control, keyPath: "appearance",
                                                   expectedValue: NSAppearance(named: .aqua))
        control.style = RecorderControlStyle(identifier: nil, components: aqua)
        wait(for: [expectation], timeout: 0)
    }

    func testStringValueKVO() {
        let control = RecorderControl()
        control.userInterfaceLayoutDirection = .leftToRight
        control.stringValueRespectsUserInterfaceLayoutDirection = false
        control.objectValue = Shortcut(keyEquivalent: "⇧⌘A")!

        var expectation = keyValueObservingExpectation(for: control, keyPath: "stringValue", expectedValue: "⇧⌘A")
        control.userInterfaceLayoutDirection = .rightToLeft
        wait(for: [expectation], timeout: 0)

        expectation = keyValueObservingExpectation(for: control, keyPath: "stringValue", expectedValue: "⇧⌘A")
        control.userInterfaceLayoutDirection = .leftToRight
        wait(for: [expectation], timeout: 0)

        expectation = keyValueObservingExpectation(for: control, keyPath: "stringValue", expectedValue: "⇧⌘A")
        control.stringValueRespectsUserInterfaceLayoutDirection = true
        wait(for: [expectation], timeout: 0)

        expectation = keyValueObservingExpectation(for: control, keyPath: "stringValue", expectedValue: "A⌘⇧")
        control.userInterfaceLayoutDirection = .rightToLeft
        wait(for: [expectation], timeout: 0)

        expectation = keyValueObservingExpectation(for: control, keyPath: "stringValue", expectedValue: "⇧⌘A")
        control.userInterfaceLayoutDirection = .leftToRight
        wait(for: [expectation], timeout: 0)
    }

    func testDisallowedEmptyModifierFlags() {
        let control = RecorderControl()
        control.set(allowedModifierFlags: CocoaModifierFlagsMask,
                    requiredModifierFlags: [],
                    allowsEmptyModifierFlags: false)
        XCTAssertFalse(control.areModifierFlagsAllowed([], for: .ansiA))
    }
}
