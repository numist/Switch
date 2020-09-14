import SwiftUI
import Combine

private struct WindowView: View {
  @State var window: WindowInfoGroup
  // TODO: @ObservableObject WindowContents(for: WindowInfoGroup) publishes nsImage, conveniences view

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
    return Rectangle()
      .fill(Color(NSColor.windowFrameColor))
      .frame(
        width: window.cgFrame.size.width * scale,
        height: window.cgFrame.size.height * scale
      )
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        windowContents(for: window, in: geometry.size)
        appIcon(for: window.mainWindow.ownerBundleID, in: geometry.size / 2.0)
          .offset(
            x: min(geometry.size.width, geometry.size.height) / 4,
            y: min(geometry.size.width, geometry.size.height) / 4
          )
      }.frame(
        width: min(geometry.size.width, geometry.size.height),
        height: min(geometry.size.width, geometry.size.height)
      )
    }
  }
}

struct WindowViewPreview: PreviewProvider {
  static var previews: some View {
    let window = WindowInfoGroup.list(from: [
      // swiftlint:disable line_length
      WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.dt.Xcode", .canActivate: true, .isAppActive: false]),
      // swiftlint:enable line_length
    ]).first!
    return WindowView(window: window).frame(width: 256, height: 256)
  }
}

/* Full scale dimensions for SwitcherView:
 *
 *   8+3+8         3           8 8                128²
 * │◀────▶│       │↔│         │↔│↔│            │◀──────▶│
 * └ ┐  ┌ ┘       └─┘         | | |            |        |
 *   ┌─────────────┼──────────┼─┼─┼────────────┼────────┼──┬ ─ ─ ─ ─
 *   │  │          ┌────────────┐                          │       ▲
 *   │  ┌────────┐ │ ┌────────┤ │ ├────────┐   ├────────┤  │       │
 *   │  │        │ │ │        │ │ │        │   │        │  │       │
 *   │  │        │ │ │        │ │ │        │   │        │  │       │128 + 8×4 + 3×2
 *   │  │     .─.│ │ │     .─.│ │ │     .─.│   │     .─.├ ─│─ -    │= 166
 *   │  │    (   ) │ │    (   ) │ │    (   )   │    (   )  │  ↕64² │
 *   │  └─────`─'┘ │ └─────`─'┘ │ └─────`─'┘   └─────`─'┴ ─│─ -    │
 *   │             └────────────┘                          │       ▼
 *   └─────────────────────────────────────────────────────┴ ─ ─ ─ ─
 *   │◀───────────────────────────────────────────────────▶│
 *                128×n + 3×(n+1) + 8×((n+1)*2)
 *
 * window radius: 20
 * selection radius: 20(window radius) - 8(inset)
 */

struct SwitcherView: View {
  @ObservedObject var state: SwitcherState

  private func cellSize(given geometry: GeometryProxy) -> CGFloat {
    return min(geometry.size.width / CGFloat(state.windows.count), geometry.size.height)
  }

  var body: some View {
    GeometryReader { geometry in
      // TODO: scaling factor and ideal sizes for everything
      ZStack {
        // HUD background
        Rectangle()
        .fill(Color(NSColor.white).opacity(0.2))
        .cornerRadius(16.0)
        .frame(
          width: cellSize(given: geometry) * CGFloat(max(state.windows.count, 1)),
          height: cellSize(given: geometry)
        )

        // Window list
        HStack {
          ForEach(state.windows, id: \.self) { window in
            WindowView(window: window)
          }
        }

        // Selection frame
        if state.selection != nil {
          RoundedRectangle(cornerRadius: 10)
          .stroke(Color.white.opacity(0.7), lineWidth: 3)
          .frame(
            width: cellSize(given: geometry),
            height: cellSize(given: geometry)
          )
          // TODO: none of the measurements here are correct. there is so much arithmetic still to be done.
          .offset(x: (CGFloat(state.selection!) - (CGFloat(state.windows.count - 1) / 2.0)) * cellSize(given: geometry))
        }
      }
    }
  }
}

