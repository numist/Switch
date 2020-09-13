import OSLog
import Combine

enum Service {
  case axPoller
  case longCmdQ
  case pasteboardHistory
  case switcher

  fileprivate func implementation() -> Any {
    switch self {
    case .longCmdQ: return LongCmdQ()
    case .pasteboardHistory: return PasteboardHistory()
    case .switcher: return Switcher()
    case .axPoller:
      return Timer.publish(every: 0.25, on: .main, in: .common)
        .autoconnect()
        .map({ _ in
          AXIsProcessTrustedWithOptions(nil)
        })
        .removeDuplicates()
        .filter({ isTrusted in
          isTrusted
        })
        .sink { _ in
          os_log(.info, "AX now trusts us, time to relaunch!")
          if !amIBeingDebugged() {
            // TODO(numist): time to relaunch!
          }
        }
    }
  }
}

class ServiceManager {
  private static var runningServices = [Service: Any]()

  static func start(_ service: Service) {
    assert(runningServices[service] == nil)
    if runningServices[service] == nil {
      runningServices[service] = service.implementation()
    } else {
      os_log(.error, "Service already started")
    }
  }

  static func stop(_ service: Service) {
    assert(runningServices[service] != nil)
    if runningServices[service] != nil {
      runningServices.removeValue(forKey: service)
    } else {
      os_log(.error, "Service never started")
    }
  }
}
