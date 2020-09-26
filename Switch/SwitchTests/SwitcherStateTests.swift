import XCTest
@testable import Switch

// swiftlint:disable file_length
// swiftlint:disable type_body_length
// swiftlint:disable function_body_length
class SwitcherStateTests: XCTestCase {
  func testBumpBackOnInactiveFrontmostWindowWhenIncrementing() {
    var raised = false
    let windowGroupList = WindowInfoGroup.list(from: [
      WindowInfo([
        .cgNumber: UInt32(510),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(1426),
        .cgOwnerName: "System Preferences",
        .cgName: "Security & Privacy",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
      WindowInfo([
        .cgNumber: UInt32(5275),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 61.0, y: 238.0, width: 720.0, height: 445.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(16649),
        .cgOwnerName: "TextMate",
        .cgName: "untitled 8",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 61.0, y: 217.0, width: 720.0, height: 445.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
    ])
    let state = SwitcherState(
      wantsRaiseCallback: { windowGroup in
        raised = true
        XCTAssertEqual(windowGroup, windowGroupList[0])
      }
    )
    state.incrementSelection()
    state.update(windows: windowGroupList)
    XCTAssertEqual(state.selection, 0)
    state.hotKeyReleased()
    XCTAssertTrue(raised)
  }

  func testNoBumpBackOnInactiveFrontmostWindowWhenDecrementing() {
    var raised = false
    let windowGroupList = WindowInfoGroup.list(from: [
      WindowInfo([
        .cgNumber: UInt32(510),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(1426),
        .cgOwnerName: "System Preferences",
        .cgName: "Security & Privacy",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
      WindowInfo([
        .cgNumber: UInt32(5275),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 61.0, y: 238.0, width: 720.0, height: 445.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(16649),
        .cgOwnerName: "TextMate",
        .cgName: "untitled 8",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 61.0, y: 217.0, width: 720.0, height: 445.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
    ])
    let state = SwitcherState(
      wantsRaiseCallback: { windowGroup in
        raised = true
        XCTAssertEqual(windowGroup, windowGroupList[1])
      }
    )
    state.decrementSelection()
    state.update(windows: windowGroupList)
    XCTAssertEqual(state.selection, 1)
    state.hotKeyReleased()
    XCTAssertTrue(raised)
  }

  func testNoBumpBackOnInactiveFrontmostWindowWhenNoChange() {
    var raised = false
    let windowGroupList = WindowInfoGroup.list(from: [
      WindowInfo([
        .cgNumber: UInt32(510),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(1426),
        .cgOwnerName: "System Preferences",
        .cgName: "Security & Privacy",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
      WindowInfo([
        .cgNumber: UInt32(5275),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 61.0, y: 238.0, width: 720.0, height: 445.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(16649),
        .cgOwnerName: "TextMate",
        .cgName: "untitled 8",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 61.0, y: 217.0, width: 720.0, height: 445.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
    ])
    let state = SwitcherState(
      wantsRaiseCallback: { windowGroup in
        raised = true
        XCTAssertEqual(windowGroup, windowGroupList[0])
      }
    )
    state.incrementSelection(by: 0)
    state.update(windows: windowGroupList)
    XCTAssertEqual(state.selection, 0)
    state.hotKeyReleased()
    XCTAssertTrue(raised)
  }

  func testNoRaiseForActiveTopmost() {
    var raised = false
    let windowGroupList = WindowInfoGroup.list(from: [
      WindowInfo([
        .cgNumber: UInt32(510),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(1426),
        .cgOwnerName: "System Preferences",
        .cgName: "Security & Privacy",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: true,
      ]),
      WindowInfo([
        .cgNumber: UInt32(5275),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 61.0, y: 238.0, width: 720.0, height: 445.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(16649),
        .cgOwnerName: "TextMate",
        .cgName: "untitled 8",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 61.0, y: 217.0, width: 720.0, height: 445.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
    ])
    let state = SwitcherState(
      wantsRaiseCallback: { _ in
        raised = true
      }
    )
    state.incrementSelection(by: 0)
    state.update(windows: windowGroupList)
    XCTAssertEqual(state.selection, 0)
    state.hotKeyReleased()
    XCTAssertFalse(raised)
  }

  func testNoRaiseOnEmptyWindowList() {
    var raised = false
    let windowGroupList = WindowInfoGroup.list(from: [])
    let state = SwitcherState(
      wantsRaiseCallback: { _ in raised = true }
    )
    state.incrementSelection(by: 0)
    state.update(windows: windowGroupList)
    XCTAssertNil(state.selection)
    state.hotKeyReleased()
    XCTAssertFalse(raised)
  }

  func testSelectionResetsOnRelease() {
    let windowGroupList = WindowInfoGroup.list(from: [
      WindowInfo([
        .cgNumber: UInt32(510),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(1426),
        .cgOwnerName: "System Preferences",
        .cgName: "Security & Privacy",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: true,
      ]),
      WindowInfo([
        .cgNumber: UInt32(5275),
        .cgLayer: Int32(0),
        .cgBounds: CGRect(x: 61.0, y: 238.0, width: 720.0, height: 445.0).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32(16649),
        .cgOwnerName: "TextMate",
        .cgName: "untitled 8",
        .cgIsOnscreen: true,
        .cgDisplayID: UInt32(69732800),
        .nsFrame: NSRect(x: 61.0, y: 217.0, width: 720.0, height: 445.0),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
    ])
    let state = SwitcherState()
    state.incrementSelection()
    state.update(windows: windowGroupList)
    state.hotKeyReleased()
    state.incrementSelection(by: 0)
    state.update(windows: windowGroupList)
    XCTAssertEqual(state.selection, 0)
  }

  func testNilSelectorWithoutWindows() {
    let state = SwitcherState()
    state.incrementSelection()
    state.update(windows: [])
    XCTAssertNil(state.selection)
    state.incrementSelection()
    XCTAssertNil(state.selection)
  }

  func testWantsTimerOnEachInvoke() {
    var wantsWindowUpdates = false
    var wantsTimer = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false }
    )

    XCTAssertFalse(wantsTimer)
    state.incrementSelection()
    XCTAssertTrue(wantsTimer)
    state.hotKeyReleased()
    XCTAssertFalse(wantsTimer)

    // While we're here, make sure the state obj wants window updates until it gets one
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [])
    XCTAssertFalse(wantsWindowUpdates)

    state.incrementSelection()
    XCTAssertTrue(wantsTimer)
  }

  func testWantsInterfaceAfterTimerAndWindows() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )
    state.incrementSelection()
    assert(wantsWindowUpdates)
    state.timerFired(); wantsTimer = false
    state.update(windows: [])
    assert(showingInterface)

    state.hotKeyReleased()

    state.incrementSelection()
    assert(wantsWindowUpdates)
    state.update(windows: [])
    state.timerFired(); wantsTimer = false
    assert(showingInterface)
  }

  func testNoInterfaceAfterTimerAlone() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    assert(wantsWindowUpdates)
    state.timerFired()
    assert(!showingInterface)
  }

  func testNoInterfaceAfterWindowsAlone() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    assert(wantsWindowUpdates)
    state.update(windows: [])
    assert(wantsTimer)
    assert(wantsWindowUpdates)
    assert(!showingInterface)
  }

  func testCloseFirstWindow() {
    let groups = WindowInfoGroup.list(from: [
      // swiftlint:disable line_length
      WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.dt.Xcode", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(510), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(1426), .cgOwnerName: "System Preferences", .cgName: "Security & Privacy", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0), .isFullscreen: false, .ownerBundleID: "com.apple.systempreferences", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(10053), .cgLayer: Int32(0), .cgBounds: CGRect(x: 61.0, y: 23.0, width: 1369.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(16649), .cgOwnerName: "TextMate", .cgName: "untitled 12", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 61.0, y: 0.0, width: 1369.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.macromates.TextMate", .canActivate: true, .isAppActive: false]),
      // swiftlint:enable line_length
    ])

    let state = SwitcherState()
    state.setSelection(to: 0)
    state.update(windows: groups)
    XCTAssertEqual(0, state.selection)
    state.update(windows: Array(groups.dropFirst()))
    XCTAssertEqual(0, state.selection)
  }
}

// MARK: - Fuzzer tests

let groups = WindowInfoGroup.list(from: [
  // swiftlint:disable line_length
  WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.dt.Xcode", .canActivate: true, .isAppActive: false]),
  WindowInfo([.cgNumber: UInt32(510), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(1426), .cgOwnerName: "System Preferences", .cgName: "Security & Privacy", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0), .isFullscreen: false, .ownerBundleID: "com.apple.systempreferences", .canActivate: true, .isAppActive: false]),
  WindowInfo([.cgNumber: UInt32(10053), .cgLayer: Int32(0), .cgBounds: CGRect(x: 61.0, y: 23.0, width: 1369.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(16649), .cgOwnerName: "TextMate", .cgName: "untitled 12", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 61.0, y: 0.0, width: 1369.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.macromates.TextMate", .canActivate: true, .isAppActive: false]),
  // swiftlint:enable line_length
])

extension SwitcherStateTests {
  func testFuzzIncrementAfterTimerFired() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.decrementSelection()
    state.incrementSelection()
    assert(wantsTimer)
    state.timerFired(); wantsTimer = false
    state.incrementSelection()
  }

  func testFuzzSomething() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    assert(wantsWindowUpdates)
    state.update(windows: [])
    assert(wantsTimer)
    state.timerFired(); wantsTimer = false
    state.decrementSelection()
    assert(wantsWindowUpdates)
    state.hotKeyReleased()
    state.hotKeyReleased()
    state.incrementSelection()
    assert(wantsWindowUpdates)
  }

  func testFuzzIncrementAfterRaise() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    assert(wantsWindowUpdates)
    state.hotKeyReleased()
    state.incrementSelection()
    assert(wantsWindowUpdates)
    state.update(windows: [])
    state.hotKeyReleased()
    state.incrementSelection()
    assert(wantsWindowUpdates)
  }

  func testFuzzNoMoreWindows() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    // wantsTimer → true
    // wantsWindows → true
    assert(wantsWindowUpdates)
    state.update(windows: [groups[0], groups[2]])
    assert(wantsWindowUpdates)
    state.update(windows: [])
    XCTAssertNil(state.selection)
  }

  func testFuzzAddingWindows() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { assert(!wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { assert(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { assert(!showingInterface); showingInterface = true },
      wantsHideInterfaceCallback: { assert(showingInterface); showingInterface = false },
      wantsStartWindowListUpdates: { assert(!wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { assert(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    // wantsTimer → true
    // wantsWindows → true
    assert(wantsWindowUpdates)
    state.update(windows: [groups[0], groups[2]])
    assert(wantsWindowUpdates)
    state.update(windows: Array(groups.dropLast()))
    assert(wantsWindowUpdates)
    state.update(windows: Array(groups.dropFirst()))
    assert(wantsWindowUpdates)
    state.update(windows: [groups[0], groups[2]])
    state.decrementSelection()
    assert(wantsWindowUpdates)
    state.update(windows: [])
    assert(wantsWindowUpdates)
    state.update(windows: Array(groups.dropLast()))
    XCTAssertEqual(0, state.selection)
  }

  func testFuzz() {
    var wantsTimer = false
    var showingInterface = false
    var wantsWindowUpdates = false
    var hasUpdatedWindows = false
    let state = SwitcherState(
      wantsTimerCallback: {
        print("// wantsTimer → true")
        assert(!wantsTimer); wantsTimer = true
      },
      wantsTimerCancelledCallback: {
        print("// wantsTimer → false")
        assert(wantsTimer); wantsTimer = false
      },
      wantsShowInterfaceCallback: {
        print("// wantsInterface → true")
        assert(!showingInterface); showingInterface = true
      },
      wantsHideInterfaceCallback: {
        print("// wantsInterface → false")
        assert(showingInterface); showingInterface = false
      },
      wantsStartWindowListUpdates: {
        print("// wantsWindows → true")
        assert(!wantsWindowUpdates); wantsWindowUpdates = true
      },
      wantsStopWindowListUpdates: {
        print("// wantsWindows → false")
        assert(wantsWindowUpdates); wantsWindowUpdates = false; hasUpdatedWindows = false
      },
      wantsRaiseCallback: {_ in print("// wantsRaise") }
    )

    var active = false
    let start = Date()
    while -start.timeIntervalSinceNow < 0.1 {
      if showingInterface { assert(hasUpdatedWindows) }
      if hasUpdatedWindows {
        assert(wantsWindowUpdates)
        _ = state.selection
        _ = state.windows
      }

      // swiftlint:disable opening_brace
      [
        {
          active = true
          print("state.incrementSelection()")
          state.incrementSelection(); assert(wantsWindowUpdates)
          print("assert(wantsWindowUpdates)")
        },
        {
          active = true
          print("state.decrementSelection()")
          state.decrementSelection(); assert(wantsWindowUpdates)
          print("assert(wantsWindowUpdates)")
        },
        { if active {
          print("state.hotKeyReleased()")
          state.hotKeyReleased(); assert(!showingInterface)
          print("assert(!showingInterface)")
          active = false
        } },
        { if wantsTimer {
          print("assert(wantsTimer)\nstate.timerFired(); wantsTimer = false")
          state.timerFired(); wantsTimer = false
        } },
        { if wantsWindowUpdates {
          print("assert(wantsWindowUpdates)\nstate.update(windows: [])")
          hasUpdatedWindows = true; state.update(windows: [])
        } },
        { if wantsWindowUpdates {
          print("assert(wantsWindowUpdates)\nstate.update(windows: groups)")
          hasUpdatedWindows = true; state.update(windows: groups)
        } },
        { if wantsWindowUpdates {
          print("assert(wantsWindowUpdates)\nstate.update(windows: Array(groups.dropFirst()))")
          hasUpdatedWindows = true; state.update(windows: Array(groups.dropFirst()))
        } },
        { if wantsWindowUpdates {
          print("assert(wantsWindowUpdates)\nstate.update(windows: [groups[0], groups[2]])")
          hasUpdatedWindows = true; state.update(windows: [groups[0], groups[2]])
        } },
        { if wantsWindowUpdates {
          print("assert(wantsWindowUpdates)\nstate.update(windows: Array(groups.dropLast()))")
          hasUpdatedWindows = true; state.update(windows: Array(groups.dropLast()))
        } },
      ].randomElement()!()
      // swiftlint:enable opening_brace
    }
  }
}
