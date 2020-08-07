//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest
import ShortcutRecorder


class SRKeyBindingTransformerTests: XCTestCase {
    func testTransform() {
        let cmd_a = Shortcut(keyEquivalent: "⌘A")
        let shift_cmd_a = Shortcut(keyEquivalent: "⇧⌘A")

        XCTAssertEqual(KeyBindingTransformer.shared.transformedValue("@a"), cmd_a)
        XCTAssertEqual(KeyBindingTransformer.shared.transformedValue("@A"), shift_cmd_a)
        XCTAssertEqual(KeyBindingTransformer.shared.transformedValue("$@a"), shift_cmd_a)
        XCTAssertEqual(KeyBindingTransformer.shared.transformedValue("$@A"), shift_cmd_a)
    }

    func testReverseTransform() {
        let cmd_a = Shortcut(keyEquivalent: "⌘A")
        let shift_cmd_a = Shortcut(keyEquivalent: "⇧⌘A")
        XCTAssertEqual(KeyBindingTransformer.shared.reverseTransformedValue(cmd_a), "@a")
        XCTAssertEqual(KeyBindingTransformer.shared.reverseTransformedValue(shift_cmd_a), "$@a")
    }
}
