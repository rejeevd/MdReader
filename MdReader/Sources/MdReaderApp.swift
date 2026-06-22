import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var store: EditorDocumentStore?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Handles Finder double-click / "Open With" on a .md file.
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        store?.open(url: url)
    }
}

@main
struct MdReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var store = EditorDocumentStore()

    var body: some Scene {
        Window("MdReader", id: "main") {
            ContentView(store: store)
                .onAppear { appDelegate.store = store }
        }
        .defaultSize(width: 1100, height: 800)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") { store.newFile() }
                    .keyboardShortcut("n", modifiers: .command)
                Button("Open...") { store.openFilePanel() }
                    .keyboardShortcut("o", modifiers: .command)
                Divider()
                Button("Close File") { store.closeFile() }
                    .keyboardShortcut("w", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save") { store.save() }
                    .keyboardShortcut("s", modifiers: .command)
                Button("Save As...") { store.saveAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}
