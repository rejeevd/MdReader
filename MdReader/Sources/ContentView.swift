import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument

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
                MarkdownView(source: document.text)
            case .edit:
                TextEditor(text: $document.text)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
