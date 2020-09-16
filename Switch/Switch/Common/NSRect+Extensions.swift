import Foundation

extension NSRect: Hashable {
  init(origin: NSPoint, size: NSSize) {
    self.init(x: origin.x, y: origin.y, width: size.width, height: size.height)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.origin.x)
    hasher.combine(self.origin.y)
    hasher.combine(self.size.width)
    hasher.combine(self.size.height)
  }
}
