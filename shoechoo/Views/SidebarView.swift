import SwiftUI

enum SidebarMode: String, CaseIterable {
    case outline = "Outline"
    case fileTree = "File Tree"
    case fileList = "File List"

    var icon: String {
        switch self {
        case .outline: return "list.bullet.indent"
        case .fileTree: return "folder"
        case .fileList: return "doc.text"
        }
    }
}

struct SidebarContainerView: View {
    @Bindable var viewModel: EditorViewModel
    var documentURL: URL?
    @State private var mode: SidebarMode = .outline
    @State private var folderURL: URL?

    var body: some View {
        VStack(spacing: 0) {
            // Mode selector
            HStack(spacing: 2) {
                ForEach(SidebarMode.allCases, id: \.self) { m in
                    Button(action: { mode = m }) {
                        Image(systemName: m.icon)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(mode == m ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .help(m.rawValue)
                    .accessibilityIdentifier("sidebar.mode.\(m.rawValue.lowercased().replacingOccurrences(of: " ", with: ""))")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Content
            switch mode {
            case .outline:
                OutlineView(viewModel: viewModel)
            case .fileTree:
                FileTreeView(rootURL: folderURL)
            case .fileList:
                FileListView(folderURL: folderURL)
            }
        }
        .accessibilityIdentifier("sidebar.container")
        .onAppear { resolveFolder() }
        .onChange(of: documentURL) { resolveFolder() }
    }

    private func resolveFolder() {
        if let docURL = documentURL {
            folderURL = docURL.deletingLastPathComponent()
        }
    }
}

// MARK: - File Tree View

struct FileTreeView: View {
    var rootURL: URL?
    @State private var entries: [FileEntry] = []
    @State private var expandedFolders: Set<URL> = []

    var body: some View {
        List {
            if let root = rootURL {
                Section(root.lastPathComponent) {
                    ForEach(entries) { entry in
                        FileTreeRow(entry: entry, expandedFolders: $expandedFolders)
                    }
                }
            } else {
                Text("No folder")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .listStyle(.sidebar)
        .onAppear { loadEntries() }
        .onChange(of: rootURL) { loadEntries() }
    }

    private func loadEntries() {
        guard let root = rootURL else { entries = []; return }
        entries = scanFolder(root, depth: 0)
    }

    private func scanFolder(_ url: URL, depth: Int) -> [FileEntry] {
        guard depth < 5 else { return [] }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let sorted = contents.sorted { a, b in
            let aDir = (try? a.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let bDir = (try? b.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if aDir != bDir { return aDir }
            return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
        }

        var result: [FileEntry] = []
        for item in sorted {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            let ext = item.pathExtension.lowercased()
            if isDir {
                let children = expandedFolders.contains(item) ? scanFolder(item, depth: depth + 1) : []
                result.append(FileEntry(url: item, isDirectory: true, depth: depth, children: children))
            } else if ["md", "markdown", "txt", "text"].contains(ext) {
                result.append(FileEntry(url: item, isDirectory: false, depth: depth, children: []))
            }
        }
        return result
    }
}

struct FileEntry: Identifiable {
    let id = UUID()
    let url: URL
    let isDirectory: Bool
    let depth: Int
    let children: [FileEntry]
}

struct FileTreeRow: View {
    let entry: FileEntry
    @Binding var expandedFolders: Set<URL>

    var body: some View {
        if entry.isDirectory {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedFolders.contains(entry.url) },
                    set: { expanded in
                        if expanded { expandedFolders.insert(entry.url) }
                        else { expandedFolders.remove(entry.url) }
                    }
                )
            ) {
                ForEach(entry.children) { child in
                    FileTreeRow(entry: child, expandedFolders: $expandedFolders)
                }
            } label: {
                Label(entry.url.lastPathComponent, systemImage: "folder")
                    .lineLimit(1)
            }
        } else {
            Button(action: { openFile(entry.url) }) {
                Label(entry.url.lastPathComponent, systemImage: "doc.text")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    private func openFile(_ url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
    }
}

// MARK: - File List View

struct FileListView: View {
    var folderURL: URL?
    @State private var files: [URL] = []

    var body: some View {
        List {
            if files.isEmpty {
                Text("No markdown files")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                ForEach(files, id: \.self) { url in
                    Button(action: { openFile(url) }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.deletingPathExtension().lastPathComponent)
                                .font(.body)
                                .lineLimit(1)
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .onAppear { loadFiles() }
        .onChange(of: folderURL) { loadFiles() }
    }

    private func loadFiles() {
        guard let folder = folderURL else { files = []; return }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { files = []; return }

        files = contents
            .filter { ["md", "markdown", "txt", "text"].contains($0.pathExtension.lowercased()) }
            .sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return d1 > d2
            }
    }

    private func openFile(_ url: URL) {
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
    }
}
