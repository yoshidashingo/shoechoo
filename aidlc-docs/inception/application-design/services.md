# Services — Cycle 2: Refactoring

> サービス層の設計。既存 actor サービスは変更なし。
> リファクタリングの主要変更は EditorViewModel のコマンドディスパッチフローの刷新。

---

## Service Architecture（リファクタリング後）

```
+------------------+     +------------------+     +------------------+
|  MarkdownParser  |     |  ExportService   |     |  ImageService    |
|  (struct)        |     |  (actor)         |     |  (actor)         |
|  - parse()       |     |  - generateHTML()|     |  - importDropped |
|                  |     |  - generatePDF() |     |  - importPasted  |
+------------------+     +--------+---------+     +--------+---------+
         |                        |                        |
         v                        v                        v
+------------------+     +------------------+     +------------------+
| EditorViewModel  |     | ExportCoordinator|     | ImageDropHandler |
| (per-document)   |     | (struct)         |     | (struct)         |
+--------+---------+     +------------------+     +--------+---------+
         |                                                 |
         | weak var commandHandler                         | commandHandler
         v                                                 v
+-------------------------------------------------------------------+
|              EditorCommandHandler (protocol)                       |
|              実装: WYSIWYGTextView.Coordinator                     |
+-------------------------------------------------------------------+
         |
         v
+------------------+
| EditorNodeModel  |
| (intermediate)   |
+------------------+
```

---

## S-01: Parsing Service（MarkdownParser）— 変更なし

| 属性 | 詳細 |
|------|------|
| **タイプ** | `struct`（Sendable、stateless、synchronous） |
| **利用元** | WYSIWYGTextView.Coordinator.applyHighlightNow() |
| **責務** | Markdown ソーステキストを swift-markdown AST 経由で EditorNode 配列に変換 |
| **並行性** | 同期 — 典型的なドキュメントではメインスレッドで十分高速 |
| **エラー処理** | 失敗しない — 不正な Markdown はベストエフォートの AST を生成 |

### オーケストレーションパターン（現在と同一）
1. Coordinator.textDidChange が呼ばれる
2. scheduleHighlight() → applyHighlightNow()
3. `MarkdownParser().parse(text, revision: 0)` を呼び出し
4. `nodeModel.applyParseResult(result)` で EditorNodeModel を更新
5. `SyntaxHighlighter().apply(to:blocks:activeBlockID:settings:theme:)` で表示更新

**現在の実装箇所**: WYSIWYGTextView.swift:172-174

---

## S-02: Rendering Service（SyntaxHighlighter）— 変更なし

| 属性 | 詳細 |
|------|------|
| **タイプ** | `@MainActor struct`（stateless、synchronous） |
| **利用元** | WYSIWYGTextView.Coordinator |
| **責務** | EditorNode ブロック配列を NSTextStorage の属性として適用 |
| **並行性** | 同期 — @MainActor |
| **エラー処理** | 範囲外アクセスを guard でスキップ |

> **注**: Cycle 1 の設計書で「MarkdownRenderer」と記載されていたコンポーネントは、
> 実装では `SyntaxHighlighter` として実現されている。NSAttributedString を新規生成するのではなく、
> 既存の NSTextStorage に対して属性を直接適用するアーキテクチャ。

### オーケストレーションパターン（現在と同一）
1. applyHighlightNow() または applyHighlightFromCache() から呼び出し
2. NSTextStorage 全体にベース属性を設定
3. 各ブロックに対して kind + isActive に応じた属性を適用
4. アクティブブロック: デリミタを delimiterColor で表示
5. 非アクティブブロック: デリミタを非表示（font 0.01pt + bgColor）

**現在の実装箇所**: SyntaxHighlighter.swift 全体（506行）

---

## S-03: Export Service（ExportService）— 変更なし

| 属性 | 詳細 |
|------|------|
| **タイプ** | `actor`（async、singleton: `.shared`） |
| **利用元** | ExportCoordinator（リファクタリング後）。現在は EditorViewModel |
| **責務** | Markdown ソースから HTML/PDF を生成 |
| **並行性** | async — PDF 生成は WKWebView を使用するため時間がかかる |
| **エラー処理** | PDF 生成で WKWebView のナビゲーションエラーを throw |

### API（変更なし）
```swift
actor ExportService {
    static let shared = ExportService()
    func generateHTML(from source: String, title: String) -> String
    @MainActor func generatePDF(from html: String) async throws -> Data
}
```

### 内部コンポーネント
- `HTMLConverter: MarkupWalker` — swift-markdown AST を HTML 文字列に変換（ExportService.swift:10-171）
- `WebViewLoadDelegate` — WKWebView のページロード完了を待機（ExportService.swift:176-199）

### オーケストレーションパターン（リファクタリング後）
```
User triggers Cmd+Shift+E
    |
    v
EditorView (SwiftUI) — export ボタン / メニューコマンド
    |
    v
ExportCoordinator.exportHTML(from: sourceText, title:)
    |
    v
ExportService.generateHTML(from:title:)
    |
    +---> (PDF の場合) ExportService.generatePDF(from: html)
    |
    v
Save dialog → write to disk
```

**変更点**: EditorViewModel.exportHTML()/exportPDF() → ExportCoordinator 経由に変更。
ExportService actor 自体は無変更。

---

## S-04: Image Service（ImageService）— 変更なし

