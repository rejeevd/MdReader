import SwiftUI

@main
struct MdReaderApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { configuration in
            ContentView(document: configuration.$document)
        }
        .defaultSize(width: 1100, height: 800)
    }
}
