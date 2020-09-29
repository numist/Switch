/*
 Goals:
 - Hold ⌘Q to quit
 - Window switcher
 - Paste history
 - Battery menu item with runtime?
 */

import Cocoa
import SwiftUI
import OSLog
import LetsMove
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
      // Don't set up the app when running for previews
      return
    }

    if ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil {
      // Don't set up the app when running unit tests
      return
    }

    if !amIBeingDebugged() {
      PFMoveToApplicationsFolderIfNecessary()
    }

    // AX permissions shenanigans
    guard AXIsProcessTrustedWithOptions(nil) else {
      // TODO(numist): show some instructions
      os_log(.info, "Switch is not trusted, prompting for AX permissions")
      AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)
      // axPoller monitors AX state and relaunches when the process becomes trusted
      ServiceManager.start(.axPoller)
      return
    }
    // The only acceptable reason for an event tap to fail is when `!AXIsProcessTrustedWithOptions(nil)`
    try! Keyboard.enableHotKeys() // swiftlint:disable:this force_try

    ServiceManager.start(.longCmdQ)
    ServiceManager.start(.pasteboardHistory)
    ServiceManager.start(.switcher)

    os_log(.info, "Switch is ready!")
  }

}
