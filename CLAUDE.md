# CLAUDE.md

## プロジェクト概要

Shoechoo（集中）は macOS 向けの集中執筆型 Markdown エディタ。Typora のようなインライン WYSIWYG 編集体験を Swift 6 + SwiftUI + AppKit で実現する。

## 技術スタック

- **言語**: Swift 6（strict concurrency）
- **UI**: SwiftUI（ウィンドウ/設定/ツールバー）+ AppKit NSTextView（テキスト編集）
- **パーサー**: [swift-markdown](https://github.com/swiftlang/swift-markdown)
- **テスト**: Swift Testing（`import Testing`, `@Test`, `#expect`）
- **最小動作環境**: macOS 14 Sonoma

## ビルド・テスト

```bash
# ビルド
xcodebuild -scheme shoechoo -destination 'platform=macOS' build

# テスト
xcodebuild -scheme shoechoo -destination 'platform=macOS' test

# テストは Swift Testing フレームワーク使用（◇/✔/✘ 形式の出力）
```

## アーキテクチャ

詳細は `ARCHITECTURE.md` を参照。主要パイプライン:

```
User Input → Coordinator.textDidChange()
  → EditorViewModel.sourceText 更新
  → MarkdownParser.parse() → EditorNodeModel.applyParseResult()
  → SyntaxHighlighter.apply() → NSTextStorage に属性適用
  → Focus Mode dimming（有効時）
```

### ディレクトリ構成

```
shoechoo/
├── App/           # ShoechooApp, MarkdownDocument
├── Models/        # EditorNode, EditorNodeModel, EditorViewModel, EditorSettings
├── Parser/        # MarkdownParser（swift-markdown AST → EditorNode）
├── Renderer/      # SyntaxHighlighter（EditorNode → NSTextStorage 属性）
├── Theme/         # EditorTheme, ThemePresets, ThemeRegistry
├── Editor/        # ShoechooTextView (NSTextView), WYSIWYGTextView (NSViewRepresentable)
├── Views/         # EditorView, SidebarView, OutlineView, PreferencesView
└── Services/      # ExportService, FileService, ImageService（すべて actor）
```

### 主要コンポーネントの責務

| コンポーネント | 責務 |
|---------------|------|
| `MarkdownDocument` | `ReferenceFileDocument`。NSLock で snapshot 保護。viewModel を所有 |
| `EditorViewModel` | `@Observable @MainActor`。sourceText, cursorPosition, フォーマットコマンド |
| `EditorNodeModel` | ブロックリスト管理。position-based diff で ID 保持。アクティブブロック解決 |
| `MarkdownParser` | `Sendable` struct。swift-markdown AST → `[EditorNode]` 変換 |
| `SyntaxHighlighter` | `EditorTheme` に基づき NSTextStorage に属性適用。テキスト内容は変更しない |
| `WYSIWYGTextView.Coordinator` | NSTextViewDelegate。ハイライト、IME 保護、フォーカスモード、オートセーブ |

## 開発ルール

### コーディング規約

- **Swift 6 strict concurrency** を遵守。`Sendable`, `@MainActor`, actor を適切に使用
- **`let` 優先**。`var` はコンパイラが要求する場合のみ
- **struct 優先**。`class` は参照セマンティクスが必要な場合のみ（`MarkdownDocument` 等）
- **NSRange（UTF-16）で統一**。Swift String.Index への変換は行わない（UTF-16 不整合によるクラッシュ防止）
- **ファイルは 400 行以下を目安**、最大 800 行
- **関数は 50 行以下**

### テスト

- **Swift Testing** フレームワークを使用（`@Test`, `#expect`, `@Suite`）
- テストカバレッジ 80% 以上を目標
- テストファイルは `shoechooTests/` に配置

### NSTextView / NSTextStorage 操作の注意点

これらは過去のバグから得られた重要なルール:

1. **IME 保護**: `textStorage` を変更する前に必ず `textView.hasMarkedText()` をチェック。IME 変換中は操作をスキップし再スケジュールする
2. **再入防止**: `textStorage` の属性変更が `textDidChange` を再発火する可能性がある。`isApplyingHighlight` フラグで防止する
3. **Selection 復元**: `textStorage.endEditing()` 後に NSTextView 内部処理が selection をリセットする。`setSelectedRange` は `DispatchQueue.main.async` で次の RunLoop に遅延する
4. **デッドロック禁止**: `DispatchQueue.main.sync` は絶対に使わない。SwiftUI body 評価中に呼ばれるとデッドロックする。off-main では `DispatchQueue.main.async` を使用
5. **Snapshot 更新**: ドキュメント保存用の `_snapshotText` は `windowController` チェーン経由ではなく、Coordinator が `document` への直接参照で更新する

### テーマシステム

- 色は `EditorTheme` プロトコル経由でアクセス。ハードコードしない
- `ThemeRegistry` がアクティブテーマを管理
- プリセットテーマは `ThemePresets.swift` に定義

### コミット規約

```
<type>: <description>

<optional body>
```

type: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

### ドキュメント管理

- **設計ドキュメント**: `docs/` に spec と plan を配置
- **ステアリングファイル**: `.steering/[YYYYMMDD]-[タイトル]/` に作業用ドキュメントを格納
  - `requirements.md` — 要求仕様
  - `design.md` — 設計詳細
  - `tasklist.md` — タスク一覧と進捗

## 既知の設計判断

- **NSTextView を採用**: SwiftUI TextEditor は attributed string, selection, IME の制御が不十分
- **NotificationCenter でコマンド伝達**: SwiftUI メニューコマンドと AppKit NSTextView を疎結合にするため。型安全性の課題あり（将来的にクロージャ/デリゲートへの移行を検討）
- **EditorNodeModel の position-based diff**: ブロック UUID を安定させ、レンダリングキャッシュの無効化を最小化
- **0.15 秒デバウンス**: ハイライト適用のタイマー。高速タイピング時の過剰な再パースを防止
