import Foundation
import CoreGraphics
import Haxcessibility

// Work around the CFString casts and other nonsense by declaring all the keys used in the infoDict passed to WindowInfo
enum WindowInfoDictionaryKey: String {
  // https://developer.apple.com/documentation/coregraphics/quartz_window_services/required_window_list_keys
  case cgNumber = "kCGWindowNumber"
//  case cgStoreType = "kCGWindowStoreType"
  case cgLayer = "kCGWindowLayer"
  case cgBounds = "kCGWindowBounds"
//  case cgSharingState = "kCGWindowSharingState"
  case cgAlpha = "kCGWindowAlpha"
  case cgOwnerPID = "kCGWindowOwnerPID"
//  case cgMemoryUsage = "kCGWindowMemoryUsage"

  // https://developer.apple.com/documentation/coregraphics/quartz_window_services/optional_window_list_keys
  case cgOwnerName = "kCGWindowOwnerName"
  case cgName = "kCGWindowName"
  case cgIsOnscreen = "kCGWindowIsOnscreen"
//  case cgBackingLocationVideoMemory = "kCGWindowBackingLocationVideoMemory"

  // https://developer.apple.com/documentation/appkit/nsscreen/1388360-devicedescription
  case cgDisplayID = "NSScreenNumber"

  // Custom keys filled by AX
  case nsFrame = "NSFrame"
  case isFullscreen = "IsFullscreen"

  // Custom keys filled by NSRunningApplication
  case canActivate = "FriendlyActivationPolicy"
  case isAppActive = "AppIsActive"
  case ownerBundleID = "BundleID"
}

// swiftlint:disable force_cast

struct WindowInfo {
  let id: CGWindowID // swiftlint:disable:this identifier_name
  let cgFrame: CGRect
  let alpha: Float
  let ownerPID: pid_t

  let ownerName: String?
  let name: String?
  let isOnScreen: Bool?

  let cgDisplayID: CGDirectDisplayID?
  let nsFrame: NSRect?
  let isFullscreen: Bool?

  let canActivate: Bool
  let isAppActive: Bool
  let ownerBundleID: String?

  init(_ infoDict: [WindowInfoDictionaryKey: Any]) {
    id = infoDict[.cgNumber] as! CGWindowID
    assert(infoDict[.cgLayer] as! CGWindowLevel == kCGNormalWindowLevel)
    cgFrame = CGRect(dictionaryRepresentation: infoDict[.cgBounds] as! CFDictionary)!
    alpha = infoDict[.cgAlpha] as! Float
    ownerPID = infoDict[.cgOwnerPID] as! Int32

    ownerName = infoDict[.cgOwnerName] as? String
    name = infoDict[.cgName] as? String
    isOnScreen = infoDict[.cgIsOnscreen] as? Bool

    cgDisplayID = infoDict[.cgDisplayID] as? CGDirectDisplayID
    nsFrame = infoDict[.nsFrame] as? NSRect
    isFullscreen = infoDict[.isFullscreen] as? Bool

    canActivate = infoDict[.canActivate] as? Bool ?? false
    /* Usually true for first window in list, usually false for subsequents. This value should never be missing for
     * main windows, but the default value is chosen to provide the best state machine behaviour (and least crashing)
     * if it's ever missing.
     */
    isAppActive = infoDict[.isAppActive] as? Bool ?? true
    ownerBundleID = infoDict[.ownerBundleID] as? String
  }
}

extension WindowInfo {
  static func get(onScreenOnly: Bool = true) -> [WindowInfo] {
    var options = CGWindowListOption.excludeDesktopElements
    if onScreenOnly { options.insert(.optionOnScreenOnly) }
    return (CGWindowListCopyWindowInfo(options, kCGNullWindowID) as! [[String: Any]])
    .filter({ $0[WindowInfoDictionaryKey.cgLayer.rawValue] as! CGWindowLevel == kCGNormalWindowLevel })
    .map({ Dictionary(uniqueKeysWithValues:
      $0
      .filter({ (key, _) in WindowInfoDictionaryKey(rawValue: key) != nil })
      .map({ (key, value) in (WindowInfoDictionaryKey(rawValue: key)!, value) }))
    })
    .map({ infoDict in
      // Try to cons up a HAXWindow for this CGWindow
      let windowID = infoDict[.cgNumber] as! CGWindowID
      let processID = infoDict[.cgOwnerPID] as! Int32

      // Add extra keys from NSRunningApplication to the info dict
      var additionalInfo = [WindowInfoDictionaryKey: Any]()
      if let runningApp = NSRunningApplication(processIdentifier: processID) {
        additionalInfo[.canActivate] = (runningApp.activationPolicy != .prohibited)
        additionalInfo[.isAppActive] = runningApp.isActive
        additionalInfo[.ownerBundleID] = runningApp.bundleIdentifier
      }

      guard let haxWindow = HAXApplication(pid: processID)?
        .windows
        .filter({ $0.cgWindowID() == windowID })
        .first
      else {
        return WindowInfo(infoDict)
      }

      // Add extra keys from hax to the info dict
      additionalInfo[.cgDisplayID] =
        haxWindow.screen.deviceDescription[.init(rawValue: "NSScreenNumber")] as! CGDirectDisplayID
      additionalInfo[.nsFrame] = haxWindow.frame
      additionalInfo[.isFullscreen] = haxWindow.isFullscreen
      if let title = haxWindow.title {
        additionalInfo[.cgName] = title
      }

      return WindowInfo(infoDict.merging(additionalInfo, uniquingKeysWith: { $1 }))
    })
  }
}

extension WindowInfo: Identifiable, Hashable {}

extension WindowInfo: CustomStringConvertible {
  // swiftlint:disable line_length
  var description: String {
    var result = """
    WindowInfo([
      .cgNumber: UInt32(\(id)),
      .cgLayer: Int32(0),
      .cgBounds: CGRect(x: \(cgFrame.origin.x), y: \(cgFrame.origin.y), width: \(cgFrame.size.width), height: \(cgFrame.size.height)).dictionaryRepresentation,
      .cgAlpha: Float(\(alpha)),
      .cgOwnerPID: Int32(\(ownerPID)),

    """
    if let ownerName = ownerName { result += "  .cgOwnerName: \"\(ownerName)\",\n" }
    if let name = name { result += "  .cgName: \"\(name)\",\n" }
    if let isOnScreen = isOnScreen { result += "  .cgIsOnscreen: \(isOnScreen),\n" }
    if let cgDisplayID = cgDisplayID { result += "  .cgDisplayID: UInt32(\(cgDisplayID)),\n" }
    if let frm = nsFrame {
      result += "  .nsFrame: NSRect(x: \(frm.origin.x), y: \(frm.origin.y), width: \(frm.size.width), height: \(frm.size.height)),\n"
    }
    if let isFullscreen = isFullscreen { result += "  .isFullscreen: \(isFullscreen),\n" }
    if let bundleID = ownerBundleID { result += "  .ownerBundleID: \"\(bundleID)\",\n" }
    return result + """
      .canActivate: \(canActivate),
      .isAppActive: \(isAppActive),
    ])
    """
  }
  // swiftlint:enable line_length
}
