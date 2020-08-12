import Foundation
import Combine
import SwiftUI

struct PasteboardItemView: View {
  @ObservedObject var item: PasteboardItem
  let index: Int?
  let selected: Bool

  var icon: NSImage {
    let workspace = NSWorkspace.shared
    if let path = workspace.absolutePathForApplication(withBundleIdentifier: item.unwrappedAppBundle) {
      return workspace.icon(forFile: path)
    }
    // TODO(numist): default app icon doesn't seem to be available via API, may have to copy an icns into the bundle
    return NSImage(named: NSImage.applicationIconName)!
  }

  var body: some View {
    HStack {
      Image(nsImage: icon)
        .resizable()
        .frame(
          width: NSFont.systemFontSize,
          height: NSFont.systemFontSize
        )
      Text(
        item.unwrappedSnippet
          .trimmingCharacters(in: .newlines)
          .replacingOccurrences(of: "\t", with: "⇥")
      )
        .lineLimit(1)
      Spacer()
      Text(index==nil ? "" : "⌘\(index!)")
        .opacity(0.5)
    }
    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)

  }
}

struct PasteboardHistoryView: View {
  @Environment(\.managedObjectContext)
  var context

  @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \PasteboardItem.lastUsed, ascending: false)])
  var items: FetchedResults<PasteboardItem>

  @State private var query = ""
  @State private var selection: Int?

  var body: some View {
    VStack(spacing: 6) {
      TextField("Filter…", text: $query)
        .lineLimit(1)
        .textFieldStyle(RoundedBorderTextFieldStyle())
      HStack {
        List(selection: $selection) {
          ForEach(items.indices, id: \.self) { index in
            PasteboardItemView(
              item: items[index],
              index: (index < 10 ? (index + 1) % 10 : nil),
              selected: index == selection
            )
          }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        Text(selection==nil ? "" : items[selection!].snippet!)
          .allowsTightening(false)
          .lineSpacing(3.0)
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
          .padding(5)
      }.cornerRadius(6)
    }.padding(10).cornerRadius(16)
  }
}

struct PasteboardHistoryView_Previews: PreviewProvider {
  static var previews: some View {
    _ = PasteboardHistory.persistentContainer

    return PasteboardHistoryView()
      .environment(\.managedObjectContext, PasteboardHistory.persistentContainer.viewContext)
  }
}
