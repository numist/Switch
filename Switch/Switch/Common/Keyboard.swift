import Carbon
import OSLog

/// Keyboard interface primarily for hotkey/callbacks
class Keyboard {
  /// Try to establish the Keyboard event tap that powers hotkeys
  static func enableHotKeys() throws {
    assert(eventTap == nil)
    eventTap = try EventTap(observing: [.keyDown, .keyUp], callback: Keyboard.keyboardEvent)
  }

  /// Remove the event tap powering hotkeys
  static func disableHotKeys() {
    assert(eventTap != nil)
    eventTap = nil
  }

  /// Register a callback to be invoked when `hotkey` is pressed or released
  static func register(_ hotkey: HotKey, _ closure: @escaping (Bool) -> Bool) {
    assert(eventTap != nil)
    os_unfair_lock_lock(&lock)
    callbacks[hotkey] = closure
    os_unfair_lock_unlock(&lock)
  }

  /// Remove the registered callback for `hotkey`
  static func deregister(_ hotkey: HotKey) {
    assert(eventTap != nil)
    os_unfair_lock_lock(&lock)
    callbacks.removeValue(forKey: hotkey)
    os_unfair_lock_unlock(&lock)
  }

  // MARK: Internals

  // Would have used CGSSetGlobalHotKeyOperatingMode & co.,
  // but then I wouldn't be able to do shenanigans with ⌘Q and ⌘⇥
  private static var eventTap: EventTap?

  private static var lock = os_unfair_lock_s()
  private static var callbacks = [HotKey: (Bool)->Bool]()

  private static func keyboardEvent(_ type: CGEventType, _ event: CGEvent) -> CGEvent? {
    precondition(type == .keyUp || type == .keyDown)

    let hotKey = HotKey(event)

    os_unfair_lock_lock(&lock)
    let callback = callbacks[hotKey]
    os_unfair_lock_unlock(&lock)

    return (callback?(type == .keyDown) ?? true) ? event : nil
  }
}
