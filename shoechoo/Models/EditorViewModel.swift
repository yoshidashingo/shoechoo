import AppKit

struct HeadingItem: Identifiable, Sendable {
    let id = UUID()
    let level: Int
    let title: String
    let position: Int  // UTF-16 offset in sourceText
}

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
    weak var commandHandler: EditorCommandHandler?

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

    // MARK: - Outline

    var headings: [HeadingItem] {
        var result: [HeadingItem] = []
        let lines = sourceText.components(separatedBy: "\n")
        var offset = 0
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                var level = 0
                for ch in trimmed {
                    if ch == "#" { level += 1 } else { break }
                }
                if level >= 1 && level <= 6 {
                    let title = String(trimmed.dropFirst(level)).trimmingCharacters(in: .whitespaces)
                    if !title.isEmpty {
                        result.append(HeadingItem(level: level, title: title, position: offset))
                    }
                }
            }
            offset += (line as NSString).length + 1  // +1 for \n
        }
        return result
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
        commandHandler?.insertImageMarkdown(markdown, at: position)
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
        commandHandler?.toggleFormatting(prefix: prefix, suffix: suffix)
    }

    private func insertText(_ text: String, cursorOffset: Int) {
        commandHandler?.insertFormattedText(text, cursorOffset: cursorOffset)
    }

    private func setLinePrefix(_ prefix: String) {
        commandHandler?.setLinePrefix(prefix)
    }
}