| 属性 | 詳細 |
|------|------|
| **タイプ** | `actor`（async、singleton: `.shared`） |
| **利用元** | ImageDropHandler（リファクタリング後）。現在は EditorViewModel |
| **責務** | 画像アセットのインポートとファイル管理 |
| **並行性** | async — ファイル I/O |
| **エラー処理** | `ImageServiceError.fileTooLarge` を throw（50MB 制限） |

### API（変更なし）
```swift
actor ImageService {
    static let shared = ImageService()
    func importDroppedImage(from urls: [URL], to assetsDir: URL) async throws -> [String]
    func importPastedImage(from imageData: Data, to assetsDir: URL) async throws -> String
    func generateFilename(originalName: String?) -> String
    func validateImagePath(_ path: String) -> Bool
}
```

### セキュリティ対策（現在と同一）
- パストラバーサル防止: `../` と `..\\` を拒否
- 絶対パス拒否: `/` 先頭と `:\\` を拒否
- ファイルサイズ制限: 50MB
- 拡張子ホワイトリスト: png, jpg, jpeg, gif, tiff, tif, webp

### オーケストレーションパターン（リファクタリング後）
```
User drops image on editor
    |
    v
ShoechooTextView.performDragOperation()
    |
    v
ImageDropHandler.handleImageDrop(urls:documentURL:insertionPosition:commandHandler:)
    |
    +---> ImageService.importDroppedImage(from:to:)
    |         +---> FileService.createDirectoryIfNeeded()
    |         +---> FileService.safeWrite()
    |         +---> Return [relativePath]
    |
    v
commandHandler.insertImageMarkdown("![](path)", at: position)
    |
    v
Normal editing flow (re-parse, re-render)
```

**変更点**:
- EditorViewModel.handleImageDrop() → ImageDropHandler に移行
- NotificationCenter.post(.insertImageMarkdown) → commandHandler.insertImageMarkdown() 直接呼び出し
- ImageService actor 自体は無変更

---

## S-05: File Service（FileService）— 変更なし

| 属性 | 詳細 |
|------|------|
| **タイプ** | `actor`（async、singleton: `.shared`） |
| **利用元** | ImageService, MarkdownDocument |
| **責務** | 低レベルファイルシステム操作 |
| **並行性** | async — ファイル I/O |
| **エラー処理** | Foundation エラーを throw |

### API（変更なし）
```swift
actor FileService {
    static let shared = FileService()
    func createDirectoryIfNeeded(at url: URL) async throws
    func fileExists(at url: URL) -> Bool
    func safeWrite(_ data: Data, to url: URL) async throws
}
```

---

## EditorViewModel コマンドディスパッチフロー（リファクタリング後）

### 現在のフロー（NotificationCenter ベース）

```
SwiftUI Menu Command / Toolbar Button
    |
    v
EditorViewModel.toggleBold() / toggleItalic() / ...
    |
    v
EditorViewModel.toggleInlineFormatting(prefix:suffix:)  [private]
    |
    v
NotificationCenter.default.post(name: .toggleFormatting, userInfo: ["prefix": ..., "suffix": ...])
    |
    v (broadcast — 全ウィンドウの全 Coordinator が受信)
    |
    v
Coordinator.registerNotifications() の Observer クロージャ
    |
    v
MainActor.assumeIsolated { self?.handleToggleFormatting(prefix:suffix:) }
    |
    v
NSTextView.insertText(_:replacementRange:)
```

**問題点**:
1. 型安全性なし — userInfo は `[String: Any]` でキャスト失敗がランタイムエラー
2. 複数ウィンドウ問題 — broadcast により全 Coordinator が同一コマンドを受信（FR-02 違反）
3. `MainActor.assumeIsolated` — Timer コールバックからの unsafe ブリッジ
4. insertImageMarkdown — Coordinator 側に受信ハンドラが未登録（FR-06 バグ）

### リファクタリング後のフロー（Protocol/Delegate ベース）

```
SwiftUI Menu Command / Toolbar Button
    |
    v
EditorViewModel.toggleBold() / toggleItalic() / ...
    |
    v
EditorViewModel.commandHandler?.toggleFormatting(prefix: "**", suffix: "**")
    |
    v (direct method call — 特定の Coordinator のみ)
    |
    v
Coordinator.toggleFormatting(prefix:suffix:)  [EditorCommandHandler protocol]
    |
    v
NSTextView.insertText(_:replacementRange:)
```

**改善点**:
1. 型安全 — protocol メソッドのパラメータは静的型付き
2. 複数ウィンドウ対応 — weak reference により特定ドキュメントの Coordinator のみにディスパッチ
3. MainActor 保証 — protocol が `@MainActor` で宣言されており、Coordinator は @MainActor class
4. insertImageMarkdown — protocol メソッドとして明示的に定義・実装

### OutlineView からのスクロール（リファクタリング後）

```
OutlineView: heading タップ
    |
    v
viewModel.commandHandler?.scrollToPosition(heading.position)
    |
    v (direct method call)
    |
    v
Coordinator.scrollToPosition(_:)
    |
    v
NSTextView.setSelectedRange() + scrollRangeToVisible()
```

**現在**: `NotificationCenter.default.post(name: .scrollToPosition, ...)` — OutlineView.swift:39-44
**変更後**: `viewModel.commandHandler?.scrollToPosition()` — 直接呼び出し
