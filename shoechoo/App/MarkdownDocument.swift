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
            // NSDocumentController can call init from background thread (#81)
            // viewModel stays nil; updateNSView will initialize it on main thread
            self.viewModel = nil
            DispatchQueue.main.async { [self] in
                MainActor.assumeIsolated {
                    self.viewModel = EditorViewModel()
                }
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
            // NSDocumentController can call init(configuration:) from background thread (#81)
            self.viewModel = nil
            let savedText = text
            DispatchQueue.main.async { [self] in
                MainActor.assumeIsolated {
                    let vm = EditorViewModel()
                    vm.sourceText = savedText
                    self.viewModel = vm
                }
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
