# CLAUDE.md

プロジェクト概要・技術スタック・アーキテクチャは `README.md` と `ARCHITECTURE.md` を参照。

## コーディング規約

- **Swift 6 strict concurrency** を遵守。`Sendable`, `@MainActor`, actor を適切に使用
- **`let` 優先**。`var` はコンパイラが要求する場合のみ
- **struct 優先**。`class` は参照セマンティクスが必要な場合のみ（`MarkdownDocument`, `SnapshotStore` 等）
- **NSRange（UTF-16）で統一**。Swift String.Index への変換は行わない（UTF-16 不整合によるクラッシュ防止）
- **ファイルは 400 行以下を目安**、最大 800 行
- **関数は 50 行以下**
- 色は `EditorTheme` プロトコル経由でアクセス。ハードコードしない
- コマンドは `EditorCommandHandler` プロトコル経由で伝達。NotificationCenter は使用禁止

## テスト

- **Swift Testing** フレームワークを使用（`@Test`, `#expect`, `@Suite`）
- テストカバレッジ 80% 以上を目標（現在 207 テスト、16 スイート）
- テストファイルは `shoechooTests/` に配置
- リファクタリング時は TDD（テスト先行）で実施

## NSTextView / NSTextStorage 操作の注意点

過去のバグから得られた重要なルール:

1. **IME 保護**: `textStorage` を変更する前に必ず `textView.hasMarkedText()` をチェック。IME 変換中は操作をスキップし再スケジュールする
2. **再入防止**: `textStorage` の属性変更が `textDidChange` を再発火する可能性がある。`isApplyingHighlight` フラグで防止する
3. **Selection 復元**: `textStorage.endEditing()` 後に NSTextView 内部処理が selection をリセットする。`setSelectedRange` は `DispatchQueue.main.async` で次の RunLoop に遅延する
4. **デッドロック禁止**: `DispatchQueue.main.sync` は絶対に使わない。off-main では `DispatchQueue.main.async` を使用
5. **Snapshot 更新**: `SnapshotStore` 経由で更新。Coordinator が `document` への直接参照で `updateSnapshotText()` を呼ぶ

## 設計判断

- **EditorCommandHandler プロトコル**: NotificationCenter を廃止し、型安全な5メソッドのプロトコルで置換。複数ウィンドウで各Coordinatorにスコープ
- **DebounceTask**: Timer を廃止し、Task ベースのデバウンスに置換。`nonisolated(unsafe)` 排除
- **SnapshotStore**: NSLock 保護の Sendable ラッパー。MarkdownDocument のスレッドセーフ snapshot 管理
- **DocumentStatistics**: EditorViewModel から統計算出を分離した struct
- **Highlightr**: コードブロックの非アクティブ表示でシンタックスハイライト。テーマ連動（`EditorTheme.highlightrTheme`）
- **EditorNodeModel の position-based diff**: ブロック UUID を安定させ、差分ハイライトを実現
- **0.15 秒デバウンス**: ハイライト適用。高速タイピング時の過剰な再パースを防止
- **NSTextView を採用**: SwiftUI TextEditor は attributed string, selection, IME の制御が不十分
- **TextKit 2**: macOS 14+ でデフォルト動作。NSTextStorage ベースの操作は維持（全面 NSTextRange 移行は No-Go）

## nonisolated(unsafe) の例外

AC #9 により public/internal インターフェースから排除。以下は許容される例外:
- `SnapshotStore` 内部の `nonisolated(unsafe) private var _text`（NSLock 保護）
- `MarkdownDocument.viewModel`（ReferenceFileDocument プロトコル制約）
- `MarkdownDocument.fileURL`（@unchecked Sendable クラスの制約）

## DispatchQueue.main.sync の例外

AC により `DispatchQueue.main.sync` は原則禁止。以下は許容される例外:
- `MarkdownDocument.init()` / `init(configuration:)`（NSDocumentController がバックグラウンドキューから呼び出す場合。`Thread.isMainThread` ガード付き。呼び出し元はメインキューのロックを保持しないことが保証されている）
