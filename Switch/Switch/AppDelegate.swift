/*
 Goals:
 - Hold ⌘Q to quit
 - Window switcher
 - Paste history
 - Battery menu item with runtime?
 */

import Cocoa
import Combine
import LetsMove
import OSLog
import Sparkle
import SwiftUI

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
      promptForAccessibilityPermissions()
      return
    }
    // The only acceptable reason for an event tap to fail is when `!AXIsProcessTrustedWithOptions(nil)`
    try! Keyboard.enableHotKeys() // swiftlint:disable:this force_try

    Services.start(.switcher)

    let infoDictionary = Bundle.main.infoDictionary!
    let version = infoDictionary["CFBundleShortVersionString"] as? String
    let appName = infoDictionary[kCFBundleNameKey as String] as? String
    print("Launched \(appName!) \(version!)")
  }

}

// MARK: Accessibility dance

private var timerCancellable: AnyCancellable?

private func promptForAccessibilityPermissions() {
  assert(timerCancellable == nil, "promptForAccessibilityPermissions() was called more than once")

  os_log(.info, "Switch is not trusted, prompting for AX permissions")
  AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary)

  timerCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
    .autoconnect()
    .map({ _ in
      AXIsProcessTrustedWithOptions(nil)
    })
    .removeDuplicates()
    .filter({ isTrusted in
      isTrusted
    })
    .sink { _ in
      os_log(.info, "AX now trusts us")
      if !amIBeingDebugged() {
        // TODO(numist): time to relaunch!
        os_log(.info, "time to relaunch!")
      }
    }
}
