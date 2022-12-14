import SwiftUI

fileprivate var desktopImage = {
  NSImage(contentsOf: NSWorkspace.shared.desktopImageURL(for: NSScreen.main!)!)!
  .cropped(to: NSSize(width: 600, height: 600))
}()

func previewBackground() -> some View {
  GeometryReader { geometry in
    ZStack {
      Image(nsImage: desktopImage)
      ZStack {
        Rectangle()
        .fill(Color(NSColor.windowBackgroundColor))
        // swiftlint:disable line_length
        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum bibendum nulla quis tincidunt pharetra. Suspendisse mattis aliquet pharetra. Nulla molestie libero sodales, varius felis vel, ullamcorper ante. Donec cursus elit at neque efficitur vestibulum. Ut arcu enim, bibendum eget ex quis, vulputate porta ante. Praesent sed turpis ligula. Aenean id diam leo. Morbi sodales dolor ut elementum eleifend. Curabitur in quam nunc. \n\nSuspendisse potenti. In dapibus, diam id rhoncus facilisis, sem purus luctus odio, vitae elementum nisl urna id orci. Nunc mollis, erat nec pulvinar fermentum, quam ligula accumsan orci, nec scelerisque sem turpis at tortor. Pellentesque")
        // swiftlint:enable line_length
      }
      .frame(width: geometry.size.width / 2.0, height: geometry.size.height)
      .position(
        x: geometry.size.width / 4.0,
        y: geometry.size.height / 2
      )
    }
  }.frame(maxWidth: .infinity, maxHeight: .infinity)
}

struct BackgroundPreview: PreviewProvider {
  static var previews: some View {
    previewBackground()
  }
}
