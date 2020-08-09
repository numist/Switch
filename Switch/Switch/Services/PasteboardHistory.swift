import Cocoa
import OSLog

/*
 Storage?:

 CREATE TABLE pasteboardItems(appName, bundleId, snippet, inserted, used)
 DELETE FROM pasteboardItems WHERE used < MAX(?, SELECT used FROM pasteboardItems ORDER BY used DESC LIMIT 1 OFFSET ?)

 */

class PasteboardHistory {
  private var sizeLimit = 1024
  private var capacityLimit = 1024
  private var expiration = Date()

  private var changeCount: Int
  private var mouseClickEventTap: EventTap! = nil

  private func recordPasteboard() {
    let pasteboard = NSPasteboard.general
    guard changeCount != pasteboard.changeCount else { return }
    changeCount = pasteboard.changeCount

    let workspace = NSWorkspace.shared
    if let path = workspace.absolutePathForApplication(withBundleIdentifier: "com.tinyspeck.slackmacgap") {
      print("icon for Slack: \(workspace.icon(forFile: path))")
    }

    let app = workspace.frontmostApplication?.bundleIdentifier ?? "(unknown)"
    let item = pasteboard.pasteboardItems?.first?.string(forType: .string)
    print("\(pasteboard.pasteboardItems?.count ?? -1) pasteboard items at changeCount \(changeCount), first is from \(app): \(item ?? "(nil)")")
  }

  private let viewHistory: (Bool) -> Bool = { keyDown in
    return false
  }

  init() {
    changeCount = NSPasteboard.general.changeCount

    mouseClickEventTap = try? EventTap(observing: .leftMouseUp, callback: { (_, event) -> CGEvent? in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.50) {
        self.recordPasteboard()
      }
      return event
    })

    let asyncAndRecord: (Bool) -> Bool = { _ in
      DispatchQueue.main.asyncAfter(deadline: .now()) {
        self.recordPasteboard()
      }
      return true
    }
    Keyboard.register(.init(.command, .x), asyncAndRecord)
    Keyboard.register(.init(.command, .c), asyncAndRecord)
  }

  deinit {
    Keyboard.deregister(.init(.command, .x))
    Keyboard.deregister(.init(.command, .c))
  }
}
