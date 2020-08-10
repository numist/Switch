//
//  WindowInfo.swift
//  Switch
//
//  Created by Scott Perry on 8/9/20.
//

import Foundation
import CoreGraphics

// swiftlint:disable force_cast

struct WindowInfo {
  fileprivate let infoDict: [String: Any]

  init(_ infoDict: [String: Any]) {
    self.infoDict = infoDict
  }
}

extension WindowInfo {
  static func get(onScreenOnly: Bool = true) -> [WindowInfo] {
    var options = CGWindowListOption.excludeDesktopElements
    if onScreenOnly { options.insert(.optionOnScreenOnly) }
    return (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as! [[String: Any]]).map { WindowInfo($0) }
  }
}

extension WindowInfo {
  /* kCGWindowNumber:
   The value for this key is a CFNumber type (encoded as kCGWindowIDCFNumberType) that contains the window ID.
   The window ID is unique within the current user session.
   */
  var number: CGWindowID {
    return infoDict[kCGWindowNumber as String] as! CGWindowID
  }

  /* kCGWindowStoreType:
   The value for this key is a CFNumber type (encoded as CFNumberType.intType) that contains one of the constants
   defined in CGWindowBackingType.
   */
  var storeType: CGWindowBackingType {
    return CGWindowBackingType(rawValue: infoDict[kCGWindowNumber as String] as! UInt32)!
  }

  /* kCGWindowLayer:
   The value for this key is a CFNumber type (encoded as CFNumberType.intType) that contains the window layer number.
   */
  var layer: CGWindowLevelKey {
    return CGWindowLevelKey.level(for: infoDict[kCGWindowLayer as String] as! CGWindowLevel)
  }

  /* kCGWindowBounds:
   The value for this key is a CFDictionary type that must be decoded to a CGRect type using the
   makeWithDictionaryRepresentation(_:) function. The coordinates of the rectangle are specified in screen space, where
   the origin is in the upper-left corner of the main display.
   */
  var bounds: CGRect {
    return CGRect(dictionaryRepresentation: infoDict[kCGWindowBounds as String] as! CFDictionary)!
  }

  /* kCGWindowSharingState:
   The value for this key is a CFNumber type (encoded as CFNumberType.intType) that contains one of the constants
   defined in CGWindowSharingType.
   */
  var sharingState: CGWindowSharingType {
    return CGWindowSharingType(rawValue: infoDict[kCGWindowSharingState as String] as! UInt32)!
  }

  /* kCGWindowAlpha:
   The value for this key is a CFNumber type (encoded as CFNumberType.floatType) that contains the window’s alpha fade
   level. This number is in the range 0.0 to 1.0, where 0.0 is fully transparent and 1.0 is fully opaque.
   */
  var alpha: Float {
    return infoDict[kCGWindowAlpha as String] as! Float
  }

  /* kCGWindowOwnerPID:
   The value for this key is a CFNumber type (encoded as CFNumberType.intType) that contains the process ID of the
   application that owns the window.
   */
  var ownerPID: pid_t {
    return infoDict[kCGWindowOwnerPID as String] as! Int32
  }

  /* kCGWindowMemoryUsage:
   The value for this key is a CFNumber type (encoded as CFNumberType.longLongType) that contains an estimate of the
   amount of memory (measured in bytes) used by the window and its supporting data structures.
   */
  var memoryUsage: Int64 {
    return infoDict[kCGWindowMemoryUsage as String] as! Int64
  }

  /* kCGWindowOwnerName:
   The key that identifies the name of the application that owns the window. The value for this key is a CFString type.
   */
  var ownerName: String? {
    return infoDict[kCGWindowOwnerName as String] as? String
  }

  /* kCGWindowName:
   The key that identifies the name of the window, as configured in Quartz. The value for this key is a CFString type.
   (Note that few applications set the Quartz window name.)
   */
  var name: String? {
    return infoDict[kCGWindowName as String] as? String
  }

  /* kCGWindowIsOnscreen:
   The key that identifies whether the window is currently onscreen. The value for this key is a CFBoolean type.
   */
  var isOnscreen: Bool? {
    return infoDict[kCGWindowIsOnscreen as String] as? Bool
  }

  /* kCGWindowBackingLocationVideoMemory:
   The key that identifies whether the window’s backing store is located in video memory.
   The value for this key is a CFBoolean type.
   */
  var backingLocationVideoMemory: Bool? {
    return infoDict[kCGWindowBackingLocationVideoMemory as String] as? Bool
  }
}

extension WindowInfo: CustomStringConvertible {
  var description: String {
    var result = "WindowInfo {\n"
    result += "\tnumber: \(number)\n"
    result += "\tstoreType: \(storeType.rawValue)\n"
    result += "\tlayer: \(layer.rawValue)\n"
    result += "\tbounds: \(bounds)\n"
    result += "\tsharingState: \(sharingState.rawValue)\n"
    result += "\talpha: \(alpha)\n"
    result += "\townerPID: \(ownerPID)\n"
    result += "\tmemoryUsage: \(memoryUsage)\n"
    result += "\townerName: \(String(describing: ownerName))\n"
    result += "\tname: \(String(describing: name))\n"
    result += "\tisOnscreen: \(String(describing: isOnscreen))\n"
    result += "\tbackingLocationVideoMemory: \(String(describing: backingLocationVideoMemory))\n"
    return result + "}"
  }
}

// Reverse mapping from CGWindowLevel to CGWindowLevelKey
private extension CGWindowLevelKey {
  // swiftlint:disable:next cyclomatic_complexity
  static func level(for layer: CGWindowLevel) -> CGWindowLevelKey {
    switch layer {
    case kCGBackstopMenuLevel: return .backstopMenu
    case kCGNormalWindowLevel: return .normalWindow
    case kCGFloatingWindowLevel: return .floatingWindow
    case kCGTornOffMenuWindowLevel: return .tornOffMenuWindow
    case kCGModalPanelWindowLevel: return .modalPanelWindow
    case kCGUtilityWindowLevel: return .utilityWindow
    case kCGDockWindowLevel: return .dockWindow
    case kCGMainMenuWindowLevel: return .mainMenuWindow
    case kCGStatusWindowLevel: return .statusWindow
    case kCGPopUpMenuWindowLevel: return .popUpMenuWindow
    case kCGOverlayWindowLevel: return .overlayWindow
    case kCGHelpWindowLevel: return .helpWindow
    case kCGDraggingWindowLevel: return .draggingWindow
    case kCGScreenSaverWindowLevel: return .screenSaverWindow
    case kCGAssistiveTechHighWindowLevel: return .assistiveTechHighWindow
    default: assert(false); return .numberOfWindowLevelKeys
    }
  }
}
