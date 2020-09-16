import Cocoa

extension NSImage {
  /// Returns a new image containing only the contents within the specified frame
  func cropped(to destFrame: NSRect) -> NSImage {
    let newImage = NSImage(size: destFrame.size)
    newImage.lockFocus()
    self.draw(
      in: NSRect(origin: NSPoint(x: 0, y: 0), size: destFrame.size),
      from: destFrame,
      operation: NSCompositingOperation.sourceOver,
      fraction: 1.0
    )
    newImage.unlockFocus()
    return newImage
  }

  /// Returns a crop of the center of the image of the specified size
  ///
  /// This function was originally authored to speed up preview rendering since only
  /// a small fraction of the desktop picture is visible through the preview's viewport.
  func cropped(to destSize: NSSize) -> NSImage {
    return cropped(to: NSRect(
      origin: NSPoint(
        x: floor((self.size.width - destSize.width) / 2),
        y: floor((self.size.height - destSize.height) / 2)
      ),
      size: destSize
    ))
  }
}
