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

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Ensure the Core Data stack is loaded before the FetchRequest is initialized
    _ = PasteboardHistory.persistentContainer

    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
      // Don't set up the app when running for previews
      return
    }

    if ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil {
      // Don't set up the app when running for unit testing
      return
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

    do {
      // This *should* only fail when !AXIsProcessTrusted
      try Keyboard.enableHotKeys()
    } catch {
      if AXIsProcessTrustedWithOptions(nil) {
        os_log(.fault, "Failed to create event tap!?")
      }
      os_log(.info, "Switch is sad :(")
    }

    ServiceManager.start(.longCmdQ)
    ServiceManager.start(.pasteboardHistory)
    ServiceManager.start(.switcher)

    os_log(.info, "Switch is ready!")
  }

}
