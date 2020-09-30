import Cocoa

extension NSMenuItem {
  convenience init(
    title string: String,
    target: AnyObject? = nil,
    action selector: Selector? = nil,
    keyEquivalent charCode: String = ""
  ) {
    self.init(title: string, action: selector, keyEquivalent: charCode)
    self.target = target
  }
}
