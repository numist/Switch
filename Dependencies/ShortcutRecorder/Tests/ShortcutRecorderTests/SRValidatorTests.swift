//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest
import ShortcutRecorder


class RecordingValidator : ShortcutValidator {
    enum FailAt {
        case delegate
        case system
        case menu
        case none
    }

    let failAt: FailAt

    let againstDelegateExpectation = XCTestExpectation(description: "validate against delegate")
    let againstSystemShortcutsExpectation = XCTestExpectation(description: "validate against system shortcuts")
    let againstMenuExpectation = XCTestExpectation(description: "validate against menu")

    init(delegate aDelegate: (NSObjectProtocol & ShortcutValidatorDelegate)? = nil, failAt: FailAt = .none)
    {
        self.failAt = failAt

        switch (failAt) {
        case .delegate:
            againstDelegateExpectation.isInverted = true
            againstSystemShortcutsExpectation.isInverted = true
            againstMenuExpectation.isInverted = true
        case .system:
            againstSystemShortcutsExpectation.isInverted = true
            againstMenuExpectation.isInverted = true
        case .menu:
            againstMenuExpectation.isInverted = true
        case .none:
            break
        }

        super.init(delegate: aDelegate)
    }

    convenience init(failAt: FailAt = .none) {
        self.init(delegate: nil, failAt: failAt)
    }

    override convenience init(delegate aDelegate: (NSObjectProtocol & ShortcutValidatorDelegate)?) {
        self.init(delegate: aDelegate, failAt: .none)
    }

    func assertExpectations(testCase: XCTestCase) {
        testCase.wait(for: [againstDelegateExpectation,
                            againstSystemShortcutsExpectation,
                            againstMenuExpectation], timeout: 0, enforceOrder: true)
    }

    override func validateAgainstDelegate(shortcut aShortcut: Shortcut) throws {
        if self.failAt != .delegate {
            againstDelegateExpectation.fulfill()
            try super.validateAgainstDelegate(shortcut: aShortcut)
        }
        else {
            throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
        }
    }

    override func validateAgainstSystemShortcuts(shortcut aShortcut: Shortcut) throws {
        if self.failAt != .system {
            againstSystemShortcutsExpectation.fulfill()
            try super.validateAgainstSystemShortcuts(shortcut: aShortcut)
        }
        else {
            throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
        }
    }

    override func validate(shortcut aShortcut: Shortcut, againstMenu aMenu: NSMenu) throws {
        if self.failAt != .menu {
            againstMenuExpectation.fulfill()
            try super .validate(shortcut: aShortcut, againstMenu: aMenu)
        }
        else {
            throw NSError.init(domain: NSCocoaErrorDomain, code: 0, userInfo: nil)
        }
    }
}


class SRValidatorTests: XCTestCase {
    func testValidationOrder() {
        let v1 = RecordingValidator()
        try! v1.validate(shortcut: Shortcut.default)

        let v2 = RecordingValidator(failAt: .delegate)
        try? v2.validate(shortcut: Shortcut.default)
        v2.assertExpectations(testCase: self)

        let v3 = RecordingValidator(failAt: .system)
        try? v3.validate(shortcut: Shortcut.default)
        v3.assertExpectations(testCase: self)

        let v4 = RecordingValidator(failAt: .menu)
        try? v4.validate(shortcut: Shortcut.default)
        v4.assertExpectations(testCase: self)
    }

    func testDelegateFailure() {
        class Delegate : NSObject, ShortcutValidatorDelegate {
            func shortcutValidator(_ aValidator: ShortcutValidator, isShortcutValid aShortcut: Shortcut, reason outReason: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
                outReason.pointee = "reason"
                return false
            }
        }

        let d = Delegate()
        let v = RecordingValidator(delegate: d)
        XCTAssertThrowsError(try v.validateAgainstDelegate(shortcut: Shortcut.default))
    }

    func testSystemShortcutsFailure() {
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validateAgainstSystemShortcuts(shortcut: Shortcut(keyEquivalent: "⌘⇥")!))
    }

    func testMenuFailure() {
        let m = NSMenu()
        m.addItem(NSMenuItem(title: "item", action: nil, keyEquivalent: "a"))
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validate(shortcut: Shortcut(keyEquivalent: "⌘a")!, againstMenu: m))
    }

    func testNestedMenuFailure() {
        let m = NSMenu()
        m.addItem(NSMenuItem(title: "item", action: nil, keyEquivalent: ""))
        m.items[0].submenu = NSMenu()
        m.items[0].submenu!.addItem(NSMenuItem(title: "subitem", action: nil, keyEquivalent: "a"))
        let v = RecordingValidator()
        XCTAssertThrowsError(try v.validate(shortcut: Shortcut(keyEquivalent: "⌘a")!, againstMenu: m))
    }
}
