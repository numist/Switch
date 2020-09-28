import Foundation
import Haxcessibility
import Combine

class Switcher {
  private var state: SwitcherState!
  private var releaseTap: EventTap?

  private func setUpReleaseTapIfNeeded() -> Bool {
    assert(Thread.isMainThread)
    guard releaseTap == nil else { return true }

    releaseTap = try? EventTap(observing: .flagsChanged, callback: { [weak self] (_, event) -> CGEvent? in
      if !event.flags.contains(.maskAlternate) {
        DispatchQueue.main.async {
          guard let self = self else { return }
          assert(self.releaseTap != nil)
          self.releaseTap = nil
          Keyboard.deregister(.init(.option, .w))
          Keyboard.deregister(.init(.option, .escape))
          self.state.hotKeyReleased()
        }
      }
      return event
    })

    // Do not engage the state machine if the releaseTap can not be created
    guard releaseTap != nil else { return false }

    // TODO: support for closeWindow hotkey (registered here, deregistered when releaseTap is deactivated)
    Keyboard.register(.init(.option, .w)) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async {
        if let selectedWindow = self.state.selectedWindow?.mainWindow {
          print("Switcher: closing window \(selectedWindow.id) (\(selectedWindow.name ?? "(untitled)")) " +
                    "belonging to \(selectedWindow.ownerPID) (\(selectedWindow.ownerName ?? "(unknown)"))")
          HAXApplication(pid: selectedWindow.ownerPID)?.window(withID: selectedWindow.id)?.close()
        }
      } }
      return false
    }
    Keyboard.register(.init(.option, .escape)) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async {
        self.state.hotKeyReleased(cancel: true)
      } }
      return false
    }

    return true
  }

  init() {
    state = SwitcherState(
      wantsTimerCallback: { [weak self] in self?.startTimer() },
      wantsTimerCancelledCallback: { [weak self] in self?.stopTimer() },
      wantsShowInterfaceCallback: { [weak self] in self?.showInterface() },
      wantsHideInterfaceCallback: { [weak self] in self?.hideInterface() },
      wantsStartWindowListUpdates: { [weak self] in self?.startWindowListPoller() },
      wantsStopWindowListUpdates: { [weak self] in self?.stopWindowListPoller() },
      wantsRaiseCallback: { windowGroup in
        let selectedWindow = windowGroup.mainWindow
        print("Switcher: raising window \(selectedWindow.id) (\(selectedWindow.name ?? "(untitled)")) " +
              "belonging to \(selectedWindow.ownerPID) (\(selectedWindow.ownerName ?? "(unknown)"))")
        HAXApplication(pid: selectedWindow.ownerPID)?.window(withID: selectedWindow.id)?.raise()
      }
    )

    Keyboard.register(.init(.option, .tab)) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async {
        if self.setUpReleaseTapIfNeeded() {
          self.state.incrementSelection()
        }
      } }
      return false
    }
    Keyboard.register(.init([.option, .shift], .tab)) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async {
        if self.setUpReleaseTapIfNeeded() {
          self.state.decrementSelection()
        }
      } }
      return false
    }

//    let iterations = 1000
//    let start = Date()
//    for _ in 0..<iterations {
//      _ = WindowInfoGroup.list(from: WindowInfo.get())
//    }
//    print("Switcher: Time to fetch windows: \(-start.timeIntervalSinceNow / Double(iterations))")
//    // It's about 20ms on average, and it varies enough to absolutely require async polling
  }

  deinit {
    Keyboard.deregister(.init(.option, .tab))
    Keyboard.deregister(.init([.option, .shift], .tab))
  }

  // MARK: - Timer management

  private var timer: Timer?

  private func startTimer() {
    assert(Thread.isMainThread)
    assert(self.timer == nil)

    self.timer = Timer.scheduledTimer(
      withTimeInterval: 0.2,
      repeats: false,
      block: { [weak self] timer in
        guard let self = self else { return }
        guard self.timer == timer else { return }
        self.state.timerFired()
        self.timer = nil
      }
    )
  }

  private func stopTimer() {
    assert(Thread.isMainThread)
    assert(self.timer != nil)

    timer?.invalidate()
    timer = nil
  }

  // MARK: - Interface management

  private var window: SwitcherWindow?

  private func showInterface() {
    assert(Thread.isMainThread)
    print("Switcher: show interface")
    window = SwitcherWindow(displaying: state, for: nil)
  }

  private func hideInterface() {
    assert(Thread.isMainThread)
    print("Switcher: hide interface")
    window = nil
  }

  // MARK: - Window list polling

  private var windowListCancellable: AnyCancellable?

  private func startWindowListPoller() {
    assert(Thread.isMainThread)
    windowListCancellable = WindowInfoGroupListPublisher().removeDuplicates().sink { [weak self] list in
      assert(Thread.isMainThread)
      guard let self = self, self.windowListCancellable != nil else { return }
      print("Switcher: windows: \(list)")
      self.state.update(windows: list)
    }
  }

  private func stopWindowListPoller() {
    assert(Thread.isMainThread)
    windowListCancellable = nil
  }
}
