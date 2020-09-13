/** # Switcher state machine
 *
 * Logic core responsible for powering switcher interface and window management behaviour.
 *
 * Ignoring transitions from one state to itself, the core functionality of the state machine is to implement the following DFA:
 *
 * ```
 * ╔════╗ {in,de}crementSelection()    ┌─────────────────────────────┐
 * ║Idle╠─────────────────────────────▶│Active (awaiting window list)│
 * ╚════╝ →wantsStartWindowListUpdates └──────────────┬──────────────┘
 * ▲                                                  │
 * │→wantsStopWindowListUpdates                  ┌────┴────────────┐
 * │→?wantsRaise                 update(windows:)│                 │hotKeyReleased()
 * │                                             ▼                 ▼
 * │                                         ┌──────┐  ┌──────────────────────┐
 * ├─────────────────────────────────────────┤Active│  │Active (pending raise)│
 * │           hotKeyReleased()              └──────┘  └───────────┬──────────┘
 * │                                                               │
 * └───────────────────────────────────────────────────────────────┘
 *                                 update(windows:)
 * ```
 *
 * Mixed in with the above is logic for controlling the display of the switcher interface (again, ignoring self-transitions):
 *
 * ```
 *                                   ╔════╗
 *                     ┌────────────▶║Idle║◀──────────────────────────────┐
 * →wantsTimerCancelled│             ╚══╦═╝                               │
 *                     │                │{in,de}crementSelection()        │
 *     hotKeyReleased()│                │                                 │
 *                     │                ▼→wantsTimer callback             │
 *                     ├─────────────────────────────────┐                │
 *                     │Active (awaiting: timer, windows)│                │
 *                     └─┬─────────────────────────────┬─┘                │→wantsHideInterface
 *           timerFired()▼                             ▼update(windows:)  │
 *         ┌──────────────────────────┐   ┌────────────────────────┐      │hotKeyReleased()
 *         │Active (awaiting: windows)│   │Active (awaiting: timer)│      │
 *         └─────────────┬────────────┘   └───────────┬────────────┘      │
 *       update(windows:)└──────────────┬─────────────┘timerFired()       │
 *                                      │                                 │
 *                                      ▼→wantsShowInterface              │
 *                                  ┌──────┐                              │
 *                                  │Active│──────────────────────────────┘
 *                                  └──────┘
 * ```
 */

class SwitcherState {
  // MARK: - Ins/outs

  private let wantsTimerCallback: () -> Void
  private let wantsTimerCancelledCallback: () -> Void
  private let wantsShowInterfaceCallback: () -> Void
  private let wantsHideInterfaceCallback: () -> Void
  private let wantsStartWindowListUpdates: () -> Void
  private let wantsStopWindowListUpdates: () -> Void
  private let wantsRaiseCallback: (WindowInfoGroup) -> Void

  /// Creates a new SwitcherState instance with configured callbacks
  /// - Parameters:
  ///   - wantsTimerCallback: Invoked when the state machine wants to perform an action after a delay
  ///   - wantsTimerCancelledCallback: Invoked when the state machine wants to cancel the issued timer
  ///   - wantsShowInterfaceCallback: Invoked when the owner should present the switching interface
  ///   - wantsHideInterfaceCallback: Invoked when the owner should hide the switching interface
  ///   - wantsStartWindowListUpdates: Invoked when the state machine wishes to recieve window list updates
  ///   - wantsStopWindowListUpdates: Invoked when the state machine no longer desires window list updates
  ///   - wantsRaiseCallback: Invoked when the owner should raise the window passed to the closure
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

  /// Call this function after the timer requested by this state machine has fired
  func timerFired() {
    assert(_wantsTimer)
    assert(!_timerFired)
    _timerFired = true
    _wantsTimer = false
    showInterfaceIfReady()
  }

  private var _active = false

  /// Call this function when the hotkey modifier driving the interaction has been released
  func hotKeyReleased() {
    guard _active else { return }

    // If hotkey is released before presenting interface, don't bother
    if _wantsTimer {
      wantsTimerCancelled()
    }
    _wantsRaiseOnWindowUpdate = true
    raiseIfReady()
  }

  /// Call this function when the forward hotkey has been pressed
  func incrementSelection(by amt: Int = 1) {
    guard !_wantsRaiseOnWindowUpdate else { return }

    _active = true
    if !_wantsTimer && !_timerFired {
      wantsTimer()
    }
    solicitWindowUpdatesIfNeeded()
    _updateSelection(by: amt)
  }

  /// Call this function when the reverse hotkey has been pressed
  func decrementSelection(by amt: Int = 1) {
    incrementSelection(by: -amt)
  }

  /// Call this function when the state machine has requested window list updates and a new list is available
  func update(windows list: [WindowInfoGroup]) {
    assert(_wantsWindowUpdates)
    guard _hasUpdatedWindows else {
      // On first window update, bump the selection back if the first window is not active
      // This way, a quick opt-tab will increment 1, bump back, and activate the topmost window
      if _selection > 0 && !(list.first?.mainWindow.isAppActive ?? true) {
        _selection -= 1
      }

      _windows = list
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
    _windows = list
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

  /// The window list from the last call to `update(windows:)`
  ///
  /// Do not access this property before the first `update(windows:)` after `→wantsStartWindowListUpdates`
  var windows: [WindowInfoGroup] {
    guard _hasUpdatedWindows else {
      assertionFailure()
      return [WindowInfoGroup]()
    }
    return _windows
  }
  private var _windows = [WindowInfoGroup]()

  /// The index of the selected window in `windows`, or `nil` if `windows.isEmpty`
  ///
  /// Do not access this property before the first `update(windows:)` after `→wantsStartWindowListUpdates`
  var selection: Int? {
    guard _hasUpdatedWindows else {
      assertionFailure()
      return nil
    }
    guard !_windows.isEmpty else {
      assert(_selection == -1)
      return nil
    }
    assert(_hasUpdatedWindows)
    assert(_selection >= 0 && _selection < _windows.count)
    return _selection % _windows.count
  }
  private var _selection = 0

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

      if let selection = selection, selection != 0 || !windows[selection].mainWindow.isAppActive {
        wantsRaiseCallback(windows[selection])
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
