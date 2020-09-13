import Carbon
import OSLog

private func eventCallback(
  _: CGEventTapProxy,
  type: CGEventType,
  event: CGEvent,
  userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
  let box = Unmanaged<WeakBox<EventTap>>.fromOpaque(userInfo!).takeUnretainedValue()
  guard let this = box.value else { return Unmanaged.passUnretained(event) }

  if type == .tapDisabledByTimeout {
    os_log(.fault, "tap disabled: tapDisabledByTimeout")
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
      os_log("Re-enabling event tap")
      CGEvent.tapEnable(tap: this.eventTap, enable: true)
    }
    return Unmanaged.passUnretained(event)
  } else if type == .tapDisabledByUserInput {
    return Unmanaged.passUnretained(event)
  }

  if let result = this.callback(type, event) {
    return Unmanaged.passRetained(result)
  } else {
    return nil
  }
}

class EventTap {
  static var eventThread: Thread = {
    let thread = Thread(block: { RunLoop.current.run() })
    thread.name = "net.numist.switch.EventTapCallbackThread"
    thread.qualityOfService = .userInteractive
    thread.threadPriority = 1.0
    thread.start()
    return thread
  }()

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
  private var selfBox: WeakBox<EventTap>!

  init(observing: EventTypes, callback: @escaping (CGEventType, CGEvent) -> CGEvent?) throws {
    self.callback = callback

    selfBox = WeakBox<EventTap>(self)

    guard let tap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(observing.rawValue),
      callback: eventCallback,
      userInfo: Unmanaged.passRetained(selfBox).toOpaque()
    ) else {
      throw EventTap.Error()
    }

    eventTap = tap
    EventTap.eventThread.sync {
      RunLoop.current.add(tap, forMode: .common)
    }
  }

  deinit {
    if let eventTap = eventTap {
      CGEvent.tapEnable(tap: eventTap, enable: false)
      EventTap.eventThread.sync {
        RunLoop.current.remove(self.eventTap, forMode: .common)
      }
    }
    Unmanaged.passUnretained(selfBox).release()
  }
}
