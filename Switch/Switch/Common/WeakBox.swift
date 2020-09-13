class WeakBox<T: AnyObject> {
  private(set) weak var value: T?

  init(_ val: T) {
    value = val
  }
}
