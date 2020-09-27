import XCTest
@testable import Switch

// swiftlint:disable line_length

class WindowInfoGroupTestsChrome: XCTestCase {
  func testStatusBar() {
    let mainWindow = WindowInfo([.canActivate: true, .cgAlpha: Float(1.0), .cgBounds: CGRect(x: 0.0, y: 22.0, width: 1366.0, height: 731.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "96001-06025-07 BOLT, FLANGE (6X25) $0.74", .cgNumber: UInt32(11304), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"])
    let windows = [
      WindowInfo([.canActivate: true, .cgAlpha: Float(1.0), .cgBounds: CGRect(x: 0.0, y: 735.0, width: 456.0, height: 18.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "", .cgNumber: UInt32(1303), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"]),
      mainWindow,
    ]

    let windowGroups = WindowInfoGroup.list(from: windows)
    XCTAssertEqual(1, windowGroups.count)
    XCTAssertEqual(mainWindow, windowGroups.first?.mainWindow)
  }

  func testMultipleWindows() {
    let window1 = WindowInfo([.canActivate: true, .cgAlpha: Float(0.0), .cgBounds: CGRect(x: 0.0, y: 752.0, width: 456.0, height: 1.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "", .cgNumber: UInt32(17988), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"])
    let window2 = WindowInfo([.canActivate: true, .cgAlpha: Float(1.0), .cgBounds: CGRect(x: 0.0, y: 22.0, width: 1366.0, height: 731.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "Some wobsite", .cgNumber: UInt32(17989), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"])
    let window3 = WindowInfo([.canActivate: true, .cgAlpha: Float(0.0), .cgBounds: CGRect(x: 0.0, y: 752.0, width: 456.0, height: 1.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "", .cgNumber: UInt32(17960), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"])
    let window4 = WindowInfo([.canActivate: true, .cgAlpha: Float(1.0), .cgBounds: CGRect(x: 0.0, y: 22.0, width: 1366.0, height: 731.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "[Ardent] climbing this week? - numist@numist.net - numist.net Mail", .cgNumber: UInt32(17961), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"])
    let window5 = WindowInfo([.canActivate: true, .cgAlpha: Float(0.0), .cgBounds: CGRect(x: 68.0, y: 740.0, width: 410.0, height: 1.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "", .cgNumber: UInt32(17963), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"])
    let window6 = WindowInfo([.canActivate: true, .cgAlpha: Float(1.0), .cgBounds: CGRect(x: 68.0, y: 22.0, width: 1229.0, height: 719.0).dictionaryRepresentation, .cgDisplayID: UInt32(69732800), .cgIsOnscreen: true, .cgLayer: Int32(0), .cgName: "Google+ Hangouts", .cgNumber: UInt32(17964), .cgOwnerName: "Google Chrome", .cgOwnerPID: Int32(8705), .isAppActive: false, .isFullscreen: false, .ownerBundleID: "com.google.Chrome"])
    let windows = [window1, window2, window3, window4, window5, window6]

    let windowGroups = WindowInfoGroup.list(from: windows)
    XCTAssertEqual(3, windowGroups.count)
    XCTAssertEqual(window2, windowGroups.first?.mainWindow)
    XCTAssertEqual(window4, windowGroups.second?.mainWindow)
    XCTAssertEqual(window6, windowGroups.last?.mainWindow)
  }
}
