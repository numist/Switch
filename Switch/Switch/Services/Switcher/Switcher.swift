import Foundation
import Haxcessibility
import Combine

class Switcher {
  let forwardHotKey = Keyboard.HotKey(.option, .tab)
  let reverseHotKey = Keyboard.HotKey([.option, .shift], .tab)
  let closeHotKey = Keyboard.HotKey(.option, .w)
  let cancelHotKey = Keyboard.HotKey(.option, .escape)

  private var commonModifiers: Keyboard.Modifiers {
    forwardHotKey.modifiers
      .intersection(reverseHotKey.modifiers)
      .intersection(closeHotKey.modifiers)
      .intersection(cancelHotKey.modifiers)
  }

  private var state: SwitcherState!
  private var releaseTap: EventTap?

  private func setUpReleaseTapIfNeeded() -> Bool {
    assert(Thread.isMainThread)
    guard releaseTap == nil else { return true }

    releaseTap = try? EventTap(observing: .flagsChanged, callback: { [weak self] (_, event) -> CGEvent? in
      guard let modifiers = self?.commonModifiers else { return event }
      if event.flags.isEmpty || !Keyboard.Modifiers(event.flags).isSuperset(of: modifiers) {
        DispatchQueue.main.async {
          guard let self = self else { return }
          assert(self.releaseTap != nil)
          self.state.hotKeyReleased()
          self.cleanUp()
        }
      }
      return event
    })

    // Do not engage the state machine if the releaseTap can not be created
    guard releaseTap != nil else { return false }

    // TODO: support for closeWindow hotkey (registered here, deregistered when releaseTap is deactivated)
    Keyboard.register(closeHotKey) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async {
        if let selectedWindow = self.state.selectedWindow {
          print("Switcher: closing \(selectedWindow)")
          HAXApplication(pid: selectedWindow.ownerPID)?.window(withID: selectedWindow.id)?.close()
        }
      } }
      return false
    }
    Keyboard.register(cancelHotKey) { [weak self] keyDown -> Bool in
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
        print("Switcher: raising \(windowGroup)")
        HAXApplication(pid: windowGroup.ownerPID)?.window(withID: windowGroup.id)?.raise()
      }
    )

    Keyboard.register(forwardHotKey) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async {
        if self.setUpReleaseTapIfNeeded() {
          self.state.incrementSelection()
        }
      } }
      return false
    }
    Keyboard.register(reverseHotKey) { [weak self] keyDown -> Bool in
      guard let self = self else { return true }
      if keyDown { DispatchQueue.main.async {
        if self.setUpReleaseTapIfNeeded() {
          self.state.decrementSelection()
        }
      } }
      return false
    }
  }

  private func cleanUp() {
    assert(Thread.isMainThread)
    if releaseTap != nil {
      Keyboard.deregister(closeHotKey)
      Keyboard.deregister(cancelHotKey)
      releaseTap = nil
    }
  }

  deinit {
    cleanUp()
    Keyboard.deregister(forwardHotKey)
    Keyboard.deregister(reverseHotKey)
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
    window = SwitcherWindow(displaying: state, for: nil)
  }

  private func hideInterface() {
    assert(Thread.isMainThread)
    window = nil
  }

  // MARK: - Window list polling

  private var windowListCancellable: AnyCancellable?

  private func startWindowListPoller() {
    assert(Thread.isMainThread)
    windowListCancellable = WindowInfoGroupListPublisher().removeDuplicates().sink { [weak self] list in
      assert(Thread.isMainThread)
      guard let self = self, self.windowListCancellable != nil else { return }
      self.state.update(windows: list)
    }
  }

  private func stopWindowListPoller() {
    assert(Thread.isMainThread)
    windowListCancellable = nil
  }
}
