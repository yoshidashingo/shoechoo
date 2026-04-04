import SwiftUI
import UniformTypeIdentifiers
import os

extension UTType {
    static let markdown = UTType(exportedAs: "net.daringfireball.markdown")
}

final class MarkdownDocument: ReferenceFileDocument, @unchecked Sendable {
    typealias Snapshot = String

    nonisolated(unsafe) var viewModel: EditorViewModel!

    static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    static var writableContentTypes: [UTType] { [.markdown] }

    nonisolated(unsafe) private let lock = NSLock()
    nonisolated(unsafe) private var _snapshotText: String = ""

    init() {
        if Thread.isMainThread {
            self.viewModel = MainActor.assumeIsolated { EditorViewModel() }
        } else {
            self.viewModel = DispatchQueue.main.sync {
                MainActor.assumeIsolated { EditorViewModel() }
            }
        }
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        _snapshotText = text
        if Thread.isMainThread {
            let vm = MainActor.assumeIsolated { EditorViewModel() }
            self.viewModel = vm
            MainActor.assumeIsolated { vm.sourceText = text }
        } else {
            let vm = DispatchQueue.main.sync {
                MainActor.assumeIsolated { EditorViewModel() }
            }
            self.viewModel = vm
            DispatchQueue.main.async {
                MainActor.assumeIsolated { vm.sourceText = text }
            }
        }
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
