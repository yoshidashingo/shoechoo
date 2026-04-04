import AppKit
import Combine

@Observable
@MainActor
final class EditorViewModel {
    var sourceText: String = ""
    var nodeModel = EditorNodeModel()
    var cursorPosition: Int = 0
    var isFocusModeEnabled: Bool
    var isTypewriterScrollEnabled: Bool

    private let parser = MarkdownParser()
    private let renderCache = RenderCache()
    private var parseTask: Task<Void, Never>?
    private var revision: UInt64 = 0

    var changedBlockIDs: Set<EditorNode.ID> = []
    var needsFullRerender: Bool = false

    var isIMEComposing: Bool = false
    var lastError: String?

    let settings: EditorSettings

    init(settings: EditorSettings = .shared) {
        self.settings = settings
        self.isFocusModeEnabled = settings.defaultFocusMode
        self.isTypewriterScrollEnabled = settings.defaultTypewriterScroll
    }

    func textDidChange(_ newText: String, editedRange: NSRange) {
        guard !isIMEComposing else { return }
        sourceText = newText
        scheduleParse()
    }

    func cursorDidMove(to position: Int) {
        guard !isIMEComposing else { return }
        cursorPosition = position
        let newActiveID = nodeModel.resolveActiveBlock(cursorOffset: position, in: sourceText)
        let changed = nodeModel.setActiveBlock(newActiveID)
        if !changed.isEmpty {
            renderCache.invalidate(changed)
            changedBlockIDs = changed
        }
    }

    private func scheduleParse() {
        parseTask?.cancel()
        revision += 1
        let currentRevision = revision
        let text = sourceText
        let parser = self.parser

        parseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(50))
            guard !Task.isCancelled else { return }

            let result = parser.parse(text, revision: currentRevision)

            guard let self, !Task.isCancelled else { return }
            self.nodeModel.applyParseResult(result)
            self.renderCache.invalidateAll()
            self.needsFullRerender = true

            let activeID = self.nodeModel.resolveActiveBlock(cursorOffset: self.cursorPosition, in: self.sourceText)
            self.nodeModel.setActiveBlock(activeID)
        }
    }

    func attributedStringForDisplay(appearance: NSAppearance) -> NSAttributedString {
        let renderer = MarkdownRenderer()
        let rendererAppearance: MarkdownRenderer.Appearance = appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ? .dark : .light
        let result = NSMutableAttributedString()

        for block in nodeModel.blocks {
            if let cached = renderCache.get(block.id), cached.isActive == block.isActive {
                result.append(cached.attributedString)
            } else {
                let rendered: RenderResult
                if block.isActive {
                    rendered = renderer.renderActiveBlock(block: block, settings: settings, appearance: rendererAppearance)
                } else {
                    rendered = renderer.render(block: block, settings: settings, appearance: rendererAppearance)
                }
                renderCache.set(block.id, result: rendered)
                result.append(rendered.attributedString)
            }
        }

        needsFullRerender = false
        changedBlockIDs.removeAll()
        return result
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
