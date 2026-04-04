# API Documentation

## Internal APIs

### MarkdownParser
```swift
struct MarkdownParser: Sendable {
    func parse(_ source: String, revision: UInt64) -> ParseResult
}
```
- **Purpose**: swift-markdown AST を EditorNode ツリーに変換
- **Input**: Markdown ソーステキスト + リビジョン番号
- **Output**: ParseResult（revision + [EditorNode]）

### EditorNodeModel
```swift
@Observable final class EditorNodeModel {
    var blocks: [EditorNode]
    var documentRevision: UInt64
    var activeBlockID: EditorNode.ID?
    
    func applyParseResult(_ result: ParseResult)
    func resolveActiveBlock(cursorOffset: Int) -> EditorNode.ID?
    func setActiveBlock(_ blockID: EditorNode.ID?) -> Set<EditorNode.ID>
    func block(withID id: EditorNode.ID) -> EditorNode?
}
```
- **Purpose**: ブロックリスト管理、差分マージ、アクティブブロック追跡
- **Thread Safety**: @unchecked Sendable、@MainActor コンテキストからのみ変更

### SyntaxHighlighter
```swift
@MainActor struct SyntaxHighlighter {
    func apply(to textStorage: NSTextStorage, blocks: [EditorNode], 
               settings: EditorSettings, theme: EditorTheme)
}
```
- **Purpose**: NSTextStorage に属性のみを適用（テキスト内容は変更しない）
- **Constraint**: beginEditing/endEditing でラップ。IME 変換中は呼び出し禁止

### EditorViewModel
```swift
@Observable @MainActor final class EditorViewModel {
    var sourceText: String
    var cursorPosition: Int
    var isFocusModeEnabled: Bool
    var isTypewriterScrollEnabled: Bool
    
    func toggleBold()
    func toggleItalic()
    func toggleInlineCode()
    func insertLink()
    func setHeading(level: Int)
    func exportHTML() async -> String
    func exportPDF() async throws -> Data
    func handleImageDrop(urls: [URL], documentURL: URL?) async
}
```
- **Purpose**: エディタの中央コーディネーター
- **Command Pattern**: NotificationCenter 経由でフォーマットコマンドを Coordinator に伝達

### MarkdownDocument
```swift
final class MarkdownDocument: ReferenceFileDocument, @unchecked Sendable {
    var viewModel: EditorViewModel
    
    nonisolated func snapshot(contentType: UTType) throws -> String
    nonisolated func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper
    nonisolated func updateSnapshotText(_ text: String)
}
```
- **Purpose**: SwiftUI ドキュメントモデル。NSLock で snapshot テキストを保護
- **Thread Safety**: snapshot/fileWrapper は nonisolated（任意スレッドから呼ばれる）

### ExportService
```swift
actor ExportService {
    static let shared: ExportService
    func generateHTML(from markdown: String, title: String) async -> String
    func generatePDF(from html: String) async throws -> Data
}
```

### FileService
```swift
actor FileService {
    static let shared: FileService
    func createDirectoryIfNeeded(at url: URL) async throws
}
```

### ImageService
```swift
actor ImageService {
    static let shared: ImageService
    func importDroppedImage(from urls: [URL], to directory: URL) async throws -> [String]
}
```

## Notification-Based Commands

| Notification Name | userInfo Keys | Purpose |
|---|---|---|
| `shoechoo.toggleFormatting` | `prefix: String`, `suffix: String` | インライン書式トグル（bold, italic, code） |
| `shoechoo.insertFormattedText` | `text: String`, `cursorOffset: Int` | テンプレートテキスト挿入（リンク等） |
| `shoechoo.setLinePrefix` | `prefix: String` | 行頭プレフィックス設定（見出し等） |
| `shoechoo.insertImageMarkdown` | `markdown: String`, `position: Int` | 画像マークダウン挿入 |
| `shoechoo.scrollToPosition` | (未使用) | スクロール位置指定 |

**問題点**: すべて `object: nil` で送信されるため、複数ウィンドウで全 Coordinator が同じ通知を受信する。userInfo は `[String: Any]` で型安全性がない。

## Data Models

### EditorNode
```swift
struct EditorNode: Identifiable, Equatable, Sendable {
    let id: UUID
    var kind: BlockKind          // paragraph, heading(level), codeBlock, list, etc.
    var sourceRange: NSRange     // UTF-16 range in full document
    var contentHash: Int
    var inlineRuns: [InlineRun]  // bold, italic, code, link etc. (block-relative ranges)
    var isActive: Bool
    var activationScope: ActivationScope
    var sourceText: String
    var children: [EditorNode]   // list items, table rows, blockquote children
}
```

### InlineRun
```swift
struct InlineRun: Equatable, Sendable {
    var type: InlineType    // text, bold, italic, boldItalic, strikethrough, inlineCode, link, image, lineBreak
    var range: NSRange      // UTF-16 range relative to owning block's sourceText
}
```

### EditorSettings
```swift
@Observable @MainActor final class EditorSettings {
    var fontFamily: String
    var fontSize: CGFloat
    var lineSpacing: CGFloat
    var appearanceOverride: AppearanceMode  // system, light, dark
    var defaultFocusMode: Bool
    var defaultTypewriterScroll: Bool
    var autoSaveEnabled: Bool
    var autoSaveIntervalSeconds: Int
}
```
