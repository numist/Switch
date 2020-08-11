import Foundation
import Combine
import SwiftUI

struct PasteboardItemView: View {
  let index: Int?
  let selected: Bool
  let bundleID: String
  let snippet: String

  var icon: NSImage {
    let workspace = NSWorkspace.shared
    if let path = workspace.absolutePathForApplication(withBundleIdentifier: bundleID) {
      return workspace.icon(forFile: path)
    }
    // TODO(numist): default app icon doesn't seem to be available via API, may have to copy the icns into the bundle
    return NSImage(named: NSImage.applicationIconName)!
  }

  var body: some View {
    HStack {
      Image(nsImage: icon)
        .resizable()
        .frame(width: 16.0, height: 16.0)
      Text(
        snippet
          .trimmingCharacters(in: .newlines)
          .replacingOccurrences(of: "\t", with: "⇥")
      )
        .lineLimit(1)
        .font(.system(size: 16, design: .default))
      Spacer()
      Text(index==nil ? "" : "⌘\(index!)")
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)

  }
}

struct PasteboardHistoryView: View {
  @State var query = ""
  @State private var selection: Int?
  @State var items: [PasteboardItem]

  let isFocused = true

  var body: some View {
    VStack(spacing: 6) {
      TextField("Filter…", text: $query)
        .lineLimit(1)
        .font(.system(size: 20, design: .default))
        .textFieldStyle(RoundedBorderTextFieldStyle())
      HStack {
        List(selection: $selection) {
          ForEach(items.indices) { index in
            PasteboardItemView(
              index: (index < 9 ? index + 1 : nil),
              selected: index == selection,
              bundleID: items[index].appBundle,
              snippet: items[index].snippet
            )
          }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        Text(selection==nil ? "" : items[selection!].snippet)
          .allowsTightening(false)
          .lineSpacing(3.0)
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
      }.cornerRadius(6)
    }.padding(10).cornerRadius(16)
  }
}

struct PasteboardHistoryView_Previews: PreviewProvider {
  static var previews: some View {
    PasteboardHistoryView(items: PasteboardHistory().getItems(for: ""))
  }
}
