//
//  Copyright 2018 ShortcutRecorder Contributors
//  CC BY 4.0
//

import Foundation
import XCTest

import ShortcutRecorder


extension Shortcut {
    class var `default`: Shortcut
    {
        return self.init(code: KeyCode.ansiA,
                         modifierFlags: [.option, .command],
                         characters: "å",
                         charactersIgnoringModifiers: "a")
    }
}


extension TISInputSource {
    var identifier: String {
        return Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(self, kTISPropertyInputSourceID)).takeUnretainedValue() as String
    }

    static func withIdentifier(_ identifier: String) -> TISInputSource? {
        let properties: [CFString: CFTypeRef] = [
            kTISPropertyInputSourceType: kTISTypeKeyboardLayout!,
            kTISPropertyInputSourceID: identifier as CFString
        ]

        let sources = TISCreateInputSourceList(properties as CFDictionary, true)!.takeRetainedValue()
        return CFArrayGetCount(sources) > 0 ? Unmanaged<TISInputSource>.fromOpaque(CFArrayGetValueAtIndex(sources, 0)).takeUnretainedValue() : nil
    }
}


extension NSEvent.ModifierFlags {
    var symbolic: String {
        return SymbolicModifierFlagsTransformer.shared.transformedValue(self.rawValue as NSNumber)!
    }
}


extension XCTestExpectation {
    convenience init(description: String, isInverted: Bool) {
        self.init(description: description)
        self.isInverted = isInverted
    }

    convenience init(description: String, assertForOverFulfill: Bool) {
        self.init(description: description)
        self.assertForOverFulfill = assertForOverFulfill
    }
}