struct SwitcherViewPreviews: PreviewProvider {
  static var previews: some View {
    let packedState = SwitcherState()
    packedState.incrementSelection(by: 3)
    packedState.update(windows: WindowInfoGroup.list(from: [
      // swiftlint:disable line_length
      WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.dt.Xcode", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(510), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(1426), .cgOwnerName: "System Preferences", .cgName: "Security & Privacy", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0), .isFullscreen: false, .ownerBundleID: "com.apple.systempreferences", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(10053), .cgLayer: Int32(0), .cgBounds: CGRect(x: 61.0, y: 23.0, width: 1369.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(16649), .cgOwnerName: "TextMate", .cgName: "untitled 12", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 61.0, y: 0.0, width: 1369.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.macromates.TextMate", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(2179), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(3342), .cgOwnerName: "Safari", .cgName: "Fucking NSImage Syntax", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.Safari", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(5269), .cgLayer: Int32(0), .cgBounds: CGRect(x: 105.0, y: 67.0, width: 788.0, height: 781.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(16649), .cgOwnerName: "TextMate", .cgName: "untitled 11", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 105.0, y: 52.0, width: 788.0, height: 781.0), .isFullscreen: false, .ownerBundleID: "net.numist.Switch", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(79), .cgLayer: Int32(0), .cgBounds: CGRect(x: 168.0, y: 24.0, width: 1120.0, height: 839.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(424), .cgOwnerName: "Terminal", .cgName: "Switch — fish /Users/numist/Code/Switch — -fish — 185×56", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 168.0, y: 37.0, width: 1120.0, height: 839.0), .isFullscreen: false, .ownerBundleID: "com.apple.Terminal", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(9737), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(3342), .cgOwnerName: "Safari", .cgName: "swift - SwiftUI and MVVM - Communication between model and view model - Stack Overflow", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.example.unknowable", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(8336), .cgLayer: Int32(0), .cgBounds: CGRect(x: 72.0, y: 67.0, width: 1368.0, height: 757.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(30660), .cgOwnerName: "Monodraw", .cgName: "Untitled", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 72.0, y: 76.0, width: 1368.0, height: 757.0), .isFullscreen: false, .ownerBundleID: "com.helftone.monodraw", .canActivate: true, .isAppActive: false]),
      // swiftlint:enable line_length
    ]))

    let fullScaleState = SwitcherState()
    fullScaleState.incrementSelection(by: 2)
    fullScaleState.update(windows: WindowInfoGroup.list(from: [
      // swiftlint:disable line_length
      WindowInfo([.cgNumber: UInt32(100), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 1440.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(425), .cgOwnerName: "Xcode-beta", .cgName: "Switcher.swift", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: -0.0, y: 0.0, width: 1440.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.apple.dt.Xcode", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(510), .cgLayer: Int32(0), .cgBounds: CGRect(x: 0.0, y: 23.0, width: 668.0, height: 573.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(1426), .cgOwnerName: "System Preferences", .cgName: "Security & Privacy", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 0.0, y: 304.0, width: 668.0, height: 573.0), .isFullscreen: false, .ownerBundleID: "com.apple.systempreferences", .canActivate: true, .isAppActive: false]),
      WindowInfo([.cgNumber: UInt32(10053), .cgLayer: Int32(0), .cgBounds: CGRect(x: 61.0, y: 23.0, width: 1369.0, height: 877.0).dictionaryRepresentation, .cgAlpha: Float(1.0), .cgOwnerPID: Int32(16649), .cgOwnerName: "TextMate", .cgName: "untitled 12", .cgIsOnscreen: true, .cgDisplayID: UInt32(69732800), .nsFrame: NSRect(x: 61.0, y: 0.0, width: 1369.0, height: 877.0), .isFullscreen: false, .ownerBundleID: "com.macromates.TextMate", .canActivate: true, .isAppActive: false]),
      // swiftlint:enable line_length
    ]))

    let emptyState = SwitcherState()
    emptyState.incrementSelection()
    emptyState.update(windows: [])

    return Group {
      SwitcherView(state: packedState)
      SwitcherView(state: fullScaleState)
      SwitcherView(state: emptyState)
    }
  }
}
