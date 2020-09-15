import SwiftUI

/* Full scale dimensions for SwitcherView:
 *
 *   8+4+8         4           8 8  128(²)
 * │◀────▶│       │↔│         │↔│↔│◀──────▶│
 * └ ┐  ┌ ┘       └─┘         | | |        |
 *   ┌─────────────┼──────────┼─┼─┼────────┼───────────────┬ ─ ─ ─ ─
 *   │  │          ┌────────────┐                          │       ▲
 *   │  ┌────────┐ │ ┌────────┤ │ ├────────┤   ┌────────┐  │       │
 *   │  │        │ │ │        │ │ │        │   │        │  │       │
 *   │  │        │ │ │        │ │ │        │   │        │  │       │128+8×4+4×2
 *   │  │     .─.│ │ │     .─.│ │ │     .─.│   │     .─.├ ─│─      │= 168
 *   │  │    (   ) │ │    (   ) │ │    (   )   │    (   )  │↕64(²) │
 *   │  └─────`─'┘ │ └─────`─'┘ │ └─────`─'┘   └─────`─'┴ ─│─      │
 *   │             └────────────┘                          │       ▼
 *   └─────────────────────────────────────────────────────┴ ─ ─ ─ ─
 *   │◀───────────────────────────────────────────────────▶│
 *                128×n + 4×(n+1) + 8×((n+1)*2)
 *
 * window radius: 20
 * selection radius: 20(window radius) - 8(inset)
 */

private let pThumbSz = CGFloat(128.0)
private let pThumbPad = CGFloat(8.0)
private let pSelThck = CGFloat(4.0)
private let pSelPad = CGFloat(8.0)
private let pHeight = (pThumbPad + pSelThck + pSelPad) * 2.0 + pThumbSz
private let pWinRadius = CGFloat(20.0)
private let pSelRadius = pWinRadius - pSelPad
private func pWidth(for count: Int) -> CGFloat {
  let cgn = CGFloat(max(count, 1))
  return pThumbSz * cgn + (pThumbPad + pSelThck + pSelPad) * (cgn + CGFloat(1.0))
}
private func scalingFactor(for count: Int, in geometry: GeometryProxy) -> CGFloat {
  min(
    geometry.size.width / pWidth(for: count),
    geometry.size.height / pHeight,
    1.0
  )
}

struct SwitcherView: View {

  @ObservedObject var state: SwitcherState

  private func cellSize(given geometry: GeometryProxy) -> CGFloat {
    return min(geometry.size.width / CGFloat(state.windows.count), geometry.size.height)
  }

  private func middleIndex(for index: Int) -> CGFloat {
    return (CGFloat(index) - (CGFloat(state.windows.count - 1) / 2.0))
  }

  private func hud(at scale: CGFloat) -> some View {
    Rectangle()
    .fill(Color(NSColor.shadowColor).opacity(0.8))
    .cornerRadius(pWinRadius * scale)
    .frame(
      width: pWidth(for: state.windows.count) * scale,
      height: pHeight * scale
    )
  }

  private func selectionBox(at scale: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: pSelRadius * scale)
    .stroke(Color.white.opacity(0.7), lineWidth: pSelThck * scale)
    // TODO: none of the measurements here are correct. there is so much arithmetic still to be done.
    .frame(
      width: (pThumbSz + pThumbPad + pThumbPad + pSelThck) * scale,
      height: (pThumbSz + pThumbPad + pThumbPad + pSelThck) * scale
    )
    .offset(
      x: middleIndex(for: state.selection!) * scale *
        (pThumbSz + pThumbPad + pSelThck + pSelPad)
    )
  }

  var body: some View {
    GeometryReader { geometry in
      let scale = scalingFactor(for: state.windows.count, in: geometry)
      ZStack {
        // HUD/background
        hud(at: scale)

        // Window list
        ForEach(Array(state.windows.enumerated()), id: \.element) { index, window in
          WindowView(window: window)
          .frame(
            width: pThumbSz * scale,
            height: pThumbSz * scale
          )
          .offset(
            x: middleIndex(for: index) * scale *
               (pThumbSz + pThumbPad + pSelThck + pSelPad)
          )
          // TODO: onHover? something like:
//          .onHover { inside in
//            if inside {
//              state.incrementSelection(by: index - state.selection!)
//            }
//          }
        }

        // Selection frame
        // TODO: animate!?
        // REF: .onReceive per https://stackoverflow.com/a/62211888?
        if state.selection != nil {
          selectionBox(at: scale)
        }
      }
    }
  }
}

struct SwitcherViewPreviews: PreviewProvider {

  private static var desktopImage = {
    NSImage(contentsOf: NSWorkspace.shared.desktopImageURL(for: NSScreen.main!)!)!
  }()
  private static func desktop() -> some View {
    GeometryReader { geometry in
      ZStack {
        Image(nsImage: desktopImage)
        Rectangle()
        .fill(Color(NSColor.windowBackgroundColor))
        .frame(width: geometry.size.width / 2.0, height: geometry.size.height)
        .offset(x: geometry.size.width / 4.0)
        // swiftlint:disable line_length
        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum bibendum nulla quis tincidunt pharetra. Suspendisse mattis aliquet pharetra. Nulla molestie libero sodales, varius felis vel, ullamcorper ante. Donec cursus elit at neque efficitur vestibulum. Ut arcu enim, bibendum eget ex quis, vulputate porta ante. Praesent sed turpis ligula. Aenean id diam leo. Morbi sodales dolor ut elementum eleifend. Curabitur in quam nunc. \n\nSuspendisse potenti. In dapibus, diam id rhoncus facilisis, sem purus luctus odio, vitae elementum nisl urna id orci. Nunc mollis, erat nec pulvinar fermentum, quam ligula accumsan orci, nec scelerisque sem turpis at tortor. Pellentesque")
        // swiftlint:enable line_length
        .frame(width: geometry.size.width / 2.0, height: geometry.size.height)
        .offset(x: geometry.size.width / 4.0)
      }
    }
  }

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
    fullScaleState.incrementSelection(by: 0)
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
      if #available(OSX 11.0, *) {
        SwitcherView(state: packedState)
        .preferredColorScheme(.light)
        .frame(width: 588.0, height: 128.0)
        .background(desktop())

        SwitcherView(state: packedState)
        .preferredColorScheme(.dark)
        .frame(width: 588.0, height: 128.0)
        .background(desktop())
      } else {
        SwitcherView(state: packedState)
        .frame(width: 588.0, height: 128.0)
        .background(desktop())
      }

      SwitcherView(state: fullScaleState)
      .frame(width: 588.0, height: 200.0)
      .background(desktop())

      SwitcherView(state: emptyState)
      .frame(width: 588.0, height: 200.0)
      .background(desktop())
    }
  }
}