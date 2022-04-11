import Foundation
import Carbon.HIToolbox
import OSLog
import Haxcessibility

// TODO(numist): UI
// TODO(numist): make pretty progress bar
// TODO(numist): enable/disable based on pref
// TODO(numist): staticify, ServiceProtocol for enable/disable? gotta think of how prefs gonna drive behaviour here

class LongCmdQ {
  var timer: Timer?
  var injected = false
  var timerFired = false

  init() {
    Keyboard.register(.init(.command, .q)) { keyDown in
      if !keyDown {
        self.timer = nil
        if self.timerFired {
          let result = self.injected
          self.injected = false
          self.timerFired = false
          return result // allow keyup to pass to match injected keydown event
        } else {
          print("LongCmdQ: ⌘Q cancelled")
        }
      } else {
        if self.timer == nil {
          self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { timer in
            guard self.timer == timer else { return }
            print("LongCmdQ: Timer fired")
            self.timerFired = true
          }
          let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "<unavailable>"
          print("LongCmdQ: Suppressing ⌘Q on \(appName) (timer started)")
        } else if self.timerFired && !self.injected {
          self.injected = true
          return true
        }
      }
      return false // suppress event
    }
  }
}
