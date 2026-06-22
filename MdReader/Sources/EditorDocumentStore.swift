import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Manages the single currently-open file for the app. There is exactly one
/// editable document at a time; opening, closing, or creating a new file all
/// operate on this shared store rather than spawning additional windows.
final class EditorDocumentStore: ObservableObject {
    @Published var text: String = ""
    @Published var fileURL: URL?
    @Published var isEdited: Bool = false

    private var lastSavedText: String = ""

    var displayName: String {
        fileURL?.lastPathComponent ?? "Untitled"
    }

    func textDidChange() {
        isEdited = (text != lastSavedText)
    }

    func newFile() {
        guard confirmDiscardIfNeeded(actionDescription: "create a new file") else { return }
        fileURL = nil
        text = ""
        lastSavedText = ""
        isEdited = false
    }

    func closeFile() {
        guard confirmDiscardIfNeeded(actionDescription: "close this file") else { return }
        fileURL = nil
        text = ""
        lastSavedText = ""
        isEdited = false
    }

    func openFilePanel() {
        guard confirmDiscardIfNeeded(actionDescription: "open another file") else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if let markdownType = UTType(filenameExtension: "md") {
            panel.allowedContentTypes = [markdownType, .plainText]
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url: url)
    }

    func open(url: URL) {
        guard let data = try? Data(contentsOf: url), let contents = String(data: data, encoding: .utf8) else {
            presentError("Couldn't open \"\(url.lastPathComponent)\". It may not be a readable text file.")
            return
        }
        fileURL = url
        text = contents
        lastSavedText = contents
        isEdited = false
    }

    func save() {
        guard let url = fileURL else {
            saveAs()
            return
        }
        write(to: url)
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md") ?? .plainText]
        panel.nameFieldStringValue = fileURL?.lastPathComponent ?? "Untitled.md"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        write(to: url)
    }

    private func write(to url: URL) {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            lastSavedText = text
            isEdited = false
        } catch {
            presentError("Couldn't save \"\(url.lastPathComponent)\": \(error.localizedDescription)")
        }
    }

    @discardableResult
    private func confirmDiscardIfNeeded(actionDescription: String) -> Bool {
        guard isEdited else { return true }
        let alert = NSAlert()
        alert.messageText = "You have unsaved changes in \"\(displayName)\"."
        alert.informativeText = "Do you want to save your changes before you \(actionDescription)?"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            save()
            return !isEdited
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    private func presentError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Error"
        alert.informativeText = message
        alert.runModal()
    }
}
