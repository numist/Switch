import XCTest
@testable import Switch

class SwitcherStateTests: XCTestCase {
  func testBumpBackOnInactiveFrontmostWindow() {
    let windowList = [
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
    ]
    let state = SwitcherState()
    state.incrementSelection()
    state.update(windows: WindowInfoGroup.list(from: windowList))
    XCTAssertEqual(state.selection, 0)
  }

  func testAccessSelectionBeforeUpdate() {
    let state = SwitcherState()
    _ = state.selection
    state.incrementSelection()
    _ = state.selection
    state.decrementSelection(by: 2)
    _ = state.selection
  }

  func testNilSelectorWithoutWindows() {
    let state = SwitcherState()
    XCTAssertNil(state.selection)
    state.incrementSelection()
    XCTAssertNil(state.selection)
    state.update(windows: [])
    XCTAssertNil(state.selection)
    state.incrementSelection()
    XCTAssertNil(state.selection)
  }
}
