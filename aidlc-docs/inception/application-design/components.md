# Components — Cycle 2: Refactoring

> Cycle 1 コンポーネント定義のリファクタリング改訂版。
> 既存コードベース（21 Swift ファイル、約4,678行）の実装事実に基づく。

---

## Component Overview（リファクタリング後）

```
+-----------------------------------------------------------+
|                    ShoechooApp (SwiftUI)                   |
|  +-------+  +------------------------------------------+  |
|  |Sidebar|  |           DocumentWindow                  |  |
|  |Outline|  |  +--------------------------------------+ |  |
|  |Files  |  |  |        EditorView (SwiftUI)          | |  |
|  |       |  |  |  +--------------------------------+  | |  |
|  |       |  |  |  | WYSIWYGTextView (AppKit)       |  | |  |
|  |       |  |  |  | Coordinator: EditorCommandHandler| | |  |
|  |       |  |  |  | DebounceTask (highlight/save)  |  | |  |
|  |       |  |  |  +--------------------------------+  | |  |
|  |       |  |  +--------------------------------------+ |  |
|  |       |  |  StatusBar: DocumentStatistics            |  |
|  +-------+  +------------------------------------------+  |
+-----------------------------------------------------------+
```

---

## 新規コンポーネント

### NC-01: EditorCommandHandler（Protocol）

| 項目 | 内容 |
|------|------|
| **名前** | `EditorCommandHandler` |
| **タイプ** | `@MainActor protocol` |
| **目的** | NotificationCenter を完全に廃止し、EditorViewModel から NSTextView 操作への型安全なコマンドチャネルを提供する |
| **FR対応** | FR-01（NotificationCenter廃止）、FR-02（複数ウィンドウ対応）、FR-06（insertImageMarkdown修正） |

**責務**:
- テキスト書式トグル（bold, italic, inline code）のNSTextView操作を受け付ける
- 書式付きテキスト挿入（link テンプレート等）を受け付ける
- 行プレフィックス設定（heading レベル変更）を受け付ける
- 画像マークダウン挿入を受け付ける
- 指定位置へのスクロール（OutlineView からの遷移）を受け付ける

**インターフェース概要**:
```swift
@MainActor
protocol EditorCommandHandler: AnyObject {
    func toggleFormatting(prefix: String, suffix: String)
    func insertFormattedText(_ text: String, cursorOffset: Int)
    func setLinePrefix(_ prefix: String)
    func insertImageMarkdown(_ markdown: String, at position: Int)
    func scrollToPosition(_ position: Int)
}
```

**現状との差分**:
- 現在: `EditorViewModel` が `NotificationCenter.default.post(name:)` で 5 つの通知を発行（EditorViewModel.swift:113-159）
- 現在: `WYSIWYGTextView.Coordinator` が `registerNotifications()` で 4 つの Observer を登録（WYSIWYGTextView.swift:305-341）
- 現在: `OutlineView` が `NotificationCenter.default.post(name: .scrollToPosition)` を直接発行（OutlineView.swift:39）
- 変更後: EditorViewModel が `weak var commandHandler: EditorCommandHandler?` を保持し、直接メソッド呼び出し
- 変更後: Coordinator が protocol を実装し、makeNSView 時に自身を commandHandler として設定

---

### NC-02: DocumentStatistics（Struct）

| 項目 | 内容 |
|------|------|
| **名前** | `DocumentStatistics` |
| **タイプ** | `struct`（Sendable） |
| **目的** | EditorViewModel から統計計算責務を分離する（Single Responsibility） |
| **FR対応** | FR-07（EditorViewModel 責務分割） |

**責務**:
- ソーステキストから語数、文字数、行数を算出する
- 不変のスナップショットとして統計情報を提供する

**インターフェース概要**:
```swift
struct DocumentStatistics: Sendable, Equatable {
    let wordCount: Int
    let characterCount: Int
    let lineCount: Int

    init(from sourceText: String)
}
```

**現状との差分**:
- 現在: `EditorViewModel` が 3 つの computed properties として統計を保持（EditorViewModel.swift:84-97）
  - `var wordCount: Int` — split + count
  - `var characterCount: Int` — sourceText.count
  - `var lineCount: Int` — components(separatedBy:).count
- 変更後: `DocumentStatistics` struct に抽出。EditorViewModel は `var statistics: DocumentStatistics` を保持し、sourceText 変更時に再計算

---

### NC-03: ExportCoordinator（Struct）

