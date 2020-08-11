import Foundation
import CoreGraphics
import Haxcessibility

// Work around the CFString casts and other nonsense by declaring all the keys used in the infoDict passed to WindowInfo
private let cgNumberKey = "kCGWindowNumber"
private let cgStoreTypeKey = "kCGWindowStoreType"
private let cgLayerKey = "kCGWindowLayer"
private let cgBoundsKey = "kCGWindowBounds"
private let cgSharingStateKey = "kCGWindowSharingState"
private let cgAlphaKey = "kCGWindowAlpha"
private let cgOwnerPIDKey = "kCGWindowOwnerPID"
private let cgMemoryUsageKey = "kCGWindowMemoryUsage"
private let cgOwnerNameKey = "kCGWindowOwnerName"
private let cgNameKey = "kCGWindowName"
private let cgIsOnscreenKey = "kCGWindowIsOnscreen"
private let cgBackingLocationVideoMemoryKey = "kCGWindowBackingLocationVideoMemory"
private let cgDisplayIDKey = "NSScreenNumber"
private let nsFrameKey = "NSFrame"
private let isFullscreenKey = "IsFullscreen"
private let canActivateKey = "FriendlyActivationPolicy"

// swiftlint:disable force_cast

struct WindowInfo {
  let id: CGWindowID // swiftlint:disable:this identifier_name
  let storeType: CGWindowBackingType
  let cgFrame: CGRect
  let sharingState: CGWindowSharingType
  let alpha: Float
  let ownerPID: pid_t
  let memoryUsage: Int64

  let ownerName: String?
  let name: String?
  let isOnscreen: Bool?
  let backingLocationVideoMemory: Bool?

  let cgDisplayID: CGDirectDisplayID?
  let nsFrame: NSRect?
  let isFullscreen: Bool?

  let canActivate: Bool

  init(_ infoDict: [String: Any]) {
    // Required Window List Keys
    // https://developer.apple.com/documentation/coregraphics/quartz_window_services/required_window_list_keys
    id = infoDict[cgNumberKey] as! CGWindowID
    storeType = CGWindowBackingType(rawValue: infoDict[cgStoreTypeKey] as! UInt32)!
    assert(infoDict[cgLayerKey] as! CGWindowLevel == kCGNormalWindowLevel)
    cgFrame = CGRect(dictionaryRepresentation: infoDict[cgBoundsKey] as! CFDictionary)!
    sharingState = CGWindowSharingType(rawValue: infoDict[cgSharingStateKey] as! UInt32)!
    alpha = infoDict[cgAlphaKey] as! Float
    ownerPID = infoDict[cgOwnerPIDKey] as! Int32
    memoryUsage = infoDict[cgMemoryUsageKey] as! Int64

    // Optional Window List Keys
    // https://developer.apple.com/documentation/coregraphics/quartz_window_services/optional_window_list_keys
    ownerName = infoDict[cgOwnerNameKey] as? String
    name = infoDict[cgNameKey] as? String
    isOnscreen = infoDict[cgIsOnscreenKey] as? Bool
    backingLocationVideoMemory = infoDict[cgBackingLocationVideoMemoryKey] as? Bool

    // Data from AX
    cgDisplayID = infoDict[cgDisplayIDKey] as? CGDirectDisplayID
    nsFrame = infoDict[nsFrameKey] as? NSRect
    isFullscreen = infoDict[isFullscreenKey] as? Bool

    canActivate = infoDict[canActivateKey] as? Bool ?? false
  }
}

extension WindowInfo {
  static func get(onScreenOnly: Bool = true) -> [WindowInfo] {
    var options = CGWindowListOption.excludeDesktopElements
    if onScreenOnly { options.insert(.optionOnScreenOnly) }
    return (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as! [[String: Any]])
    .filter({ $0[cgLayerKey] as! CGWindowLevel == kCGNormalWindowLevel })
    .map({ infoDict in
      // Try to cons up a HAXWindow for this CGWindow
      let windowID = infoDict[kCGWindowNumber as String] as! CGWindowID
      let processID = infoDict[cgOwnerPIDKey] as! Int32
      guard let haxWindow = HAXApplication(pid: processID)?
        .windows
        .filter({ $0.cgWindowID() == windowID })
        .first
      else {
        return WindowInfo(infoDict)
      }

      // Add extra keys from hax to the info dict
      var haxInfo: [String: Any] = [
        cgDisplayIDKey: haxWindow.screen.deviceDescription[.init(rawValue: "NSScreenNumber")] as! CGDirectDisplayID,
        nsFrameKey: haxWindow.frame,
        isFullscreenKey: haxWindow.isFullscreen,
      ]
      if let title = haxWindow.title {
        haxInfo[cgNameKey] = title
      }

      // Add extra keys from NSRunningApplication to the info dict
      if let runningApp = NSRunningApplication(processIdentifier: processID) {
        haxInfo[canActivateKey] = (runningApp.activationPolicy != .prohibited)
      }

      return WindowInfo(infoDict.merging(haxInfo as [String: Any], uniquingKeysWith: { $1 }))
    })
  }
}

extension WindowInfo: Identifiable, Hashable {}

//extension WindowInfo: CustomStringConvertible {
//  var description: String {
// TODO: description should be directly pastable into a unit test to create a functionally identical WindowInfo instance
// CGRectCreateDictionaryRepresentation
//  }
//}
