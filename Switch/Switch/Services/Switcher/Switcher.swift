import Foundation
import Haxcessibility

class Switcher {
  private var state: SwitcherState!
  private var releaseTap: EventTap?
  private var window: SwitcherWindow?

  private func setUpReleaseTapIfNeeded() -> Bool {
    assert(Thread.isMainThread)
    guard releaseTap == nil else { return true }

    // TODO: support for closeWindow hotkey (registered here, deregistered when releaseTap is deactivated)

    releaseTap = try? EventTap(observing: .flagsChanged, callback: { [weak self] (_, event) -> CGEvent? in
      if !event.flags.contains(.maskAlternate) {
        DispatchQueue.main.async {
          guard let self = self else { return }
          assert(self.releaseTap != nil)
          self.releaseTap = nil
          self.state.hotKeyReleased()
        }
      }
      return event
    })

    // Do not engage the state machine if the releaseTap can not be created
    return releaseTap != nil
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
        let haxApp = HAXApplication(pid: selectedWindow.ownerPID)
        let haxWindow = haxApp?.window(withID: selectedWindow.id)
        haxWindow?.raise()
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

  // MARK: -
  // This section implements the state machine's callbacks

  // MARK: Timer management
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

  // MARK: Interface management

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

  // MARK: Window list polling

  private func startWindowListPoller() {
    assert(Thread.isMainThread)

    // TODO: turn this into a more reliable polling situation
    DispatchQueue.global(qos: .userInitiated).async {
      let windowList = WindowInfoGroup.list(from: WindowInfo.get())
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        self.state.update(windows: windowList)
        print("Switcher: Updated window list (\(windowList.count) windows: \(windowList.map { $0.mainWindow.name ?? "" }))")
      }
    }
  }

  private func stopWindowListPoller() {
    assert(Thread.isMainThread)
  }
}
