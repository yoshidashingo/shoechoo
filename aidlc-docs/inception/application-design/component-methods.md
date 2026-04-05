# Component Methods — Cycle 2: Refactoring

> 各コンポーネントのメソッドシグネチャ定義。
> 既存コードベースの実装事実に基づき、リファクタリング後のインターフェースを規定する。

---

## NC-01: EditorCommandHandler Protocol

```swift
/// EditorViewModel から NSTextView 操作への型安全なコマンドチャネル。
/// NotificationCenter の 5 つの通知を完全に置換する。
///
/// 現在の対応関係:
///   .toggleFormatting     → toggleFormatting(prefix:suffix:)
///   .insertFormattedText  → insertFormattedText(_:cursorOffset:)
///   .setLinePrefix        → setLinePrefix(_:)
///   .insertImageMarkdown  → insertImageMarkdown(_:at:)
///   .scrollToPosition     → scrollToPosition(_:)
@MainActor
protocol EditorCommandHandler: AnyObject {

    /// 選択テキストに対するインライン書式のトグル。
    /// 選択テキストが既に prefix/suffix で囲まれている場合は除去、そうでなければ追加。
    ///
    /// 呼び出し元: EditorViewModel.toggleBold() ("**"), toggleItalic() ("*"), toggleInlineCode() ("`")
    /// 現在の実装: Coordinator.handleToggleFormatting(prefix:suffix:) — WYSIWYGTextView.swift:343-353
    func toggleFormatting(prefix: String, suffix: String)

    /// カーソル位置にテンプレートテキストを挿入し、カーソルを指定オフセットに移動。
    ///
    /// 呼び出し元: EditorViewModel.insertLink() — テンプレート "[](url)", cursorOffset: 1
    /// 現在の実装: Coordinator.handleInsertText(text:cursorOffset:) — WYSIWYGTextView.swift:355-360
    func insertFormattedText(_ text: String, cursorOffset: Int)

    /// 現在の行のプレフィックスを置換。既存の # プレフィックスは正規表現で除去。
    ///
    /// 呼び出し元: EditorViewModel.setHeading(level:) — "## " 等
    /// 現在の実装: Coordinator.handleSetLinePrefix(prefix:) — WYSIWYGTextView.swift:362-370
    func setLinePrefix(_ prefix: String)

    /// 指定位置に画像マークダウン構文を挿入。
    ///
    /// 呼び出し元: ImageDropHandler.handleImageDrop()
    /// 現在の実装: Notification 経由だが Coordinator 側に受信ハンドラなし（バグ: FR-06）
    /// リファクタリングで正しく実装される。
    func insertImageMarkdown(_ markdown: String, at position: Int)

    /// 指定 UTF-16 オフセット位置にスクロールし、カーソルを移動。
    ///
    /// 呼び出し元: OutlineView.scrollToHeading(), EditorViewModel（将来）
    /// 現在の実装: Coordinator.handleScrollToPosition(position:) — WYSIWYGTextView.swift:372-379
    func scrollToPosition(_ position: Int)
}
```

---

## NC-02: DocumentStatistics

```swift
/// EditorViewModel から分離された統計情報。
/// 不変の値型で、sourceText 変更時に再生成される。
///
/// 現在の実装箇所: EditorViewModel.swift:84-97 の 3 computed properties
struct DocumentStatistics: Sendable, Equatable {
    let wordCount: Int
    let characterCount: Int
    let lineCount: Int

    /// sourceText から統計情報を算出。
    /// - wordCount: 空白・改行で分割したトークン数（現在の実装と同一ロジック）
    /// - characterCount: String.count（Character 数）
    /// - lineCount: 改行区切りの行数。空文字列の場合は 0
    init(from sourceText: String) {
        self.wordCount = sourceText.split { $0.isWhitespace || $0.isNewline }.count
        self.characterCount = sourceText.count
        self.lineCount = sourceText.isEmpty ? 0 : sourceText.components(separatedBy: "\n").count
    }
}
```

---

## NC-03: ExportCoordinator

```swift
/// EditorViewModel からエクスポート責務を分離した薄いコーディネーター。
/// ExportService actor への委譲のみを行う。
///
/// 現在の実装箇所: EditorViewModel.swift:100-108
struct ExportCoordinator {
    private let exportService: ExportService

    init(exportService: ExportService = .shared) {
        self.exportService = exportService
    }

    /// Markdown ソースから HTML を生成。
    /// 現在: EditorViewModel.exportHTML() → ExportService.shared.generateHTML()
    func exportHTML(from sourceText: String, title: String) async -> String {
        await exportService.generateHTML(from: sourceText, title: title)
    }

