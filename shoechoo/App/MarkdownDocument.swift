import SwiftUI
import UniformTypeIdentifiers
import os

extension UTType {
    static let markdown = UTType(exportedAs: "net.daringfireball.markdown")
}

final class MarkdownDocument: ReferenceFileDocument, @unchecked Sendable {
    typealias Snapshot = String

    @MainActor var viewModel: EditorViewModel!

    static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    static var writableContentTypes: [UTType] { [.markdown] }

    private let lock = NSLock()
    private var _snapshotText: String = ""

    init() {
        self.viewModel = MainActor.assumeIsolated { EditorViewModel() }
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        _snapshotText = text
        let vm = MainActor.assumeIsolated { EditorViewModel() }
        self.viewModel = vm
        Task { @MainActor in
            vm.sourceText = text
            vm.textDidChange(text, editedRange: NSRange(location: 0, length: text.count))
        }
    }

    func snapshot(contentType: UTType) throws -> String {
        lock.withLock { _snapshotText }
    }

    func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = snapshot.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return FileWrapper(regularFileWithContents: data)
    }

    func updateSnapshotText(_ text: String) {
        lock.withLock { _snapshotText = text }
    }

    // MARK: - Assets Directory

    private var _fileURL: URL?

    func setFileURL(_ url: URL?) {
        _fileURL = url
    }

    func assetsDirectoryURL() -> URL? {
        guard let fileURL = _fileURL else { return nil }
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
