//
//  WindowInfo.swift
//  Switch
//
//  Created by Scott Perry on 8/9/20.
//

import Foundation
import CoreGraphics
import Haxcessibility

// swiftlint:disable force_cast

struct WindowInfo {
  // Required Window List Keys
  // https://developer.apple.com/documentation/coregraphics/quartz_window_services/required_window_list_keys
  let number: CGWindowID
  let storeType: CGWindowBackingType
  let layer: CGWindowLevelKey
  let bounds: CGRect
  let sharingState: CGWindowSharingType
  let alpha: Float
  let ownerPID: pid_t
  let memoryUsage: Int64

  // Optional Window List Keys
  // https://developer.apple.com/documentation/coregraphics/quartz_window_services/optional_window_list_keys
  let ownerName: String?
  let name: String?
  let isOnscreen: Bool?
  let backingLocationVideoMemory: Bool?

  init(_ infoDict: [String: Any]) {
    number = infoDict[kCGWindowNumber as String] as! CGWindowID
    storeType = CGWindowBackingType(rawValue: infoDict[kCGWindowNumber as String] as! UInt32)!
    layer = CGWindowLevelKey.level(for: infoDict[kCGWindowLayer as String] as! CGWindowLevel)
    bounds = CGRect(dictionaryRepresentation: infoDict[kCGWindowBounds as String] as! CFDictionary)!
    sharingState = CGWindowSharingType(rawValue: infoDict[kCGWindowSharingState as String] as! UInt32)!
    alpha = infoDict[kCGWindowAlpha as String] as! Float
    ownerPID = infoDict[kCGWindowOwnerPID as String] as! Int32
    memoryUsage = infoDict[kCGWindowMemoryUsage as String] as! Int64
    ownerName = infoDict[kCGWindowOwnerName as String] as? String
    name = infoDict[kCGWindowName as String] as? String
    isOnscreen = infoDict[kCGWindowIsOnscreen as String] as? Bool
    backingLocationVideoMemory = infoDict[kCGWindowBackingLocationVideoMemory as String] as? Bool
  }
}

extension WindowInfo {
  static func get(onScreenOnly: Bool = true) -> [WindowInfo] {
    var options = CGWindowListOption.excludeDesktopElements
    if onScreenOnly { options.insert(.optionOnScreenOnly) }
    return (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as! [[String: Any]]).map({ infoDict in
      // TODO: try CGSCopyWindowProperty first to avoid AX per https://stackoverflow.com/a/15237348
      // My bet is it's the same as kCGWindowName
      if infoDict[kCGWindowName as String] == nil {
        // Try to get the window name from AX instead
        let number = infoDict[kCGWindowNumber as String] as! CGWindowID
        let ownerPID = infoDict[kCGWindowOwnerPID as String] as! Int32
        let haxWindow = HAXApplication(pid: ownerPID)?.windows.filter({ $0.cgWindowID() == number }).first
        if let haxName = haxWindow?.title {
          return WindowInfo(infoDict.merging([(kCGWindowName as String): haxName], uniquingKeysWith: { $1 }))
        }
      }
      return WindowInfo(infoDict)
    })
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
