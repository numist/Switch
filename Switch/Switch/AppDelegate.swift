/*
 Goals:
 - Hold ⌘Q to quit
 - Window switcher
 - Paste history
 - Battery menu item with runtime?
 */

import Cocoa
import Combine
import Defaults
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

    Services.start(.statusItem)

    // AX permissions shenanigans
    guard AXIsProcessTrustedWithOptions(nil) else {
      promptForAccessibilityPermissions()
      return
    }
    // The only acceptable reason for an event tap to fail is when `!AXIsProcessTrustedWithOptions(nil)`
    try! Keyboard.enableHotKeys() // swiftlint:disable:this force_try

    Defaults.observe(.SUFeedURL) { change in
      SUUpdater.shared()?.feedURL = URL(string: change.newValue)!
    }.tieToLifetime(of: self)

    if Defaults[.firstLaunch] {
      print("This is our first launch!!")
      // TODO(numist): show prefs
    }

    Services.start(.switcher)

    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    let appName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String)
    print("Launched \(appName!) \(version!)")
  }

  @objc func showPreferences(sender: NSObject?) {
    // TODO(numist): preferences window
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
