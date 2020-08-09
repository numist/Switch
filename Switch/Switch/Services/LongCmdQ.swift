import Foundation
import Carbon.HIToolbox
import OSLog

class LongCmdQ {
  var timer: Timer? = nil
  var suppress = true

  init() {
    Keyboard.register(.init(.command, .q)) { keyDown in
      if !keyDown {
        self.timer = nil
        if !self.suppress {
          self.suppress = true
          return true
        }
      } else if self.timer == nil {
        os_log(.info, "LongCmdQ: Suppressing ⌘Q!")
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
          guard self.timer == timer else { return }
          os_log(.info, "LongCmdQ: Injecting ⌘Q!")
          self.suppress = false
          CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(kVK_ANSI_Q), keyDown: true)!
            .post(tap: .cgSessionEventTap)
        }
      }
      return !self.suppress
    }
  }
}
