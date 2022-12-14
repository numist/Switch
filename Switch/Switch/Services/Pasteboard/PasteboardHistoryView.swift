import Foundation
import Combine
import SwiftUI

private struct PasteboardItemRow: View {
  @ObservedObject var item: PasteboardItem
  let index: Int?
  let selected: Bool

  var icon: NSImage {
    let workspace = NSWorkspace.shared
    if let path = workspace.urlForApplication(withBundleIdentifier: item.unwrappedAppBundle)?.path {
      return workspace.icon(forFile: path)
    }
    // TODO(numist): a default app icon doesn't seem to be available via API, copy a stand-in icns into the bundle
    return NSImage(named: NSImage.applicationIconName)!
  }

  var body: some View {
    Button(action: {
      print("\(item.unwrappedSnippet)")
    }, label: {
      HStack {
        Image(nsImage: icon).resizable().frame(width: 16, height: 16)
        Text(item.unwrappedSnippet.trimmingCharacters(in: .newlines)).lineLimit(1)
        Spacer()
        Text(index==nil ? "" : "⌘\(index!)").opacity(0.5)
      }
    })
    .buttonStyle(PlainButtonStyle())
  }
}

private struct ResultsList: View {
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
      predicate: query.isEmpty ? nil : NSPredicate(format: "snippet CONTAINS %@", query)
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
        }.frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        Text(selection==nil ? "" : items[selection!].snippet!)
          .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
      }.background(Color(NSColor.windowBackgroundColor)).cornerRadius(4)
    }
  }
}

private class Asdf: ObservableObject {
  var field = "" {
    didSet {
      subject.send(field)
    }
  }
  @Published var query = ""

  var subject = PassthroughSubject<String, Never>()
  var stream: AnyCancellable?

  init() {
    stream = subject
      .debounce(for: 0.25, scheduler: RunLoop.main)
      .sink(receiveValue: { [weak self] in self?.query = $0 })
  }
}

struct PasteboardHistoryView: View {
  @State fileprivate var asdf = Asdf()

  var body: some View {
    VStack(spacing: 6) {
      TextField("Filter…", text: $asdf.field)
        .lineLimit(1)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
        .cornerRadius(4)
      ResultsList(query: asdf.query)
        .environment(\.managedObjectContext, PasteboardHistory.persistentContainer.viewContext)
    }
    .padding(8)
    .background(
      Color(NSColor.underPageBackgroundColor)
        .opacity(0.9)
        .cornerRadius(10)
    )
  }
}

struct PasteboardHistoryView_Previews: PreviewProvider {
  static var previews: some View {
    return PasteboardHistoryView()
      .frame(width: 500, height: 400, alignment: .center)
      .environment(\.managedObjectContext, PasteboardHistory.persistentContainer.viewContext)
  }
}