| 項目 | 内容 |
|------|------|
| **名前** | `ExportCoordinator` |
| **タイプ** | `struct` |
| **目的** | EditorViewModel からエクスポート責務を分離する |
| **FR対応** | FR-07（EditorViewModel 責務分割） |

**責務**:
- ExportService への委譲によるHTML/PDFエクスポートの実行
- エクスポートに必要なコンテキスト（sourceText, title）の受け渡し

**インターフェース概要**:
```swift
struct ExportCoordinator {
    private let exportService: ExportService

    init(exportService: ExportService = .shared)

    func exportHTML(from sourceText: String, title: String) async -> String
    func exportPDF(from sourceText: String, title: String) async throws -> Data
}
```

**現状との差分**:
- 現在: `EditorViewModel.exportHTML()` と `exportPDF()` が `ExportService.shared` を直接呼び出し（EditorViewModel.swift:100-108）
- 変更後: `ExportCoordinator` が責務を受け持ち、EditorView から直接使用。EditorViewModel からエクスポートメソッドを削除

---

### NC-04: ImageDropHandler（Struct）

| 項目 | 内容 |
|------|------|
| **名前** | `ImageDropHandler` |
| **タイプ** | `struct` |
| **目的** | EditorViewModel から画像ドロップ/インポート責務を分離する |
| **FR対応** | FR-06（insertImageMarkdown修正）、FR-07（EditorViewModel 責務分割） |

**責務**:
- 画像 URL の受け取りと ImageService への委譲
- アセットディレクトリパスの構築
- 結果としてのマークダウン構文の生成
- EditorCommandHandler 経由での画像マークダウン挿入指示

**インターフェース概要**:
```swift
struct ImageDropHandler {
    private let imageService: ImageService

    init(imageService: ImageService = .shared)

    func handleImageDrop(
        urls: [URL],
        documentURL: URL?,
        insertionPosition: Int,
        commandHandler: EditorCommandHandler?
    ) async throws
}
```

**現状との差分**:
- 現在: `EditorViewModel.handleImageDrop(urls:documentURL:)` が ImageService を呼び出し、NotificationCenter で `insertImageMarkdown` を post（EditorViewModel.swift:112-134）
- 現在: `EditorViewModel.insertImage(at:relativePath:)` が NotificationCenter 経由で通知（EditorViewModel.swift:112-118）
- 変更後: `ImageDropHandler` が全責務を受け持ち、`EditorCommandHandler.insertImageMarkdown()` を直接呼び出し

---

### NC-05: DebounceTask（ユーティリティ）

| 項目 | 内容 |
|------|------|
| **名前** | `DebounceTask` |
| **タイプ** | `@MainActor final class` |
| **目的** | Timer ベースのデバウンスを Task ベースに置換し、nonisolated(unsafe) を排除する |
| **FR対応** | FR-09（Timer→Task デバウンス）、NFR-02（nonisolated(unsafe) ゼロ） |

**責務**:
- 指定インターバルでのデバウンス実行（前回の Task をキャンセルして新規 Task を発行）
- MainActor 分離を保証し、nonisolated(unsafe) を不要にする

**インターフェース概要**:
```swift
@MainActor
final class DebounceTask {
    private var task: Task<Void, Never>?

    func schedule(interval: Duration, operation: @MainActor @Sendable @escaping () -> Void)
    func cancel()
}
```

**現状との差分**:
- 現在: `Coordinator` が `nonisolated(unsafe) private var highlightTimer: Timer?` と `nonisolated(unsafe) private var autoSaveTimer: Timer?` を保持（WYSIWYGTextView.swift:101-102）
- 現在: `Timer.scheduledTimer(withTimeInterval:repeats:)` + `MainActor.assumeIsolated` パターン（WYSIWYGTextView.swift:151-155, 208-213）
- 変更後: `DebounceTask` に置換。`highlightDebounce` と `autoSaveDebounce` の 2 インスタンスを Coordinator が保持
- 排除される `nonisolated(unsafe)`: `highlightTimer`, `autoSaveTimer` の 2 箇所

---

### NC-06: SnapshotStore（Class）

| 項目 | 内容 |
|------|------|
| **名前** | `SnapshotStore` |
| **タイプ** | `final class`（Sendable） |
| **目的** | MarkdownDocument の `nonisolated(unsafe)` を排除するための Sendable ラッパー |
| **FR対応** | FR-10（MarkdownDocument の nonisolated(unsafe) 排除）、NFR-02 |