    /// Markdown ソースから PDF を生成。HTML 中間生成を経由。
    /// 現在: EditorViewModel.exportPDF() → exportHTML() → ExportService.shared.generatePDF()
    func exportPDF(from sourceText: String, title: String) async throws -> Data {
        let html = await exportService.generateHTML(from: sourceText, title: title)
        return try await exportService.generatePDF(from: html)
    }
}
```

---

## NC-04: ImageDropHandler

```swift
/// EditorViewModel から画像ハンドリング責務を分離。
/// ImageService actor への委譲 + EditorCommandHandler 経由のマークダウン挿入。
///
/// 現在の実装箇所: EditorViewModel.swift:112-134
struct ImageDropHandler {
    private let imageService: ImageService

    init(imageService: ImageService = .shared) {
        self.imageService = imageService
    }

    /// 画像 URL リストをアセットディレクトリにインポートし、マークダウン構文を挿入。
    ///
    /// 現在の EditorViewModel.handleImageDrop の責務を引き継ぐ。
    /// 差分: NotificationCenter.post(.insertImageMarkdown) → commandHandler.insertImageMarkdown() 直接呼び出し
    ///
    /// - Parameters:
    ///   - urls: ドロップされた画像ファイルの URL リスト
    ///   - documentURL: ドキュメントファイルの URL（nil の場合は処理しない）
    ///   - insertionPosition: 挿入位置（UTF-16 オフセット）
    ///   - commandHandler: NSTextView 操作のハンドラ（weak 参照元から渡される）
    /// - Throws: ImageServiceError（ファイルサイズ超過等）
    @MainActor
    func handleImageDrop(
        urls: [URL],
        documentURL: URL?,
        insertionPosition: Int,
        commandHandler: EditorCommandHandler?
    ) async throws {
        // Implementation: ImageService.importDroppedImage → commandHandler.insertImageMarkdown
    }
}
```

---

## NC-05: DebounceTask

```swift
/// Timer ベースのデバウンスを Task ベースに置換するユーティリティ。
/// MainActor 分離を保証し、nonisolated(unsafe) を不要にする。
///
/// 置換対象:
///   - Coordinator.highlightTimer (Timer?, interval: 0.15s / 0.02s)
///   - Coordinator.autoSaveTimer (Timer?, interval: settings.autoSaveIntervalSeconds)
///
/// 現在の実装パターン:
///   highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
///       MainActor.assumeIsolated { self?.applyHighlightNow() }
///   }
@MainActor
final class DebounceTask {
    private var task: Task<Void, Never>?

    /// 前回の Task をキャンセルし、指定インターバル後に operation を実行。
    ///
    /// - Parameters:
    ///   - interval: デバウンスインターバル
    ///   - operation: MainActor 上で実行されるクロージャ
    func schedule(interval: Duration, operation: @MainActor @Sendable @escaping () -> Void) {
        task?.cancel()
        task = Task { @MainActor in
            try? await Task.sleep(for: interval)
            guard !Task.isCancelled else { return }
            operation()
        }
    }

    /// 保留中の Task をキャンセル。
    func cancel() {
        task?.cancel()
        task = nil
    }

    deinit {
        task?.cancel()
    }
}
```

---

## NC-06: SnapshotStore

```swift
/// MarkdownDocument のスナップショットテキストをスレッドセーフに管理する Sendable ラッパー。
/// 内部で NSLock を使用し、nonisolated(unsafe) を SnapshotStore 内部に封じ込める。
///
/// 現在の実装箇所: MarkdownDocument.swift:17-18, 35-37, 46-48
///   nonisolated(unsafe) private let lock = NSLock()
///   nonisolated(unsafe) private var _snapshotText: String = ""
///
/// ReferenceFileDocument.snapshot(contentType:) は nonisolated で呼ばれるため、
/// Sendable な値型でロックを内包する必要がある。
final class SnapshotStore: Sendable {
    private let lock = NSLock()
    private nonisolated(unsafe) var _text: String = ""

    /// スナップショットテキストを読み取る。nonisolated コンテキストから安全に呼び出し可能。
    nonisolated func read() -> String {
        lock.withLock { _text }
    }

