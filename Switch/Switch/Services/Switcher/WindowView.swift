import SwiftUI

struct WindowView: View {
  @State var window: WindowInfoGroup
  // TODO(numist): @ObservableObject WindowContents(for: WindowInfoGroup) publishes nsImage, conveniences view
  // Might wind up creating a Big Cache for these images to improve liveness

  func appIcon(for bundleID: String?, in size: CGSize) -> some View {
    let workspace = NSWorkspace.shared
    let nsImage: NSImage
    if let bid = bundleID, let path = workspace.absolutePathForApplication(withBundleIdentifier: bid) {
      nsImage = workspace.icon(forFile: path)
    } else {
      // TODO(numist): a default app icon doesn't seem to be available via API? copy a stand-in icns into the bundle
      nsImage = NSImage(named: NSImage.applicationIconName)!
    }
    let scale = min(
      size.width / nsImage.size.width,
      size.height / nsImage.size.height
    )
    nsImage.size = CGSize(
      width: nsImage.size.width * scale,
      height: nsImage.size.height * scale
    )
    return Image(nsImage: nsImage)
  }

  func windowContents(for window: WindowInfoGroup, in size: CGSize) -> some View {
    let scale = min(
      size.width / window.cgFrame.size.width,
      size.height / window.cgFrame.size.height
    )
    let width = window.cgFrame.size.width * scale
    let height = window.cgFrame.size.height * scale

    return Rectangle()
      .redacted(reason: .placeholder)
      .frame(width: width, height: height)
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        windowContents(
          for: window,
          in: CGSize(
            width: min(geometry.size.width, geometry.size.height),
            height: min(geometry.size.width, geometry.size.height)
          )
        )
        appIcon(for: window.mainWindow.ownerBundleID, in: geometry.size / 2.0)
          .offset(
            x: min(geometry.size.width, geometry.size.height) / 4,
            y: min(geometry.size.width, geometry.size.height) / 4
          )
      }.frame(
        width: min(geometry.size.width, geometry.size.height),
        height: min(geometry.size.width, geometry.size.height)
      ).offset(
        x: (geometry.size.width - min(geometry.size.width, geometry.size.height)) / 2,
        y: (geometry.size.height - min(geometry.size.width, geometry.size.height)) / 2)
    }
  }
}

struct WindowViewPreview: PreviewProvider {
  static var previews: some View {
    // swiftlint:disable line_length
    return Group {
      WindowView(window: WindowInfoGroup.list(from: [
        WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.dt.Xcode", .canActivate: true, .isAppActive: false]),
      ]).first!)
      .frame(width: 256, height: 256)
      .background(previewBackground())

      WindowView(window: WindowInfoGroup.list(from: [
        WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 484.0, height: 168.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 484.0, height: 168.0), .isFullscreen: false, .ownerBundleID: "net.numist.Switch", .canActivate: true, .isAppActive: false]),
      ]).first!)
      .frame(width: 512, height: 128)
      .background(previewBackground())

      WindowView(window: WindowInfoGroup.list(from: [
        WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 877.0, height: 1440.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 877.0, height: 1440.0), .isFullscreen: false, .ownerBundleID: "com.example.NoSuch", .canActivate: true, .isAppActive: false]),
      ]).first!)
      .frame(width: 128, height: 256)
      .background(previewBackground())
    }
    // swiftlint:enable line_length
  }
}
