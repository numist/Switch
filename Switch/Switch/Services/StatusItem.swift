import Cocoa
import Defaults

class StatusItem: NSObject, NSMenuDelegate {
  var statusItem: NSStatusItem?
  var debugItems = Set<NSMenuItem>()

  override init() {
    super.init()
    Defaults.observe(.showStatusItem) { [weak self] change in
      guard let self = self else { return }
      if change.newValue && self.statusItem == nil {
        self.addStatusItem()
      } else if let statusItem = self.statusItem, !change.newValue {
        statusItem.statusBar?.removeStatusItem(statusItem)
        self.statusItem = nil
      }
    }.tieToLifetime(of: self)
  }

  private func addStatusItem() {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.image = NSImage(named: "NSPrivateChaptersTemplate") //TODO(numist): deprecated?? Bundle.main.image(forResource: "weave")
//    statusItem.highlightMode = true // TODO(numist): Deprecated??
//    statusItem.target = self // TODO(numist): Deprecated??

//    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Status Bar Menu"];
    let menu = NSMenu(title: "Status Bar Menu") // TODO(numist): how much of this is actually necessary anyway
    menu.addItem(NSMenuItem(title: "Preferences…", target: NSApplication.shared.delegate, action: #selector(AppDelegate.showPreferences(sender:)), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())

    var debugItems = Set<NSMenuItem>()

    var menuItem = NSMenuItem(title: "Hi there!")
    menuItem.isEnabled = false
    menu.addItem(menuItem)
    debugItems.insert(menuItem)

    // initWithTitle:@"Take Snapshot…" action:NNSelfSelector1(snapshot:)
    menuItem = NSMenuItem(title: "Take snapshot…")
    menu.addItem(menuItem)
    debugItems.insert(menuItem)

    // initWithTitle:@"Open Log Folder…" action:NNSelfSelector1(openLogFolder:)
    menuItem = NSMenuItem(title: "Open Log Folder…")
    menu.addItem(menuItem)
    debugItems.insert(menuItem)

    menuItem = NSMenuItem.separator()
    menu.addItem(menuItem)
    debugItems.insert(menuItem)

    self.debugItems = debugItems

    menu.addItem(
      NSMenuItem(
        title: "Quit \(Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String)!)",
        target: NSApplication.shared,
        action: #selector(NSApplication.terminate(_:))
      )
    )

    menu.delegate = self

    statusItem.menu = menu

    self.statusItem = statusItem
  }

  // MARK: NSMenuDelegate

  @objc func menuNeedsUpdate(_ menu: NSMenu) {
    let hideDebugItems = NSEvent.modifierFlags != .option

    for item in debugItems {
      item.isHidden = hideDebugItems
    }
  }
}
