# Application Design — Cycle 2: Consolidated (Rev.2 — Red Team修正)

## Overview

本ドキュメントはCycle 2リファクタリングのApplication Design成果物を統合したものです。

## 成果物一覧

| ファイル | 内容 | 行数 |
|---------|------|------|
| `components.md` | 新規6コンポーネント定義 + 既存4コンポーネント変更 | ~350 |
| `component-methods.md` | 全メソッドシグネチャ（Swiftコード付き） | ~449 |
| `services.md` | サービス層設計、コマンドディスパッチフロー比較 | ~289 |
| `component-dependency.md` | 依存グラフ、NotificationCenter/nonisolated(unsafe)排除 | ~316 |
| `archive-cycle1/` | Cycle 1のunit-of-work定義（アーカイブ、参照しないこと） | — |

## Red Team #3 で修正された設計判断

### MarkdownDocument.init(configuration:) の @MainActor 制約
`ReferenceFileDocument.init(configuration:)` は Apple プロトコル定義で @MainActor ではない。off-main スレッドから呼ばれる可能性があるため、`viewModel` の `nonisolated(unsafe)` を維持。現在の設計（off-main では `DispatchQueue.main.async` で遅延初期化）を継続。

### SnapshotStore の型: final class（struct ではない）
内部に NSLock + mutable state を持つため、struct（値型コピー）は不適切。`final class: Sendable` が正しい型。内部の `nonisolated(unsafe) private var _text` は NSLock で完全保護された private 実装詳細として AC #9 の例外。

### AC #9 の例外注記
macOS 14+ では `Mutex<String>`（Swift 6.2+/macOS 15+）が利用不可。以下を例外として許容:
- `SnapshotStore` 内部の `nonisolated(unsafe) private var _text`（NSLock保護）
- `MarkdownDocument.viewModel` の `nonisolated(unsafe)`（ReferenceFileDocument制約）

## 新規コンポーネント

| コンポーネント | タイプ | FR対応 | 目的 |
|---------------|--------|--------|------|
| `EditorCommandHandler` | protocol | FR-01 | 5つの編集コマンドの型安全インターフェース |
| `DocumentStatistics` | struct | FR-07 | 語数/文字数/行数（ViewModelから分離、ハイライト時にデバウンス更新） |
| `ExportCoordinator` | struct | FR-07 | HTML/PDFエクスポート委譲 — **未実装**（EditorViewModel に残存） |
| `ImageDropHandler` | struct | FR-07 | 画像D&D処理（ViewModelから分離） — **未実装**（EditorViewModel に残存） |
| `DebounceTask` | class | FR-09 | Task ベースデバウンス（Timer置換） |
| `SnapshotStore` | final class | FR-10 | Sendable snapshot管理（NSLock内包） |

## 既存コンポーネントの変更

| コンポーネント | 変更内容 |
|---------------|---------|
| `EditorViewModel` | 責務縮小: 統計/エクスポート/画像を分離。`weak var commandHandler` を保持 |
| `WYSIWYGTextView.Coordinator` | `EditorCommandHandler` を実装。Timer → DebounceTask。NotificationCenter購読削除。commandHandler は `makeNSView` で設定 |
| `MarkdownDocument` | SnapshotStore 使用。viewModel の nonisolated(unsafe) は維持（プロトコル制約） |
| `ShoechooTextView` | `performDragOperation()` の呼び出し先変更（ImageDropHandler へ） |
