//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest

import ShortcutRecorder


class SRShortcutFormatterTests: XCTestCase {
    func testFormatter() {
        let formatter = ShortcutFormatter()
        formatter.isKeyCodeLiteral = true
        formatter.usesASCIICapableKeyboardInputSource = true
        formatter.areModifierFlagsLiteral = false

        let label = NSTextField(frame: .zero)
        label.isEditable = false
        label.drawsBackground = false
        label.formatter = formatter
        label.objectValue = Shortcut.default

        XCTAssertEqual(label.stringValue, "⌥⌘A")
    }
}
