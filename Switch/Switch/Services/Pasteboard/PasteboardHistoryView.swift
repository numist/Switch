import Foundation
import Combine
import SwiftUI

private struct PasteboardItemRow: View {
  @ObservedObject var item: PasteboardItem
  let index: Int?
  let selected: Bool

  var icon: NSImage {
    let workspace = NSWorkspace.shared
    if let path = workspace.absolutePathForApplication(withBundleIdentifier: item.unwrappedAppBundle) {
      return workspace.icon(forFile: path)
    }
    // TODO(numist): a default app icon doesn't seem to be available via API, copy a stand-in icns into the bundle
    return NSImage(named: NSImage.applicationIconName)!
  }

  var body: some View {
    HStack {
      Image(nsImage: icon).resizable().frame(width: 16, height: 16)
      Text(item.unwrappedSnippet.trimmingCharacters(in: .newlines)).lineLimit(1)
      Spacer()
      Text(index==nil ? "" : "⌘\(index!)").opacity(0.5)
    }
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
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9)).cornerRadius(4)
      HStack {
        List(selection: $selection) {
          ForEach(items.indices, id: \.self) { index in
            PasteboardItemRow(
              item: items[index],
              index: (index < 10 ? (index + 1) % 10 : nil),
              selected: index == selection
            )
          }
        }.frame(minWidth: 0, maxWidth: .infinity)
        Text(selection==nil ? "" : items[selection!].snippet!)
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
          .padding(5)
      }.background(Color(NSColor.windowBackgroundColor)).cornerRadius(4)
    }.padding(8).background(Color(NSColor.underPageBackgroundColor).opacity(0.9).cornerRadius(10))
  }
}

struct PasteboardHistoryView_Previews: PreviewProvider {
  static var previews: some View {
    // Ensure the Core Data stack is loaded before the FetchRequest is initialized
    _ = PasteboardHistory.persistentContainer

    return PasteboardHistoryView()
      .environment(\.managedObjectContext, PasteboardHistory.persistentContainer.viewContext)
  }
}
