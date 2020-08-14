import Foundation

extension NSRect: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.origin.x)
    hasher.combine(self.origin.y)
    hasher.combine(self.size.width)
    hasher.combine(self.size.height)
  }
}
