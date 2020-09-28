import XCTest
@testable import Switch

// swiftlint:disable:next type_body_length
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
      wantsRaiseCallback: { _ in raised = true }
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
    XCTAssertEqual(state.selection, 1)
    state.hotKeyReleased()
    XCTAssertNil(state.selection)
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
      wantsTimerCallback: { XCTAssertFalse(wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { XCTAssertTrue(wantsTimer); wantsTimer = false },
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { XCTAssertTrue(wantsWindowUpdates); wantsWindowUpdates = false }
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
    var wantsInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { XCTAssertFalse(wantsTimer); wantsTimer = true },
      wantsShowInterfaceCallback: { XCTAssertFalse(wantsInterface); wantsInterface = true },
      wantsHideInterfaceCallback: { XCTAssertTrue(wantsInterface); wantsInterface = false },
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { XCTAssertTrue(wantsWindowUpdates); wantsWindowUpdates = false }
    )
    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    XCTAssertTrue(wantsTimer)
    state.timerFired(); wantsTimer = false
    state.update(windows: [])
    XCTAssertTrue(wantsInterface)

    state.hotKeyReleased()
    XCTAssertFalse(wantsInterface)

    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [])
    XCTAssertTrue(wantsTimer)
    state.timerFired(); wantsTimer = false
    XCTAssertTrue(wantsInterface)
  }

  func testNoInterfaceAfterTimerAlone() {
    var wantsTimer = false
    var wantsInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { XCTAssertFalse(wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { XCTAssertTrue(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { XCTAssertFalse(wantsInterface); wantsInterface = true },
      wantsHideInterfaceCallback: { XCTAssertTrue(wantsInterface); wantsInterface = false },
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { XCTAssertTrue(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.timerFired()
    XCTAssertFalse(wantsInterface)
  }

  func testNoInterfaceAfterWindowsAlone() {
    var wantsTimer = false
    var wantsInterface = false
    var wantsWindowUpdates = false
    let state = SwitcherState(
      wantsTimerCallback: { XCTAssertFalse(wantsTimer); wantsTimer = true },
      wantsTimerCancelledCallback: { XCTAssertTrue(wantsTimer); wantsTimer = false },
      wantsShowInterfaceCallback: { XCTAssertFalse(wantsInterface); wantsInterface = true },
      wantsHideInterfaceCallback: { XCTAssertTrue(wantsInterface); wantsInterface = false },
      wantsStartWindowListUpdates: { XCTAssertFalse(wantsWindowUpdates); wantsWindowUpdates = true },
      wantsStopWindowListUpdates: { XCTAssertTrue(wantsWindowUpdates); wantsWindowUpdates = false },
      wantsRaiseCallback: {_ in}
    )

    state.incrementSelection()
    XCTAssertTrue(wantsWindowUpdates)
    state.update(windows: [])
    XCTAssertTrue(wantsTimer)
    XCTAssertTrue(wantsWindowUpdates)
    XCTAssertFalse(wantsInterface)
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
