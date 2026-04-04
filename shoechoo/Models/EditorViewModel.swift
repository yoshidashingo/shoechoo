import AppKit

@Observable
@MainActor
final class EditorViewModel {
    var sourceText: String = ""
    var cursorPosition: Int = 0
    var isFocusModeEnabled: Bool
    var isTypewriterScrollEnabled: Bool
    var isIMEComposing: Bool = false
    var lastError: String?

    let settings: EditorSettings

    init(settings: EditorSettings = .shared) {
        self.settings = settings
        self.isFocusModeEnabled = settings.defaultFocusMode
        self.isTypewriterScrollEnabled = settings.defaultTypewriterScroll
    }

    func toggleBold() {
        toggleInlineFormatting(prefix: "**", suffix: "**")
    }

    func toggleItalic() {
        toggleInlineFormatting(prefix: "*", suffix: "*")
    }

    func toggleInlineCode() {
        toggleInlineFormatting(prefix: "`", suffix: "`")
    }

    func insertLink() {
        let template = "[](url)"
        insertText(template, cursorOffset: 1)
    }

    func setHeading(level: Int) {
        let prefix = String(repeating: "#", count: level) + " "
        setLinePrefix(prefix)
    }

    func toggleFocusMode() {
        isFocusModeEnabled.toggle()
    }

    func toggleTypewriterScroll() {
        isTypewriterScrollEnabled.toggle()
    }

    // MARK: - Statistics

    var wordCount: Int {
        let words = sourceText.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }

    var characterCount: Int {
        sourceText.count
    }

    var lineCount: Int {
        guard !sourceText.isEmpty else { return 0 }
        return sourceText.components(separatedBy: "\n").count
    }

    // MARK: - Export

    func exportHTML() async -> String {
        let service = ExportService.shared
        return await service.generateHTML(from: sourceText, title: "Document")
    }

    func exportPDF() async throws -> Data {
        let html = await exportHTML()
        return try await ExportService.shared.generatePDF(from: html)
    }

    // MARK: - Image Handling

    func insertImage(at position: Int, relativePath: String) {
        let markdown = "![](\(relativePath))"
        NotificationCenter.default.post(name: .insertImageMarkdown, object: nil, userInfo: [
            "markdown": markdown,
            "position": position
        ])
    }

    func handleImageDrop(urls: [URL], documentURL: URL?) async {
        guard let docURL = documentURL else { return }

        let assetsDir = docURL.deletingPathExtension().appendingPathExtension("assets")
        do {
            let relativePaths = try await ImageService.shared.importDroppedImage(from: urls, to: assetsDir)
            let assetsDirName = assetsDir.lastPathComponent
            for path in relativePaths {
                let fullRelative = "\(assetsDirName)/\(path)"
                insertImage(at: cursorPosition, relativePath: fullRelative)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearError() {
        lastError = nil
    }

    // MARK: - Private helpers

    private func toggleInlineFormatting(prefix: String, suffix: String) {
        NotificationCenter.default.post(name: .toggleFormatting, object: nil, userInfo: [
            "prefix": prefix,
            "suffix": suffix
        ])
    }

    private func insertText(_ text: String, cursorOffset: Int) {
        NotificationCenter.default.post(name: .insertFormattedText, object: nil, userInfo: [
            "text": text,
            "cursorOffset": cursorOffset
        ])
    }

    private func setLinePrefix(_ prefix: String) {
        NotificationCenter.default.post(name: .setLinePrefix, object: nil, userInfo: [
            "prefix": prefix
        ])
    }
}

extension Notification.Name {
    static let toggleFormatting = Notification.Name("shoechoo.toggleFormatting")
    static let insertFormattedText = Notification.Name("shoechoo.insertFormattedText")
    static let setLinePrefix = Notification.Name("shoechoo.setLinePrefix")
    static let insertImageMarkdown = Notification.Name("shoechoo.insertImageMarkdown")
}
