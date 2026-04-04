import SwiftUI

struct SidebarView: View {
    @State private var recentFiles: [URL] = []

    var body: some View {
        List {
            Section("Recent Files") {
                if recentFiles.isEmpty {
                    Text("No recent files")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(recentFiles, id: \.self) { url in
                        Button(action: { openFile(url) }) {
                            Label(url.lastPathComponent, systemImage: "doc.text")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 220)
        .onAppear { loadRecentFiles() }
    }

    private func loadRecentFiles() {
        recentFiles = NSDocumentController.shared.recentDocumentURLs
    }

    private func openFile(_ url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
    }
}
