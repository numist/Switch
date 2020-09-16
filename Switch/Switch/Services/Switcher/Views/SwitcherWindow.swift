import Cocoa
import SwiftUI

class SwitcherWindow {
  let window: NSWindow!

  init(displaying state: SwitcherState) {
    window = NSWindow(
      contentRect: NSScreen.main!.frame,
      styleMask: [.borderless, .fullSizeContentView],
      backing: .buffered,
      defer: false,
      screen: NSScreen.main
    )
    window.isMovableByWindowBackground = false
    window.hasShadow = false
    window.isOpaque = false
    window.backgroundColor = NSColor.clear
    window.ignoresMouseEvents = false
    window.level = .popUpMenu
    window.setFrameOrigin(NSPoint(x: 0, y: 0))
    window.setFrameAutosaveName("Switcher Window")

    window.contentView = NSHostingView(rootView: SwitcherView(state: state))

    window.makeKeyAndOrderFront(nil)
  }

  deinit {
    window.orderOut(nil)
  }
}