**注**: struct ではなく final class。内部に NSLock + mutable state を持ち、複数箇所から同一インスタンスの read()/write() を呼ぶため、値型（コピーセマンティクス）は不適切。

**責務**:
- スナップショットテキストのスレッドセーフな読み書き
- NSLock ベースの排他制御を内部にカプセル化
- Sendable 準拠により isolation boundary を安全に越える

**nonisolated(unsafe) に関する注記**:
内部実装で `nonisolated(unsafe) private var _text` を使用する。これは NSLock で完全に保護された private 実装詳細であり、public/internal インターフェースには露出しない。AC #9 は「public/internal インターフェースから nonisolated(unsafe) を排除」と解釈する（requirements.md に例外注記を追加）。macOS 14+ では Mutex<String> が利用不可のため、NSLock + nonisolated(unsafe) が唯一の現実的手段。

**インターフェース概要**:
```swift
final class SnapshotStore: Sendable {
    func read() -> String
    func write(_ text: String)
}
```

**現状との差分**:
- 現在: `MarkdownDocument` が `nonisolated(unsafe) private let lock = NSLock()` と `nonisolated(unsafe) private var _snapshotText: String` を保持（MarkdownDocument.swift:17-18）
- 現在: `lock.withLock { _snapshotText }` と `lock.withLock { _snapshotText = text }` で手動ロック（MarkdownDocument.swift:35-37, 46-48）
- 変更後: `SnapshotStore` がロック + テキストを内包。MarkdownDocument は `let snapshotStore = SnapshotStore()` を保持
- 排除される `nonisolated(unsafe)`: `lock`, `_snapshotText` の 2 箇所

---

## 既存コンポーネントの責務変更

### EC-01: EditorViewModel（責務縮小）

| 項目 | 現在 | リファクタリング後 |
|------|------|-------------------|
| **タイプ** | `@Observable final class: @unchecked Sendable` | `@Observable @MainActor final class` |
| **Sendable準拠** | `@unchecked Sendable`（unsafe） | `@MainActor` 明示により不要 |

**責務の変更**:

| 責務 | 現在の所在 | 移行先 |
|------|-----------|--------|
| コマンドディスパッチ（書式、挿入、heading） | NotificationCenter.post → Coordinator | `commandHandler?.method()` 直接呼び出し |
| 統計情報（wordCount, characterCount, lineCount） | EditorViewModel computed properties | `DocumentStatistics` struct |
| エクスポート（exportHTML, exportPDF） | EditorViewModel メソッド | `ExportCoordinator` |
| 画像ドロップ処理（handleImageDrop, insertImage） | EditorViewModel メソッド | `ImageDropHandler` |
| UI状態管理（sourceText, cursorPosition, focusMode 等） | EditorViewModel | EditorViewModel（**残留**） |
| Outline heading 抽出 | EditorViewModel.headings computed property | EditorViewModel（**残留**、FR-08 で別途最適化） |

**削除されるメソッド**:
- `exportHTML()`, `exportPDF()` → ExportCoordinator へ
- `handleImageDrop(urls:documentURL:)`, `insertImage(at:relativePath:)` → ImageDropHandler へ
- `clearError()` → ImageDropHandler のエラーハンドリングに統合

**削除される private メソッド**:
- `toggleInlineFormatting(prefix:suffix:)` → commandHandler 直接呼び出しに変更
- `insertText(_:cursorOffset:)` → commandHandler 直接呼び出しに変更
- `setLinePrefix(_:)` → commandHandler 直接呼び出しに変更

**削除される定義**:
- `Notification.Name` extension 全体（5 定義: `.toggleFormatting`, `.insertFormattedText`, `.setLinePrefix`, `.insertImageMarkdown`, `.scrollToPosition`）

**追加されるプロパティ**:
- `weak var commandHandler: EditorCommandHandler?`
- `var statistics: DocumentStatistics`

---

### EC-02: WYSIWYGTextView.Coordinator（責務変更）

| 項目 | 現在 | リファクタリング後 |
|------|------|-------------------|
| **プロトコル準拠** | `NSObject, NSTextViewDelegate` | `NSObject, NSTextViewDelegate, EditorCommandHandler` |

**責務の変更**:

