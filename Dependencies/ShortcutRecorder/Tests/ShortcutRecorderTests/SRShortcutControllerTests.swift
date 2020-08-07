//
//  Copyright 2018 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest
import ShortcutRecorder


class SRShortcutControllerTests: XCTestCase {
    func testInitialization() {
        let c = ShortcutController(content: Shortcut.default)
        let selection = c.value(forKey: "selection") as! NSObject
        let shortcutDict: Dictionary = (c.content as! Shortcut).dictionaryRepresentation
        let selectionDict = selection.dictionaryWithValues(forKeys: [
            ShortcutKey.keyCode.rawValue,
            ShortcutKey.modifierFlags.rawValue,
            ShortcutKey.characters.rawValue,
            ShortcutKey.charactersIgnoringModifiers.rawValue
        ]) as NSDictionary
        XCTAssertTrue(selectionDict.isEqual(to: shortcutDict))
    }

    func testComputedPropertiesAccess() {
        func compareKeys(_ controller: ShortcutController, _ controllerKeyPath: ShortcutControllerKeyPath, _ selectionKey: ShortcutControllerSelectionKey) {
            let selection = controller.value(forKey: "selection") as! NSObject
            let controllerValue = controller.value(forKeyPath: controllerKeyPath.rawValue) as? NSObject
            let selectionValue = selection.value(forKey: selectionKey.rawValue) as? NSObject
            XCTAssertEqual(controllerValue, selectionValue)
        }

        for content in [Shortcut.default, nil] {
            let c = ShortcutController(content: content)
            compareKeys(c, .keyEquivalent, .keyEquivalent)
            compareKeys(c, .keyEquivalentModifierMask, .keyEquivalentModifierMask)
            compareKeys(c, .literalKeyCode, .literalKeyCode)
            compareKeys(c, .symbolicKeyCode, .symbolicKeyCode)
            compareKeys(c, .literalASCIIKeyCode, .literalASCIIKeyCode)
            compareKeys(c, .symbolicASCIIKeyCode, .symbolicASCIIKeyCode)
            compareKeys(c, .literalModifierFlags, .literalModifierFlags)
            compareKeys(c, .symbolicModifierFlags, .symbolicModifierFlags)
        }
    }

    func testNoSelectionMarker() {
        let c = ShortcutController(content: nil)
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.keyEquivalent.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.keyEquivalentModifierMask.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.literalKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.literalASCIIKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicASCIIKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.literalModifierFlags.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicModifierFlags.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))

        c.content = Shortcut.default
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.keyEquivalent.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.keyEquivalentModifierMask.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.literalKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.literalASCIIKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicASCIIKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.literalModifierFlags.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertFalse((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicModifierFlags.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))

        c.content = nil
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.keyEquivalent.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.keyEquivalentModifierMask.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.literalKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.literalASCIIKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicASCIIKeyCode.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.literalModifierFlags.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
        XCTAssertTrue((c.value(forKeyPath: ShortcutControllerKeyPath.symbolicModifierFlags.rawValue) as! NSObject).isEqual(NSNoSelectionMarker))
    }

    func testComputedPropertiesObservation() {
        class AssertObserver : NSObject {
            let oldValue: Any
            let newValue: Any
            let keyPath: String?
            var isCalled = false

            init(oldValue: Any, newValue: Any, keyPath: String) {
                self.oldValue = oldValue
                self.newValue = newValue
                self.keyPath = keyPath
                super.init()
            }

            override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                XCTAssertFalse(self.isCalled)
                XCTAssertEqual(self.keyPath, keyPath)
                XCTAssertTrue((self.oldValue as! NSObject).isEqual(change![.oldKey]))
                XCTAssertTrue((self.oldValue as! NSObject).isEqual(change![.newKey]))
                self.isCalled = true
            }
        }

        func addObserver(_ controller: ShortcutController, _ keyPath: ShortcutControllerKeyPath, _ old: [String: Any], _ new: [String: Any]) -> AssertObserver {
            let o = AssertObserver(oldValue: old[keyPath.rawValue]!, newValue: new[keyPath.rawValue]!, keyPath: keyPath.rawValue)
            controller.addObserver(o, forKeyPath: keyPath.rawValue, options: [.old, .new], context: nil)
            return o
        }

        func getComputed(_ shortcut: Shortcut) -> [String: Any] {
            return (ShortcutController(content: shortcut).selection as! NSObject).dictionaryWithValues(forKeys: [
                ShortcutControllerKeyPath.keyEquivalent.rawValue,
                ShortcutControllerKeyPath.keyEquivalentModifierMask.rawValue,
                ShortcutControllerKeyPath.literalKeyCode.rawValue,
                ShortcutControllerKeyPath.symbolicKeyCode.rawValue,
                ShortcutControllerKeyPath.literalASCIIKeyCode.rawValue,
                ShortcutControllerKeyPath.symbolicASCIIKeyCode.rawValue,
                ShortcutControllerKeyPath.literalModifierFlags.rawValue,
                ShortcutControllerKeyPath.symbolicModifierFlags.rawValue
            ])
        }

        let s1 = Shortcut(code: KeyCode.ansiA, modifierFlags: .option, characters: "å", charactersIgnoringModifiers: "a")
        let s2 = Shortcut(code: KeyCode.ansiS, modifierFlags: .command, characters: "b", charactersIgnoringModifiers: "b")

        let s1Computed = getComputed(s1)
        let s2Computed = getComputed(s2)

        let c = ShortcutController(content: s1)
        let observers = [
            addObserver(c, .keyEquivalent, s1Computed, s2Computed),
            addObserver(c, .keyEquivalentModifierMask, s1Computed, s2Computed),
            addObserver(c, .literalKeyCode, s1Computed, s2Computed),
            addObserver(c, .symbolicKeyCode, s1Computed, s2Computed),
            addObserver(c, .literalASCIIKeyCode, s1Computed, s2Computed),
            addObserver(c, .symbolicASCIIKeyCode, s1Computed, s2Computed),
            addObserver(c, .literalModifierFlags, s1Computed, s2Computed),
            addObserver(c, .symbolicModifierFlags, s1Computed, s2Computed)
        ]

        c.content = s2
        for o in observers {
            XCTAssertTrue(o.isCalled)
        }
    }

    func testShortcutActionManagement() {
        class Target: NSObject, ShortcutActionTarget {
            func perform(shortcutAction anAction: ShortcutAction) -> Bool {
                return true
            }
        }

        let shortcut = Shortcut(keyEquivalent: "⌘A")
        let controller = ShortcutController(content: shortcut)
        controller.identifier = "shortcut"

        XCTAssertNil(controller.shortcutAction)


        let target = Target()
        controller.shortcutActionTarget = target

        XCTAssertEqual(controller.shortcutAction?.shortcut, shortcut)
        XCTAssertTrue(controller.shortcutAction?.target === target)
        XCTAssertTrue(controller.shortcutAction?.observedObject === controller)
        XCTAssertEqual(controller.shortcutAction?.observedKeyPath, "content")

        controller.shortcutActionTarget = nil
        XCTAssertNil(controller.shortcutAction)
    }
}