    /// スナップショットテキストを更新する。nonisolated コンテキストから安全に呼び出し可能。
    nonisolated func write(_ text: String) {
        lock.withLock { _text = text }
    }
}
```

> **注**: SnapshotStore 自体は内部に `nonisolated(unsafe)` を 1 箇所持つが、これは NSLock で保護された private 実装詳細であり、外部 API は完全にスレッドセーフ。MarkdownDocument 側の `nonisolated(unsafe)` 4 箇所のうち `lock` + `_snapshotText` の 2 箇所が SnapshotStore に集約される。残りの `viewModel` は `@MainActor` 明示、`fileURL` は同様のロック保護パターンまたは `@MainActor` 明示で対応。

---

## EC-01: EditorViewModel（リファクタリング後のメソッド一覧）

### 削除されるメソッド

| メソッド | 行番号 | 移行先 |
|---------|--------|--------|
| `exportHTML() async -> String` | 100-103 | ExportCoordinator |
| `exportPDF() async throws -> Data` | 105-108 | ExportCoordinator |
| `insertImage(at:relativePath:)` | 112-118 | ImageDropHandler |
| `handleImageDrop(urls:documentURL:) async` | 120-134 | ImageDropHandler |
| `clearError()` | 136-138 | ImageDropHandler のエラーハンドリング |
| `toggleInlineFormatting(prefix:suffix:)` (private) | 142-147 | commandHandler 直接呼び出し |
| `insertText(_:cursorOffset:)` (private) | 149-154 | commandHandler 直接呼び出し |
| `setLinePrefix(_:)` (private) | 156-160 | commandHandler 直接呼び出し |

### 削除されるプロパティ

| プロパティ | 行番号 | 理由 |
|-----------|--------|------|
| `var lastError: String?` | 16 | ImageDropHandler に移行 |
| `var wordCount: Int` (computed) | 84-87 | DocumentStatistics に移行 |
| `var characterCount: Int` (computed) | 89-91 | DocumentStatistics に移行 |
| `var lineCount: Int` (computed) | 93-97 | DocumentStatistics に移行 |

### 削除される定義

```swift
// EditorViewModel.swift:163-169 — 全削除
extension Notification.Name {
    static let toggleFormatting = ...      // → EditorCommandHandler.toggleFormatting
    static let insertFormattedText = ...   // → EditorCommandHandler.insertFormattedText
    static let setLinePrefix = ...         // → EditorCommandHandler.setLinePrefix
    static let insertImageMarkdown = ...   // → EditorCommandHandler.insertImageMarkdown
    static let scrollToPosition = ...      // → EditorCommandHandler.scrollToPosition
}
```

### 残留するメソッド

| メソッド | 責務 |
|---------|------|
| `toggleBold()` | `commandHandler?.toggleFormatting(prefix: "**", suffix: "**")` に変更 |
| `toggleItalic()` | `commandHandler?.toggleFormatting(prefix: "*", suffix: "*")` に変更 |
| `toggleInlineCode()` | `commandHandler?.toggleFormatting(prefix: "`", suffix: "`")` に変更 |
| `insertLink()` | `commandHandler?.insertFormattedText("[](url)", cursorOffset: 1)` に変更 |
| `setHeading(level:)` | `commandHandler?.setLinePrefix(prefix)` に変更 |
| `toggleFocusMode()` | 変更なし |
| `toggleTypewriterScroll()` | 変更なし |

### 追加されるプロパティ

```swift
@Observable @MainActor
final class EditorViewModel {
    // 既存（残留）
    var sourceText: String = ""
    var cursorPosition: Int = 0
    var isFocusModeEnabled: Bool
    var isTypewriterScrollEnabled: Bool
    var isIMEComposing: Bool = false
    let settings: EditorSettings

    // 新規
    weak var commandHandler: EditorCommandHandler?
    var statistics: DocumentStatistics = DocumentStatistics(from: "")

    // headings は残留（FR-08 で別途最適化）
    var headings: [HeadingItem] { ... }
}
```

---

## EC-02: WYSIWYGTextView.Coordinator（リファクタリング後の構造）

### 削除されるメンバー

| メンバー | 行番号 | 理由 |
|---------|--------|------|
| `nonisolated(unsafe) private var highlightTimer: Timer?` | 101 | DebounceTask に置換 |
| `nonisolated(unsafe) private var autoSaveTimer: Timer?` | 102 | DebounceTask に置換 |
| `nonisolated(unsafe) private var notificationObservers: [any NSObjectProtocol]` | 103 | Notification 廃止 |
| `func registerNotifications()` | 305-341 | EditorCommandHandler protocol で置換 |
| `private func handleToggleFormatting(prefix:suffix:)` | 343-353 | → protocol メソッド `toggleFormatting` |
| `private func handleInsertText(text:cursorOffset:)` | 355-360 | → protocol メソッド `insertFormattedText` |
| `private func handleSetLinePrefix(prefix:)` | 362-370 | → protocol メソッド `setLinePrefix` |
| `private func handleScrollToPosition(position:)` | 372-379 | → protocol メソッド `scrollToPosition` |
| `deinit` 内の Timer invalidate + Observer 解除 | 111-115 | DebounceTask.cancel() + Observer 不要 |

### リファクタリング後の構造

```swift
@MainActor
final class Coordinator: NSObject, NSTextViewDelegate, EditorCommandHandler {
    var parent: WYSIWYGTextView
    weak var textView: ShoechooTextView?
    weak var scrollView: NSScrollView?
    let nodeModel = EditorNodeModel()
    private var isApplyingHighlight = false
    private var currentActiveBlockID: EditorNode.ID?

