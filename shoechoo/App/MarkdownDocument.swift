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

    private let lock = NSLock()
    nonisolated(unsafe) private var _snapshotText: String = ""

    init() {
        // SwiftUI DocumentGroup always calls init on MainActor
        self.viewModel = MainActor.assumeIsolated { EditorViewModel() }
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        _snapshotText = text  // No lock needed during init — no concurrent access
        // SwiftUI DocumentGroup calls init(configuration:) on MainActor
        let vm = MainActor.assumeIsolated { EditorViewModel() }
        MainActor.assumeIsolated { vm.sourceText = text }
        self.viewModel = vm
    }

    nonisolated func snapshot(contentType: UTType) throws -> String {
        lock.withLock { _snapshotText }
    }

    nonisolated func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = snapshot.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    nonisolated func updateSnapshotText(_ text: String) {
        lock.withLock { _snapshotText = text }
    }

    // MARK: - File URL

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
