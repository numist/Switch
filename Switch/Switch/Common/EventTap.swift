import Carbon
import OSLog

private func eventCallback(
  _: CGEventTapProxy,
  type: CGEventType,
  event: CGEvent,
  userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  let this = Unmanaged<EventTap>.fromOpaque(userInfo!).takeUnretainedValue()

  if type == .tapDisabledByTimeout {
    os_log(.fault, "tap disabled: tapDisabledByTimeout")
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      os_log("Re-enabling event tap")
      CGEvent.tapEnable(tap: this.eventTap, enable: true)
    }
    return Unmanaged.passRetained(event)
  } else if type == .tapDisabledByUserInput {
    os_log(.fault, "tap disabled: tapDisabledByUserInput")
    return Unmanaged.passRetained(event)
  }

  if let result = this.callback(type, event) {
    return Unmanaged.passRetained(result)
  } else {
    return nil
  }
}

class EventTap {
  struct Error: Swift.Error {}
  struct EventTypes: OptionSet {
    let rawValue: Int64

    static let null = EventTypes(rawValue: 1 << CGEventType.null.rawValue)
    static let leftMouseDown = EventTypes(rawValue: 1 << CGEventType.leftMouseDown.rawValue)
    static let leftMouseUp = EventTypes(rawValue: 1 << CGEventType.leftMouseUp.rawValue)
    static let rightMouseDown = EventTypes(rawValue: 1 << CGEventType.rightMouseDown.rawValue)
    static let rightMouseUp = EventTypes(rawValue: 1 << CGEventType.rightMouseUp.rawValue)
    static let mouseMoved = EventTypes(rawValue: 1 << CGEventType.mouseMoved.rawValue)
    static let leftMouseDragged = EventTypes(rawValue: 1 << CGEventType.leftMouseDragged.rawValue)
    static let rightMouseDragged = EventTypes(rawValue: 1 << CGEventType.rightMouseDragged.rawValue)
    static let keyDown = EventTypes(rawValue: 1 << CGEventType.keyDown.rawValue)
    static let keyUp = EventTypes(rawValue: 1 << CGEventType.keyUp.rawValue)
    static let flagsChanged = EventTypes(rawValue: 1 << CGEventType.flagsChanged.rawValue)
    static let scrollWheel = EventTypes(rawValue: 1 << CGEventType.scrollWheel.rawValue)
    static let tabletPointer = EventTypes(rawValue: 1 << CGEventType.tabletPointer.rawValue)
    static let tabletProximity = EventTypes(rawValue: 1 << CGEventType.tabletProximity.rawValue)
    static let otherMouseDown = EventTypes(rawValue: 1 << CGEventType.otherMouseDown.rawValue)
    static let otherMouseUp = EventTypes(rawValue: 1 << CGEventType.otherMouseUp.rawValue)
    static let otherMouseDragged = EventTypes(rawValue: 1 << CGEventType.otherMouseDragged.rawValue)
  }

  fileprivate let callback: (CGEventType, CGEvent) -> CGEvent?
  fileprivate var eventTap: CFMachPort!
  private var eventThread: Thread!

  init(observing: EventTypes, callback: @escaping (CGEventType, CGEvent) -> CGEvent?) throws {
    self.callback = callback

    guard let tap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(observing.rawValue),
      callback: eventCallback,
      userInfo: Unmanaged.passRetained(self).toOpaque()
    ) else {
      throw EventTap.Error()
    }
    eventTap = tap

    let eventThread = Thread(block: {
      let runLoop = RunLoop.current
      runLoop.add(tap, forMode: .common)
      runLoop.run()
    })
    eventThread.name = "EventTap event callback thread"
    eventThread.qualityOfService = .userInteractive
    eventThread.threadPriority = 1.0
    eventThread.start()
  }

  deinit {
    eventThread.sync {
      CGEvent.tapEnable(tap: self.eventTap, enable: false)
      RunLoop.current.remove(self.eventTap, forMode: .common)
    }
    eventThread.cancel()
  }
}
