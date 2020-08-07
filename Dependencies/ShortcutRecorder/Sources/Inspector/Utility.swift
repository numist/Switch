//
//  Copyright 2019 ShortcutRecorder Contributors
//  CC BY 4.0
//

import Cocoa
import Foundation

import ShortcutRecorder




class MutableDictionaryTransformer: ValueTransformer {
    public override class func allowsReverseTransformation() -> Bool {
        return true
    }

    public override class func transformedValueClass() -> AnyClass {
        return NSMutableDictionary.self
    }

    public override func transformedValue(_ value: Any?) -> Any? {
        return value != nil ? NSMutableDictionary(dictionary: value as! Dictionary) : NSMutableDictionary()
    }

    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        return value
    }
}


extension NSValueTransformerName {
    static let mutableDictionaryTransformerName = NSValueTransformerName(rawValue: "MutableDictionaryTransformer")
}
