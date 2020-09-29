import Cocoa

extension NSScreen {
  var screenNumber: CGDirectDisplayID {
    // swiftlint:disable force_cast
    return self.deviceDescription[.init(rawValue: "NSScreenNumber")] as! CGDirectDisplayID
    // swiftlint:enable force_cast
  }
}
