import Foundation
import CoreGraphics

struct WindowInfoGroup: Hashable {
  let mainWindow: WindowInfo
  let windows: [WindowInfo]
}

extension WindowInfoGroup: Identifiable {
  // swiftlint:disable:next identifier_name
  var id: CGWindowID { return mainWindow.id }
}

extension WindowInfoGroup {
  var cgFrame: CGRect {
    var minPoint = mainWindow.cgFrame.origin
    var maxPoint = minPoint
    for cgFrame in windows.map({ $0.cgFrame }) {
      minPoint.x = min(minPoint.x, cgFrame.origin.x)
      minPoint.y = min(minPoint.y, cgFrame.origin.y)
      maxPoint.x = max(maxPoint.x, cgFrame.origin.x + cgFrame.size.width)
      maxPoint.y = max(maxPoint.y, cgFrame.origin.y + cgFrame.size.height)
    }
    return CGRect(
      origin: minPoint,
      size: CGSize(width: maxPoint.x - minPoint.x, height: maxPoint.y - minPoint.y)
    )
  }

  var nsFrame: NSRect? {
    guard let mainFrame = mainWindow.nsFrame else { return nil }
    var minPoint = mainFrame.origin
    var maxPoint = minPoint
    for nsFrame in windows.map({ $0.nsFrame }) {
      guard let nsFrame = nsFrame else { return nil }
      minPoint.x = min(minPoint.x, nsFrame.origin.x)
      minPoint.y = min(minPoint.y, nsFrame.origin.y)
      maxPoint.x = max(maxPoint.x, nsFrame.origin.x + nsFrame.size.width)
      maxPoint.y = max(maxPoint.y, nsFrame.origin.y + nsFrame.size.height)
    }
    return NSRect(
      origin: minPoint,
      size: NSSize(width: maxPoint.x - minPoint.x, height: maxPoint.y - minPoint.y)
    )
  }
}

extension WindowInfoGroup {
  // TODO(numist): this is gonna get more sophisticated but let's get off the ground first
  /* Heuristics:
   *   * window grouping is not accurate when title is not set
   *   * group non-activatable windows with nearest mainwindow candidate
   *   * …maybe just recreate/port tests from old source
   */
  static func list(from infos: [WindowInfo]) -> [WindowInfoGroup] {
    return infos
      .filter({ $0.alpha != 0.0 && $0.canActivate && $0.name?.count ?? 0 > 0 })
      .map({ WindowInfoGroup(mainWindow: $0, windows: [$0]) })
  }
}
