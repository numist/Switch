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

private struct ResultsList: View {
  @Environment(\.managedObjectContext) var context

  var fetchRequest: FetchRequest<PasteboardItem>
  var items: FetchedResults<PasteboardItem> { fetchRequest.wrappedValue }

  // Still some problems around selected state being drawn in the list but this property wrapping appears to be
  // effective at preventing out of bounds crashes when `items` shrinks
  @State private var _selection: Int?
  private var selection: Int? {
    if let sel = _selection, sel >= items.count {
      if items.isEmpty {
        return nil
      }
      return min(sel, items.count - 1)
    }
    return _selection
  }

  init(query: String) {
    fetchRequest = FetchRequest(
      sortDescriptors: [NSSortDescriptor(keyPath: \PasteboardItem.lastUsed, ascending: false)],
      predicate: query.isEmpty ? nil : NSPredicate(format: "snippet LIKE %@", "*\(query)*")
    )
    // TODO(numist): selection = (items.isEmpty ? nil : 0), but
    // EXC_BAD_INSTRUCTION (code=EXC_I386_INVOP, subcode=0x0) in fetchRequest.wrappedValue
  }

  var body: some View {
    VStack(spacing: 6) {
      HStack {
        List(selection: $_selection) {
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

struct PasteboardHistoryView: View {
  @Environment(\.managedObjectContext)
  var context

  @State private var query = ""

  var body: some View {
    VStack(spacing: 6) {
      TextField("Filter…", text: $query)
        .lineLimit(1)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .cornerRadius(4)
        .padding(.horizontal, 8)
      ResultsList(query: query)
    }.padding(8).background(Color(NSColor.underPageBackgroundColor).opacity(0.9).cornerRadius(10))
  }
}

struct PasteboardHistoryView_Previews: PreviewProvider {
  static var previews: some View {
    return PasteboardHistoryView()
      .frame(width: 500, height: 400, alignment: .center)
      .environment(\.managedObjectContext, PasteboardHistory.persistentContainer.viewContext)
  }
}
