import Cocoa
import SwiftUI

class SwitcherWindow {
  let window: NSWindow!
  let screen: NSScreen?

  init(displaying state: SwitcherState, for screen: NSScreen?) {
    let displayScreen = screen ?? NSScreen.main!
    self.screen = screen

    window = NSWindow(
      contentRect: displayScreen.frame,
      styleMask: [.borderless, .fullSizeContentView],
      backing: .buffered,
      defer: false,
      screen: displayScreen
    )
    window.isMovableByWindowBackground = false
    window.hasShadow = false
    window.isOpaque = false
    window.backgroundColor = NSColor.clear
    window.ignoresMouseEvents = false
    window.level = .popUpMenu
    window.setFrameOrigin(NSPoint(x: 0, y: 0))

    window.contentView = NSHostingView(rootView: SwitcherView(with: state, on: screen?.screenNumber))

    window.makeKeyAndOrderFront(nil)
  }

  deinit {
    let window = self.window!
    NSAnimationContext.runAnimationGroup({ context in
      context.duration = 0.25
      context.timingFunction = CAMediaTimingFunction(name: .default)
      window.animator().alphaValue = 0.0
    }, completionHandler: {
      window.orderOut(nil)
    })
  }
}
