extension Set {
  func intersects(_ other: Self) -> Bool {
    let smaller = self.count < other.count ? self : other
    let larger = self.count < other.count ? other : self
    for element in smaller {
      if larger.contains(element) { return true }
    }
    return false
  }
}
