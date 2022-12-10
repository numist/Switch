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
private let pItemSz = pThumbSz + pThumbPad + pSelThck + pSelPad
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
  @State private var hoverLocation: CGPoint = .zero
  let displayID: CGDirectDisplayID?

  init(with state: SwitcherState, on displayID: CGDirectDisplayID? = nil) {
    assert(displayID == nil) // TODO(numist): multimon support
    self.state = state
    self.displayID = displayID
  }

  private func cellSize(given geometry: GeometryProxy) -> CGFloat {
    return min(geometry.size.width / CGFloat(state.windows.count), geometry.size.height)
  }

  private func middleIndex(for index: Int) -> CGFloat {
    return (CGFloat(index) - (CGFloat(state.windows.count - 1) / 2.0))
  }

  private func hud(at scale: CGFloat) -> some View {
    Rectangle()
    .fill(Color(NSColor.shadowColor).opacity(0.25))
    .cornerRadius(pWinRadius * scale)
    .frame(
      width: pWidth(for: state.windows.count) * scale,
      height: pHeight * scale
    )
    .animation(.default, value: state.windows)
  }

  private func selectionBox(at scale: CGFloat) -> some View {
    ZStack { // can't fill *and* stroke a Shape!
      RoundedRectangle(cornerRadius: pSelRadius * scale)
      .fill(Color(NSColor.shadowColor).opacity(0.5))
      .frame(
        width: (pThumbSz + pThumbPad + pThumbPad) * scale,
        height: (pThumbSz + pThumbPad + pThumbPad) * scale
      )
      RoundedRectangle(cornerRadius: pSelRadius * scale)
      .stroke(Color.white.opacity(0.7), lineWidth: pSelThck * scale)
      .frame(
        width: (pThumbSz + pThumbPad + pThumbPad + pSelThck) * scale,
        height: (pThumbSz + pThumbPad + pThumbPad + pSelThck) * scale
      )
    }
    .offset(
      x: middleIndex(for: state.selection!) * scale * pItemSz
    )
    .animation(.easeInOut.speed(2), value: state.selection)
  }

  var body: some View {
    GeometryReader { geometry in
      let scale = scalingFactor(for: state.windows.count, in: geometry)
      ZStack {
        // HUD/background
        hud(at: scale)

        // Selection frame
        if state.selection != nil {
          selectionBox(at: scale)
        }

        // Window list
        ForEach(Array(state.windows.enumerated()), id: \.element) { index, window in
          WindowView(window: window)
          .onContinuousHover { phase in
            // The selection state should only change when the mouse moves within a view
            // This is important in case the Switcher happens to get invoked
            // while the cursor is idling within the view's bounds
            switch phase {
            case .active(let location):
              if hoverLocation != .zero && state.selection != index {
                state.setSelection(to: window)
              }
              hoverLocation = location
            case .ended:
              hoverLocation = .zero
            }
          }
          .frame(
            width: pThumbSz * scale,
            height: pThumbSz * scale
          )
          .offset(
            x: middleIndex(for: index) * scale *
               (pThumbSz + pThumbPad + pSelThck + pSelPad)
          )
          .animation(.default.speed(2), value: state.windows)
        }
      }
      .position(
        x: geometry.size.width / 2,
        y: geometry.size.height / 2
      )
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
      SwitcherView(with: packedState)
      .frame(width: 588.0, height: 128.0)
      .background(previewBackground())

      SwitcherView(with: fullScaleState)
      .frame(width: 588.0, height: 200.0)
      .background(previewBackground())

      SwitcherView(with: emptyState)
      .frame(width: 588.0, height: 200.0)
      .background(previewBackground())
    }
  }
}
