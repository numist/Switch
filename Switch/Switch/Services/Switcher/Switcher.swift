import Foundation

class Switcher {
  private var state = SwitcherState()

  private var releaseTap: EventTap?
  private func hotKeyDown(incrementing: Bool) {
    assert(Thread.isMainThread)

    if releaseTap == nil {
      // swiftlint:disable:next force_try
      releaseTap = try! EventTap(observing: .flagsChanged, callback: { [weak self] (_, event) -> CGEvent? in
        guard let self = self else { return event }

        if !event.flags.contains(.maskAlternate) {
          DispatchQueue.main.async {
            assert(self.releaseTap != nil)
            self.releaseTap = nil
            print("switcher: dismissed (selection: \(String(describing: self.state.selection)))")
          }
          return nil
        }
        return event
      })

      state = SwitcherState()
      print("switcher: active")
    }

    if incrementing {
      state.incrementSelection()
      print("switcher: increment")
    } else {
      state.decrementSelection()
      print("switcher: decrement")
    }
  }

  init() {
    Keyboard.register(.init(.option, .tab)) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async { self.hotKeyDown(incrementing: true) } }
      return false
    }
    Keyboard.register(.init([.option, .shift], .tab)) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async { self.hotKeyDown(incrementing: false) } }
      return false
    }
  }
}
