import SwiftUI

struct ContentView: View {
    @ObservedObject var store: EditorDocumentStore

    enum Tab: String, CaseIterable, Identifiable {
        case view = "View"
        case edit = "Edit"
        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .view

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
            .padding(.top, 10)
            .padding(.bottom, 8)

            Divider()

            switch selectedTab {
            case .view:
                MarkdownView(source: store.text)
            case .edit:
                TextEditor(text: Binding(
                    get: { store.text },
                    set: { store.text = $0; store.textDidChange() }
                ))
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .navigationTitle(store.displayName)
    }
}
