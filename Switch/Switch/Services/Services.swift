import OSLog
import Combine

/// Top level app services manager
///
/// Moves top level app functionality management out of the app delegate
final class Services {
  enum Service: CaseIterable {
    case longCmdQ
    case pasteboardHistory
    case statusItem
    case switcher
  }

  // Service starting takes advantage of the fact that static members are initialized lazily
  private static let longCmdQ = LongCmdQ()
  private static let pasteboardHistory = PasteboardHistory()
  private static let statusItem = StatusItem()
  private static let switcher = Switcher()

  /// Start an app service
  ///
  /// Once a service has been started it cannot be stopped
  static func start(_ service: Service? = nil) {
    guard let service = service else {
      for service in Service.allCases {
        start(service)
      }
      return
    }

    switch service {
    case .longCmdQ: _ = longCmdQ
    case .pasteboardHistory: _ = pasteboardHistory
    case .statusItem: _ = statusItem
    case .switcher: _ = switcher
    }
  }
}
