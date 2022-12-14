extension Collection {
  var second: Element? {
    guard self.count > 1 else { return nil }
    return self[self.index(after: self.startIndex)]
  }
}
