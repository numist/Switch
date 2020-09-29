import Defaults
import Foundation

extension Defaults.Keys {
  static let firstLaunch = Key<Bool>("firstLaunch", default: false)
  static let multimonInterface = Key<Bool>("multimonInterface", default: true)
  static let multimonGroupByMonitor = Key<Bool>("multimonGroupByMonitor", default: true)
  static let showStatusItem = Key<Bool>("showStatusItem", default: true)
  static let SUFeedURL = Key<String>(
    "SUFeedURL",
    default: Bundle.main.infoDictionary!["SUFeedURL"]! as! String // swiftlint:disable:this force_cast
  )
}
