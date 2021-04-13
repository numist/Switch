import Defaults
import Foundation

extension Defaults.Keys {
  static let firstLaunch = Key<Bool>("firstLaunch", default: true)
  static let multimonInterface = Key<Bool>("multimonInterface", default: true)
  static let multimonGroupByMonitor = Key<Bool>("multimonGroupByMonitor", default: true)
  static let showStatusItem = Key<Bool>("showStatusItem", default: true)

  // This would be better as a URL, but previous shipping versions of Switch already used a string for this default
  static let SUFeedURL = Key<String>(
    "SUFeedURL",
    default: Bundle.main.object(forInfoDictionaryKey: "SUFeedURL")! as! String // swiftlint:disable:this force_cast
  )
}