| 責務 | 現在の実装 | 移行後 |
|------|-----------|--------|
| Notification 購読 | `registerNotifications()` で 4 Observer 登録 | **削除** — EditorCommandHandler protocol メソッドで直接受け取り |
| 書式トグル | `handleToggleFormatting(prefix:suffix:)` — Notification 経由 | `toggleFormatting(prefix:suffix:)` — protocol メソッドとして直接呼ばれる |
| テキスト挿入 | `handleInsertText(text:cursorOffset:)` — Notification 経由 | `insertFormattedText(_:cursorOffset:)` — protocol メソッド |
| 行プレフィックス | `handleSetLinePrefix(prefix:)` — Notification 経由 | `setLinePrefix(_:)` — protocol メソッド |
| スクロール | `handleScrollToPosition(position:)` — Notification 経由 | `scrollToPosition(_:)` — protocol メソッド |
| 画像マークダウン挿入 | Notification 経由（現在未受信のバグ） | `insertImageMarkdown(_:at:)` — protocol メソッド |
| ハイライトデバウンス | `nonisolated(unsafe) var highlightTimer: Timer?` | `DebounceTask` インスタンス |
| 自動保存デバウンス | `nonisolated(unsafe) var autoSaveTimer: Timer?` | `DebounceTask` インスタンス |
| Notification Observer リスト | `nonisolated(unsafe) var notificationObservers` | **削除** |

**排除される `nonisolated(unsafe)`**: 3 箇所すべて（`highlightTimer`, `autoSaveTimer`, `notificationObservers`）

**削除されるメソッド**:
- `registerNotifications()` — Notification 購読の全体
- `deinit` 内の Observer 解除ロジック

**追加される初期化**:
- `makeNSView` 内で `parent.viewModel.commandHandler = context.coordinator` を設定

---

### EC-03: MarkdownDocument（nonisolated(unsafe) 排除）

| 項目 | 現在 | リファクタリング後 |
|------|------|-------------------|
| **Sendable準拠** | `@unchecked Sendable` | `@unchecked Sendable`（ReferenceFileDocument 要件）ただし unsafe 箇所は SnapshotStore に隔離 |

**責務の変更**:

| プロパティ | 現在 | 移行後 |
|-----------|------|--------|
| `nonisolated(unsafe) var viewModel` | MainActor 想定だが unsafe 宣言 | `nonisolated(unsafe) var viewModel: EditorViewModel!` を維持。**理由**: `ReferenceFileDocument.init(configuration:)` は Apple プロトコル定義で @MainActor ではなく、off-main スレッドから呼ばれる可能性がある。viewModel を @MainActor にすると off-main から生成不可。現在の設計（off-main では `DispatchQueue.main.async` で遅延初期化）を維持し、viewModel の nonisolated(unsafe) は ReferenceFileDocument プロトコル制約による例外として AC #9 注記に追加 |
| `nonisolated(unsafe) private let lock` | NSLock インスタンス | **削除** — SnapshotStore に内包 |
| `nonisolated(unsafe) private var _snapshotText` | String + NSLock 保護 | **削除** — SnapshotStore に内包 |
| `nonisolated(unsafe) var fileURL` | URL? | `SnapshotStore` 類似パターンまたは `@MainActor` 明示 |

**追加されるプロパティ**:
- `let snapshotStore = SnapshotStore()`

---

## 変更なしコンポーネント

| コンポーネント | 理由 |
|---------------|------|
| **ShoechooApp** | メニューコマンドは FocusedValue 経由で EditorViewModel を取得しており、commandHandler 導入後もチェーンは同一 |
| **EditorSettings** | 変更なし。シングルトン + UserDefaults 永続化 |
| **MarkdownParser** | Sendable struct。変更なし |
| **EditorNodeModel** | @Observable @MainActor class。変更なし |
| **EditorNode / ParseResult** | Sendable struct。変更なし |
| **SyntaxHighlighter** | @MainActor struct。変更なし（FR-04/FR-05 は Cycle 2 後半で対応） |
| **ShoechooTextView** | NSTextView subclass。**軽微な変更**: `performDragOperation()` の呼び出し先が `viewModel.handleImageDrop()` → `ImageDropHandler.handleImageDrop()` に変更。ImageDropHandler への依存が新規追加 |
| **EditorTheme / ThemePresets / ThemeRegistry** | 変更なし |
| **ExportService** | Actor。変更なし（ExportCoordinator が薄いラッパーとして上に載る） |
| **FileService** | Actor。変更なし |
| **ImageService** | Actor。変更なし（ImageDropHandler が薄いラッパーとして上に載る） |
| **EditorView / OutlineView / SidebarView / PreferencesView** | OutlineView の scrollToHeading が NotificationCenter → commandHandler に変更される以外、構造変更なし |
