import SwiftUI
import Combine

struct SwitcherView: View {
  let windowPublisher = Timer.publish(every: 1, on: .current, in: .common)
    .autoconnect()
    .map({ _ in
      WindowInfoGroup.list(from: WindowInfo.get())
    })
    .removeDuplicates()

  @State var windows = WindowInfoGroup.list(from: WindowInfo.get())

  var body: some View {
    HStack(spacing: 6) {
      ForEach(windows, id: \.self) { window in
        Text("\(window.mainWindow.name ?? "unknown")")
      }
    }.onReceive(windowPublisher, perform: { newValue in
      windows = newValue
    })
    .padding(8)
    .background(Color(NSColor.underPageBackgroundColor).opacity(0.9).cornerRadius(10))
  }
}

struct SwitcherView_Previews: PreviewProvider {
  static var previews: some View {
    return SwitcherView()
  }
}
