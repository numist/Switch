import XCTest
@testable import Switch

//func randomWindow() -> WindowInfo {
//  return WindowInfo([
//    .cgNumber: Int.random(in: 0..<1000),
//    .cgStoreType: 2,
//    .cgBounds: CGRect(
//      x: Int.random(in: 0..<1000),
//      y: Int.random(in: 0..<1000),
//      width: Int.random(in: 0..<1000),
//      height: Int.random(in: 0..<1000)).dictionaryRepresentation,
//    .cgSharingState: 0,
//    .cgAlpha: 1.0,
//    .cgOwnerPID: Int.random(in: 0..<1000),
//    .cgMemoryUsage: Int.random(in: 0..<1000),
//
//    .isFullscreen: false,
//    .canActivate: true,
//    .isAppActive: Bool.random(),
//  ])
//}
//
//func randomWindowGroup() -> WindowInfoGroup {
//  let windowInfo = randomWindow()
//  return WindowInfoGroup(mainWindow: windowInfo, windows: [windowInfo])
//}

class SwitcherStateTests: XCTestCase {
  func testBumpBackOnInactiveFrontmostWindow() {
    let window1 = [
      WindowInfo([
        .cgNumber: UInt32.random(in: 0..<1000),
        .cgLayer: kCGNormalWindowLevel,
        .cgBounds: CGRect(
          x: Int.random(in: 0..<1000),
          y: Int.random(in: 0..<1000),
          width: Int.random(in: 0..<1000),
          height: Int.random(in: 0..<1000)).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32.random(in: 0..<1000),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
    ]
    let window2 = [
      WindowInfo([
        .cgNumber: UInt32.random(in: 0..<1000),
        .cgLayer: kCGNormalWindowLevel,
        .cgBounds: CGRect(
          x: Int.random(in: 0..<1000),
          y: Int.random(in: 0..<1000),
          width: Int.random(in: 0..<1000),
          height: Int.random(in: 0..<1000)).dictionaryRepresentation,
        .cgAlpha: Float(1.0),
        .cgOwnerPID: Int32.random(in: 0..<1000),
        .isFullscreen: false,
        .canActivate: true,
        .isAppActive: false,
      ]),
    ]
    let state = SwitcherState()
    state.incrementSelection()
    state.update(windows: [
      WindowInfoGroup(mainWindow: window1.first!, windows: window1),
      WindowInfoGroup(mainWindow: window2.first!, windows: window2),
    ])
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
}
