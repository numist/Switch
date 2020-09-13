class SwitcherState {
  // MARK: - Ins/outs

  let wantsTimerCallback: () -> Void
  let wantsTimerCancelledCallback: () -> Void
  let wantsShowInterfaceCallback: () -> Void
  let wantsHideInterfaceCallback: () -> Void
  let wantsStartWindowListUpdates: () -> Void
  let wantsStopWindowListUpdates: () -> Void
  let wantsRaiseCallback: (WindowInfoGroup) -> Void

  init(
    wantsTimerCallback: @escaping () -> Void = {},
    wantsTimerCancelledCallback: @escaping () -> Void = {},
    wantsShowInterfaceCallback: @escaping () -> Void = {},
    wantsHideInterfaceCallback: @escaping () -> Void = {},
    wantsStartWindowListUpdates: @escaping () -> Void = {},
    wantsStopWindowListUpdates: @escaping () -> Void = {},
    wantsRaiseCallback: @escaping (WindowInfoGroup) -> Void = {_ in}
  ) {
    self.wantsTimerCallback = wantsTimerCallback
    self.wantsTimerCancelledCallback = wantsTimerCancelledCallback
    self.wantsShowInterfaceCallback = wantsShowInterfaceCallback
    self.wantsHideInterfaceCallback = wantsHideInterfaceCallback
    self.wantsStartWindowListUpdates = wantsStartWindowListUpdates
    self.wantsStopWindowListUpdates = wantsStopWindowListUpdates
    self.wantsRaiseCallback = wantsRaiseCallback
  }

  func timerFired() {
    assert(_wantsTimer)
    assert(!_timerFired)
    _timerFired = true
    _wantsTimer = false
    showInterfaceIfReady()
  }

  private var _active = false
  func hotKeyReleased() {
    guard _active else { return }

    // If hotkey is released before presenting interface, don't bother
    if _wantsTimer {
      wantsTimerCancelled()
    }
    _wantsRaiseOnWindowUpdate = true
    raiseIfReady()
  }

  func incrementSelection(by amt: Int = 1) {
    guard !_wantsRaiseOnWindowUpdate else { return }

    _active = true
    if !_wantsTimer && !_timerFired {
      wantsTimer()
    }
    solicitWindowUpdatesIfNeeded()
    _updateSelection(by: amt)
  }

  func decrementSelection(by amt: Int = 1) {
    incrementSelection(by: -amt)
  }

  func update(windows list: [WindowInfoGroup]) {
    assert(_wantsWindowUpdates)
    guard _hasUpdatedWindows else {
      // On first window update, bump the selection back if the first window is not active
      // This way, a quick opt-tab will increment 1, bump back, and activate the topmost window
      if _selection > 0 && !(list.first?.mainWindow.isAppActive ?? true) {
        _selection -= 1
      }

      windows = list
      _hasUpdatedWindows = true
      _updateSelection()
      showInterfaceIfReady()
      raiseIfReady()
      return
    }

    if !windows.isEmpty && !list.isEmpty {
      if let selectedWindowInList = list.map({ $0.mainWindow.id }).firstIndex(of: windows[_selection].mainWindow.id) {
        // If possible, maintain selection on the same window
        _selection = selectedWindowInList
      } else {
        // Otherwise, clamp selection to size of new list and fall back one
        _selection = min(_selection, list.count) - 1
      }
    }
    windows = list
    showInterfaceIfReady()
    raiseIfReady()
  }

  // MARK: - Window list update logic
  private var _hasUpdatedWindows = false
  private var _wantsWindowUpdates = false
  private func solicitWindowUpdatesIfNeeded() {
    guard !_wantsWindowUpdates else { return }
    _wantsWindowUpdates = true
    wantsStartWindowListUpdates()
  }

  private func stopWindowUpdates() {
    assert(_wantsWindowUpdates)
    _wantsWindowUpdates = false
    wantsStopWindowListUpdates()
  }

  // MARK: - Publicly read-only properties
  private(set) var windows = [WindowInfoGroup]()

  private var _selection = 0
  var selection: Int? {
    guard !windows.isEmpty else {
      assert(_selection == -1 || !_hasUpdatedWindows)
      return nil
    }
    assert(_hasUpdatedWindows)
    assert(_selection >= 0 && _selection < windows.count)
    return _selection % windows.count
  }

  var selectedWindow: WindowInfoGroup? {
    guard let index = selection else { return nil }
    return windows[index]
  }

  // MARK: - Timer management
  private var _timerFired = false
  private var _wantsTimer = false
  private func wantsTimer() {
    assert(!_timerFired)
    _wantsTimer = true
    wantsTimerCallback()
  }
  private func wantsTimerCancelled() {
    wantsTimerCancelledCallback()
    _wantsTimer = false
  }

  // MARK: - Interface management
  private var _showingInterface = false
  private func showInterfaceIfReady() {
    guard !_showingInterface else { return }
    guard _hasUpdatedWindows else { return }
    guard _timerFired else {
      assert(_wantsTimer || _wantsRaiseOnWindowUpdate)
      return
    }
    wantsShowInterfaceCallback()
    _showingInterface = true
  }
  private func hideInterface() {
    assert(_showingInterface)
    wantsHideInterfaceCallback()
    _showingInterface = false
  }

  // MARK: - Raising logic
  private var _wantsRaiseOnWindowUpdate = false
  private func raiseIfReady() {
    if _wantsRaiseOnWindowUpdate && _hasUpdatedWindows {
      if _showingInterface {
        hideInterface()
      }
      if _wantsTimer {
        wantsTimerCancelled()
      }

      stopWindowUpdates()

      if let selectedWindow = selectedWindow, selection != 0 || !selectedWindow.mainWindow.isAppActive {
        wantsRaiseCallback(selectedWindow)
      }
      _selection = 0
      _hasUpdatedWindows = false
      _wantsRaiseOnWindowUpdate = false
      _timerFired = false
      _active = false
    }
  }

  // MARK: - Private
  private func _updateSelection(by amt: Int = 0) {
    if _hasUpdatedWindows {
      if windows.isEmpty {
        _selection = -1
      } else {
        _selection = (_selection + amt) % windows.count
        if _selection < 0 {
          _selection += windows.count
        }
        assert(_selection >= 0 && _selection < windows.count)
      }
    } else {
      _selection += amt
    }
  }
}
