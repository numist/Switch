class SwitcherState {

  private var hasUpdatedWindows = false
  private(set) var windows = [WindowInfoGroup]()

  private var _selection = 0
  var selection: Int? {
    guard !windows.isEmpty else {
      assert(_selection == -1 || !hasUpdatedWindows)
      return nil
    }
    assert(hasUpdatedWindows)
    assert(_selection >= 0 && _selection < windows.count)
    return _selection % windows.count
  }

  func incrementSelection(by amt: Int = 1) {
    if hasUpdatedWindows {
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

  func decrementSelection(by amt: Int = 1) {
    incrementSelection(by: -amt)
  }

  func update(windows list: [WindowInfoGroup]) {
    guard hasUpdatedWindows else {
      // On first window update, bump the selection back if the first window is not active
      // This way, a quick opt-tab will increment 1, bump back, and activate the topmost window
      if _selection > 0 && !(list.first?.mainWindow.isAppActive ?? true) {
        _selection -= 1
      }

      windows = list
      hasUpdatedWindows = true
      // (ab)use incrementSelection with a 0 parameter to bake the current _selection into a real index into windows
      incrementSelection(by: 0)
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
  }
}
