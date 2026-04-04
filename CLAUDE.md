# CLAUDE.md

プロジェクト概要・技術スタック・アーキテクチャは `README.md` と `ARCHITECTURE.md` を参照。

## コーディング規約

- **Swift 6 strict concurrency** を遵守。`Sendable`, `@MainActor`, actor を適切に使用
- **`let` 優先**。`var` はコンパイラが要求する場合のみ
- **struct 優先**。`class` は参照セマンティクスが必要な場合のみ（`MarkdownDocument` 等）
- **NSRange（UTF-16）で統一**。Swift String.Index への変換は行わない（UTF-16 不整合によるクラッシュ防止）
- **ファイルは 400 行以下を目安**、最大 800 行
- **関数は 50 行以下**
- 色は `EditorTheme` プロトコル経由でアクセス。ハードコードしない

## テスト

- **Swift Testing** フレームワークを使用（`@Test`, `#expect`, `@Suite`）
- テストカバレッジ 80% 以上を目標
- テストファイルは `shoechooTests/` に配置

## NSTextView / NSTextStorage 操作の注意点

これらは過去のバグから得られた重要なルール:

1. **IME 保護**: `textStorage` を変更する前に必ず `textView.hasMarkedText()` をチェック。IME 変換中は操作をスキップし再スケジュールする
2. **再入防止**: `textStorage` の属性変更が `textDidChange` を再発火する可能性がある。`isApplyingHighlight` フラグで防止する
3. **Selection 復元**: `textStorage.endEditing()` 後に NSTextView 内部処理が selection をリセットする。`setSelectedRange` は `DispatchQueue.main.async` で次の RunLoop に遅延する
4. **デッドロック禁止**: `DispatchQueue.main.sync` は絶対に使わない。SwiftUI body 評価中に呼ばれるとデッドロックする。off-main では `DispatchQueue.main.async` を使用
5. **Snapshot 更新**: ドキュメント保存用の `_snapshotText` は `windowController` チェーン経由ではなく、Coordinator が `document` への直接参照で更新する

## 既知の設計判断

- **NSTextView を採用**: SwiftUI TextEditor は attributed string, selection, IME の制御が不十分
- **NotificationCenter でコマンド伝達**: SwiftUI メニューコマンドと AppKit NSTextView を疎結合にするため。型安全性の課題あり（将来的にクロージャ/デリゲートへの移行を検討）
- **EditorNodeModel の position-based diff**: ブロック UUID を安定させ、レンダリングキャッシュの無効化を最小化
- **0.15 秒デバウンス**: ハイライト適用のタイマー。高速タイピング時の過剰な再パースを防止
