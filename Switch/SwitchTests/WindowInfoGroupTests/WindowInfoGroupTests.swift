import XCTest
@testable import Switch

// swiftlint:disable line_length

class WindowInfoGroupTests: XCTestCase {
  func testPhotosMainWindowHasEmptyName() {
    let window = WindowInfo([
      .cgNumber: UInt32(37086),
      .cgLayer: Int32(0),
      .cgBounds: CGRect(x: 0.0, y: 25.0, width: 1440.0, height: 875.0).dictionaryRepresentation,
      .cgAlpha: Float(1.0),
      .cgOwnerPID: Int32(63872),
      .cgOwnerName: "Photos",
      .cgName: "",
      .cgIsOnscreen: true,
      .cgDisplayID: UInt32(1),
      .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 875.0),
      .isFullscreen: false,
      .ownerBundleID: "com.apple.Photos",
      .canActivate: true,
      .isAppActive: false,
    ])
    let windowGroups = WindowInfoGroup.list(from: [window])
    XCTAssertEqual(1, windowGroups.count)
  }

  func testSafariStatusBar() {
    let windows = [
      WindowInfo([.cgNumber: UInt32(860), .cgLayer: Int32(0), .cgBounds: CGRect(x: 455.0, y: 878.0, width: 458.0, height: 20.0).dictionaryRepresentation, .cgAlpha: Float(0.21708053), .cgOwnerPID: Int32(568), .cgOwnerName: "Safari.app", .cgName: "", .cgIsOnscreen: true, .cgDisplayID: UInt32(1), .nsFrame: NSRect(x: 455.0, y: 2.0, width: 458.0, height: 20.0), .isFullscreen: false, .ownerBundleID: "com.apple.Safari", .canActivate: true, .isAppActive: true]),
      WindowInfo([.cgNumber: UInt32(116), .cgLayer: Int32(0), .cgBounds: CGRect(x: 452.0, y: 26.0, width: 987.0, height: 875.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(568), .cgOwnerName: "Safari.app", .cgName: "3 • Inbox | Fastmail", .cgIsOnscreen: true, .cgDisplayID: UInt32(1), .nsFrame: NSRect(x: 452.0, y: -1.0, width: 987.0, height: 875.0), .isFullscreen: false, .ownerBundleID: "com.apple.Safari", .canActivate: true, .isAppActive: true]),
    ]
    let windowGroups = WindowInfoGroup.list(from: windows)
    XCTAssertEqual(1, windowGroups.count)
    XCTAssertEqual(windows[1], windowGroups.first?.mainWindow)
  }
}

// TODO:
/*
 Bring back snapshots.
 
 Fucking Zoom shenanigans:

 [WindowInfo([
   .cgNumber: UInt32(82205),
   .cgLayer: Int32(0),
   .cgBounds: CGRect(x: 440.0, y: 236.0, width: 560.0, height: 453.0).dictionaryRepresentation,
   .cgAlpha: Float(1.0),
   .cgOwnerPID: Int32(94451),
   .cgOwnerName: "zoom.us",
   .cgName: "",
   .cgIsOnscreen: true,
   .cgDisplayID: UInt32(1),
   .nsFrame: NSRect(x: 440.0, y: 211.0, width: 560.0, height: 453.0),
   .isFullscreen: false,
   .ownerBundleID: "us.zoom.xos",
   .canActivate: true,
   .isAppActive: true,
 ]), WindowInfo([
   .cgNumber: UInt32(82206),
   .cgLayer: Int32(0),
   .cgBounds: CGRect(x: 400.0, y: 222.0, width: 640.0, height: 480.0).dictionaryRepresentation,
   .cgAlpha: Float(1.0),
   .cgOwnerPID: Int32(94451),
   .cgOwnerName: "zoom.us",
   .cgName: "Login",
   .cgIsOnscreen: true,
   .cgDisplayID: UInt32(1),
   .nsFrame: NSRect(x: 400.0, y: 198.0, width: 640.0, height: 480.0),
   .isFullscreen: false,
   .ownerBundleID: "us.zoom.xos",
   .canActivate: true,
   .isAppActive: true,
 ])]

 */
