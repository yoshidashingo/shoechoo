import SwiftUI
import UniformTypeIdentifiers
import os

extension UTType {
    static let markdown = UTType(exportedAs: "net.daringfireball.markdown")
}

final class MarkdownDocument: ReferenceFileDocument, @unchecked Sendable {
    typealias Snapshot = String

    // Set once during init, accessed only from @MainActor context (views, Coordinator).
    // nonisolated(unsafe) is required by ReferenceFileDocument protocol constraint (AC #9 exception).
    // Never access from nonisolated methods (snapshot, fileWrapper).
    nonisolated(unsafe) private(set) var viewModel: EditorViewModel

    static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    static var writableContentTypes: [UTType] { [.markdown] }

    private let snapshotStore = SnapshotStore()

    init() {
        // NSDocumentController may call init() from a background queue
        // ("NSDocumentController Opening"), so MainActor.assumeIsolated crashes.
        // DispatchQueue.main.sync is normally forbidden (deadlock risk), but this is
        // a necessary exception: synchronous init must produce a @MainActor object,
        // and the calling queue (NSDocumentController Opening) never holds main-queue lock.
        if Thread.isMainThread {
            self.viewModel = MainActor.assumeIsolated { EditorViewModel() }
        } else {
            self.viewModel = DispatchQueue.main.sync { EditorViewModel() }
        }
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        snapshotStore.write(text)
        // Same exception as init() — see comment above.
        if Thread.isMainThread {
            let vm = MainActor.assumeIsolated { EditorViewModel() }
            MainActor.assumeIsolated { vm.sourceText = text }
            self.viewModel = vm
        } else {
            self.viewModel = DispatchQueue.main.sync {
                let vm = EditorViewModel()
                vm.sourceText = text
                return vm
            }
        }
    }

    nonisolated func snapshot(contentType: UTType) throws -> String {
        snapshotStore.read()
    }

    nonisolated func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = snapshot.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    nonisolated func updateSnapshotText(_ text: String) {
        snapshotStore.write(text)
    }

    // MARK: - File URL

    // Set/read only from @MainActor context (EditorView, ShoechooTextView).
    // nonisolated(unsafe) required because class is @unchecked Sendable.
    nonisolated(unsafe) var fileURL: URL?

    func setFileURL(_ url: URL?) {
        fileURL = url
    }

    func assetsDirectoryURL() -> URL? {
        guard let fileURL else { return nil }
        return fileURL.deletingPathExtension().appendingPathExtension("assets")
    }

    func ensureAssetsDirectory() async throws -> URL {
        guard let assetsURL = assetsDirectoryURL() else {
            throw CocoaError(.fileWriteNoPermission)
        }
        try await FileService.shared.createDirectoryIfNeeded(at: assetsURL)
        return assetsURL
    }
}