    // Timer → DebounceTask
    private let highlightDebounce = DebounceTask()
    private let autoSaveDebounce = DebounceTask()

    // MARK: - EditorCommandHandler

    func toggleFormatting(prefix: String, suffix: String) { ... }
    func insertFormattedText(_ text: String, cursorOffset: Int) { ... }
    func setLinePrefix(_ prefix: String) { ... }
    func insertImageMarkdown(_ markdown: String, at position: Int) { ... }
    func scrollToPosition(_ position: Int) { ... }

    // MARK: - NSTextViewDelegate (変更なし)

    func textDidChange(_ notification: Notification) { ... }
    func textViewDidChangeSelection(_ notification: Notification) { ... }

    // MARK: - Highlight (Timer → DebounceTask)

    func scheduleHighlight() {
        highlightDebounce.schedule(interval: .milliseconds(150)) { [weak self] in
            self?.applyHighlightNow()
        }
    }

    func applyHighlightNow() { ... }  // 変更なし

    // MARK: - Auto-Save (Timer → DebounceTask)

    func scheduleAutoSave() {
        guard parent.settings.autoSaveEnabled else {
            autoSaveDebounce.cancel()
            return
        }
        let interval = parent.settings.autoSaveIntervalSeconds
        autoSaveDebounce.schedule(interval: .seconds(interval)) { [weak self] in
            self?.performAutoSave()
        }
    }

    // MARK: - Appearance / Focus Mode (変更なし)
    func applyAppearance(settings: EditorSettings) { ... }
    private func updateFocusModeDimming(cursorPosition: Int) { ... }
    private func applyHighlightFromCache() { ... }
    private func scheduleHighlightForCursorMove() { ... }
}
```

---

## EC-03: MarkdownDocument（リファクタリング後）

```swift
final class MarkdownDocument: ReferenceFileDocument, @unchecked Sendable {
    typealias Snapshot = String

    // viewModel: nonisolated(unsafe) を維持（ReferenceFileDocument プロトコル制約）
    // init(configuration:) は off-main スレッドから呼ばれる可能性があり、
    // @MainActor な EditorViewModel を生成できない。AC #9 の例外として記録。
    nonisolated(unsafe) var viewModel: EditorViewModel!

    // nonisolated(unsafe) lock + _snapshotText → SnapshotStore に集約
    let snapshotStore = SnapshotStore()

    // fileURL: SnapshotStore 類似パターンで lock 保護
    // assetsDirectoryURL() が nonisolated から呼ばれるため @MainActor 不可
    private let fileURLStore = SnapshotStore() // URL を String として保存、または専用 URLStore

    static var readableContentTypes: [UTType] { [.markdown, .plainText] }
    static var writableContentTypes: [UTType] { [.markdown] }

    init() {
        // ReferenceFileDocument.init() は通常 MainActor から呼ばれる
        self.viewModel = MainActor.assumeIsolated { EditorViewModel() }
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        snapshotStore.write(text)
        // off-main の場合は遅延初期化（デッドロック防止）
        if Thread.isMainThread {
            let vm = MainActor.assumeIsolated { EditorViewModel() }
            MainActor.assumeIsolated { vm.sourceText = text }
            self.viewModel = vm
        } else {
            DispatchQueue.main.async { [weak self] in
                MainActor.assumeIsolated {
                    let vm = EditorViewModel()
                    vm.sourceText = text
                    self?.viewModel = vm
                }
            }
        }
        vm.sourceText = text
        self.viewModel = vm
    }

    nonisolated func snapshot(contentType: UTType) throws -> String {
        snapshotStore.read()
    }

    nonisolated func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        // 変更なし
    }

    nonisolated func updateSnapshotText(_ text: String) {
        snapshotStore.write(text)
    }

    // MARK: - Asset Management (変更なし)
    @MainActor func assetsDirectoryURL() -> URL? { ... }
    @MainActor func ensureAssetsDirectory() async throws -> URL { ... }
}
```

---

## OutlineView（scrollToHeading の変更）

```swift
// 現在: OutlineView.swift:38-44
// NotificationCenter.default.post(name: .scrollToPosition, ...)
//
// 変更後: EditorViewModel.commandHandler 経由
private func scrollToHeading(_ heading: HeadingItem) {
    viewModel.commandHandler?.scrollToPosition(heading.position)
}
```
