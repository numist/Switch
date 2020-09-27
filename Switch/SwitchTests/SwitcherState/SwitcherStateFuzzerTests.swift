import XCTest
@testable import Switch

let groups = WindowInfoGroup.list(from: [
  // swiftlint:disable line_length
  WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.dt.Xcode", .canActivate: true, .isAppActive: false]),
  WindowInfo([.cgNumber: UInt32(510), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(1426), .cgOwnerName: "System Preferences", .cgName: "Security & Privacy", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0), .isFullscreen: false, .ownerBundleID: "com.apple.systempreferences", .canActivate: true, .isAppActive: false]),
  WindowInfo([.cgNumber: UInt32(10053), .cgLayer: Int32(0), .cgBounds: CGRect(x: 61.0, y: 23.0, width: 1369.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(16649), .cgOwnerName: "TextMate", .cgName: "untitled 12", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 61.0, y: 0.0, width: 1369.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.macromates.TextMate", .canActivate: true, .isAppActive: false]),
  // swiftlint:enable line_length
])

class SwitcherStateFuzzerDerivedTests: XCTestCase {
  func testFuzzIncrementAfterTimerFired() {
    var wantsTimer = false
    let state = SwitcherState(
      wantsTimerCallback: { XCTAssertFalse(wantsTimer); wantsTimer = true }
    )

    state.decrementSelection()
    state.incrementSelection()
    XCTAssertTrue(wantsTimer)
    state.timerFired(); wantsTimer = false
    state.incrementSelection()
  }

  func testFuzzSomething() {
    var wantsTimer = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { XCTAssertFalse(wantsTimer); wantsTimer = true },
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { XCTAssertTrue(wantsWindowUpdates); wantsWindowUpdates = false }
    )

    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [])
    XCTAssertTrue(wantsTimer)
    state.timerFired(); wantsTimer = false
    state.decrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.hotKeyReleased()
    state.hotKeyReleased()
    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
  }

  func testFuzzIncrementAfterRaise() {
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { XCTAssertTrue(wantsWindowUpdates); wantsWindowUpdates = false }
    )

    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.hotKeyReleased()
    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [])
    state.hotKeyReleased()
    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
  }

  func testFuzzNoMoreWindows() {
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true }
    )

    state.incrementSelection()
    // wantsTimer → true
    // wantsWindows → true
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [groups[0], groups[2]])
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [])
    XCTAssertNil(state.selection)
  }

  func testFuzzAddingWindows() {
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true }
    )

    state.incrementSelection()
    // wantsTimer → true
    // wantsWindows → true
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [groups[0], groups[2]])
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: Array(groups.dropLast()))
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: Array(groups.dropFirst()))
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [groups[0], groups[2]])
    state.decrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [])
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: Array(groups.dropLast()))
    XCTAssertEqual(0, state.selection)
  }
}

class SwitcherStateFuzzerTests: XCTestCase {
  // swiftlint:disable:next cyclomatic_complexity function_body_length
  func testFuzz() {
    var script = ""
    var wantsTimer = false
    var wantsInterface = false
    var wantsWindowUpdates = false
    var hasUpdatedWindows = false
    let state = SwitcherState(
      wantsTimerCallback: {
        script += "// wantsTimer → true\nXCTAssertTrue(wantsTimer)\n"
        XCTAssertFalse(wantsTimer); wantsTimer = true
      },
      wantsTimerCancelledCallback: {
        script += "// wantsTimer → false\n"
        XCTAssertTrue(wantsTimer); wantsTimer = false
      },
      wantsShowInterfaceCallback: {
        script += "// wantsInterface → true\nXCTAssertTrue(wantsInterface)\n"
        XCTAssertFalse(wantsInterface); wantsInterface = true
      },
      wantsHideInterfaceCallback: {
        script += "// wantsInterface → false\n"
        XCTAssertTrue(wantsInterface); wantsInterface = false
      },
      wantsStartWindowListUpdates: {
        script += "// wantsWindowUpdates → true\nXCTAssertTrue(wantsWindowUpdates)\n"
        XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true
      },
      wantsStopWindowListUpdates: {
        script += "// wantsWindowUpdates → false\nXCTAssertFalse(wantsWindowUpdates)\n"
        XCTAssertTrue(wantsWindowUpdates); wantsWindowUpdates = false; hasUpdatedWindows = false
      },
      wantsRaiseCallback: {_ in script += "// wantsRaise\n" }
    )

    var active = false
    let start = Date()
    var iterations = 0
    while -start.timeIntervalSinceNow < 0.1 {
      if self.testRun!.failureCount > 0 {
        print(script)
        break
      }
      if wantsInterface { XCTAssertTrue(hasUpdatedWindows) }
      if hasUpdatedWindows {
        XCTAssertTrue(wantsWindowUpdates)
        _ = state.selection
        _ = state.windows
      }

      // swiftlint:disable opening_brace
      [
        {
          active = true
          script += "state.incrementSelection()\n"
          state.incrementSelection(); XCTAssertTrue(wantsWindowUpdates)
          script += "XCTAssertTrue(wantsWindowUpdates)\n"
        },
        {
          active = true
          script += "state.decrementSelection()\n"
          state.decrementSelection(); XCTAssertTrue(wantsWindowUpdates)
          script += "XCTAssertTrue(wantsWindowUpdates)\n"
        },
        { if active {
          script += "state.hotKeyReleased()\n"
          state.hotKeyReleased(); XCTAssertFalse(wantsInterface)
          script += "XCTAssertFalse(wantsInterface)\n"
          active = false
        } },
        { if wantsTimer {
          script += "XCTAssertTrue(wantsTimer)\nstate.timerFired(); wantsTimer = false\n"
          state.timerFired(); wantsTimer = false
        } },
        { if wantsWindowUpdates {
          script += "XCTAssertTrue(wantsWindowUpdates)\nstate.update(windows: [])\n"
          hasUpdatedWindows = true; state.update(windows: [])
        } },
        { if wantsWindowUpdates {
          script += "XCTAssertTrue(wantsWindowUpdates)\nstate.update(windows: groups)\n"
          hasUpdatedWindows = true; state.update(windows: groups)
        } },
        { if wantsWindowUpdates {
          script += "XCTAssertTrue(wantsWindowUpdates)\nstate.update(windows: Array(groups.dropFirst()))\n"
          hasUpdatedWindows = true; state.update(windows: Array(groups.dropFirst()))
        } },
        { if wantsWindowUpdates {
          script += "XCTAssertTrue(wantsWindowUpdates)\nstate.update(windows: [groups[0], groups[2]])\n"
          hasUpdatedWindows = true; state.update(windows: [groups[0], groups[2]])
        } },
        { if wantsWindowUpdates {
          script += "XCTAssertTrue(wantsWindowUpdates)\nstate.update(windows: Array(groups.dropLast()))\n"
          hasUpdatedWindows = true; state.update(windows: Array(groups.dropLast()))
        } },
      ].randomElement()!()
      // swiftlint:enable opening_brace
      iterations += 1
    }
    print("Fuzzer completed \(iterations) iterations")
  }
}
