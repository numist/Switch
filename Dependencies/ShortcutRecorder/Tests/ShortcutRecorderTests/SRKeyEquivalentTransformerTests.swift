//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import XCTest

import ShortcutRecorder


class SRKeyEquivalentTransformerTests: XCTestCase {
    func testTransformFromShortcut() {
        let cmd_a = Shortcut(keyEquivalent: "⌘A")!
        let cmd_a_ke = KeyEquivalentTransformer.shared.transformedValue(cmd_a)!
        XCTAssertEqual(cmd_a_ke, "a")
    }
}
