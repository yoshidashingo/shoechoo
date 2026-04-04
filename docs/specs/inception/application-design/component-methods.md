---
layout: default
---

# Component Methods: Shoe Choo

> **Note**: Method signatures define the interface. Detailed business rules will be specified in Functional Design (CONSTRUCTION phase).

---

## C-02: MarkdownDocument

```swift
class MarkdownDocument: NSDocument {
    var viewModel: EditorViewModel

    // NSDocument lifecycle
    override func read(from data: Data, ofType typeName: String) throws
    override func data(ofType typeName: String) throws -> Data
    override func defaultDraftName() -> String

    // Asset management
    func assetsDirectoryURL() -> URL?
    func ensureAssetsDirectory() throws -> URL
}
```

## C-03: EditorViewModel

```swift
@Observable
class EditorViewModel {
    // State
    var sourceText: String
    var nodeModel: EditorNodeModel
    var cursorPosition: Int
    var activeBlockID: EditorNode.ID?
    var isFocusModeEnabled: Bool
    var isTypewriterScrollEnabled: Bool

    // Text editing
    func textDidChange(_ newText: String, editedRange: NSRange)
    func cursorDidMove(to position: Int)

    // Rendering
    func attributedStringForDisplay() -> NSAttributedString
    func rerenderBlock(_ blockID: EditorNode.ID)

    // Focus mode
    func toggleFocusMode()
    func toggleTypewriterScroll()

    // Image insertion
    func insertImage(at position: Int, relativePath: String)

    // Export
    func exportHTML() async throws -> String
    func exportPDF() async throws -> Data
}
```

## C-04: EditorSettings

```swift
@Observable
class EditorSettings {
    // Typography
    var fontFamily: String
    var fontSize: CGFloat
    var lineSpacing: CGFloat

    // Appearance
    var appearanceOverride: AppearanceMode  // .system, .light, .dark

    // Defaults
    var defaultFocusMode: Bool
    var defaultTypewriterScroll: Bool
}
```

## C-05: MarkdownParser

```swift
struct MarkdownParser {
    func parse(_ source: String) -> Markup
    func parseBlock(_ source: String, range: Range<String.Index>) -> [BlockMarkup]
}
```

## C-06: EditorNodeModel

```swift
class EditorNodeModel {
    var blocks: [EditorNode]

    // Sync with parser
    func rebuild(from markup: Markup)
    func updateBlocks(editedRange: NSRange, newSource: String, parser: MarkdownParser)

    // Active block tracking
    func blockContaining(position: Int) -> EditorNode?
    func setActiveBlock(_ blockID: EditorNode.ID?)
}

struct EditorNode: Identifiable {
    let id: UUID
    var type: BlockType             // .paragraph, .heading(level:), .codeBlock(lang:), .list, .table, .blockquote, .horizontalRule, .taskList
    var sourceRange: Range<String.Index>
    var inlineRuns: [InlineRun]     // bold, italic, link, code, image, strikethrough
    var isActive: Bool              // cursor is in this block
}

struct InlineRun {
    var type: InlineType            // .bold, .italic, .link(url:), .code, .image(src:,alt:), .strikethrough, .text
    var range: Range<String.Index>
}
```

## C-07: MarkdownRenderer

```swift
struct MarkdownRenderer {
    var settings: EditorSettings

    func render(block: EditorNode, appearance: NSAppearance) -> NSAttributedString
    func renderActiveBlock(block: EditorNode, appearance: NSAppearance) -> NSAttributedString
    func renderFullDocument(model: EditorNodeModel, appearance: NSAppearance) -> NSAttributedString
}
```

## C-08: WYSIWYGTextView

```swift
struct WYSIWYGTextView: NSViewRepresentable {
    @Binding var viewModel: EditorViewModel
    var settings: EditorSettings

    func makeNSView(context: Context) -> ShoechooTextView
    func updateNSView(_ nsView: ShoechooTextView, context: Context)
}

class ShoechooTextView: NSTextView {
    // Focus mode
    func applyFocusModeDimming(activeBlockRange: NSRange)
    func removeFocusModeDimming()

    // Typewriter scroll
    func scrollToCenterLine(_ lineRange: NSRange)

    // Image drag & drop
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool
}
```

## C-11: ExportService

```swift
actor ExportService {
    func generateHTML(from source: String, title: String) async throws -> String
    func generatePDF(from html: String) async throws -> Data
}
```

## C-12: ImageService

```swift
actor ImageService {
    func importDroppedImage(_ image: NSImage, to assetsDir: URL) async throws -> String
    func importPastedImage(from pasteboard: NSPasteboard, to assetsDir: URL) async throws -> String
    func generateFilename(for image: NSImage) -> String
}
```

## C-13: FileService

```swift
actor FileService {
    func createDirectoryIfNeeded(at url: URL) async throws
    func fileExists(at url: URL) -> Bool
    func safeWrite(_ data: Data, to url: URL) async throws
}
```
