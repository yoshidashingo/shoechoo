# Units of Work — Cycle 2: WYSIWYG Editor Refactoring

## Unit Overview

| Unit | Branch | FR | 概要 | 依存 |
|------|--------|------|------|------|
| **1a** | `refactor/unit-1a-command-handler` | FR-01, FR-06 | NotificationCenter廃止→Protocol/Delegate | なし |
| **1b** | `refactor/unit-1b-multiwindow` | FR-02 | 複数ウィンドウ検証 | 1a |
| **1c** | `refactor/unit-1c-task-debounce` | FR-09 | Timer→Taskデバウンス | なし(1aと並行可) |
| **2** | `refactor/unit-2-model-cleanup` | FR-07, FR-08, FR-10 | ViewModel分割+heading統合+MarkdownDocument unsafe排除 | なし(1aと並行可) |
| **3** | `refactor/unit-3-textkit2-poc` | FR-03 | TextKit 2 PoC+Go/No-Go判定 | 1a |
| **4** | `refactor/unit-4-wysiwyg-highlight` | FR-04, FR-05 | WYSIWYG体験向上+コードブロックハイライト | 3判定後 |
| **5** | `refactor/unit-5-docs-tests` | FR-11, NFR残件 | ARCHITECTURE.md再設計+テスト補完 | 1-4 |

---

## Unit 1a: NotificationCenter廃止（FR-01 + FR-06）

**目的**: 5つのNotification通知をEditorCommandHandlerプロトコルに置換し、型安全性と複数ウィンドウ対応の基盤を構築

**変更対象ファイル**:
- `Models/EditorViewModel.swift` — NotificationCenter.post → commandHandler 呼び出し
- `Editor/WYSIWYGTextView.swift` — Coordinator が EditorCommandHandler を実装、NotificationCenter購読削除
- `Views/OutlineView.swift` — scrollToPosition を commandHandler 経由に変更

**新規ファイル**:
- `Models/EditorCommandHandler.swift` — プロトコル定義

**サブステップ（各ステップ後にビルド+テスト）**:
1. `EditorCommandHandler` プロトコル定義 + Coordinator実装（空メソッド）
2. `toggleFormatting` をProtocol呼び出しに置換
3. `insertFormattedText` を置換
4. `setLinePrefix` を置換
5. `insertImageMarkdown` を置換（FR-06バグ修正）
6. `scrollToPosition` を置換
7. 全Notification.Name定義 + NotificationCenter購読を削除

**完了基準**:
- [ ] NotificationCenter.post が EditorViewModel 内に0箇所
- [ ] NotificationCenter.addObserver が Coordinator 内に0箇所
- [ ] Notification.Name 拡張が削除済み
- [ ] ビルド成功 + 全テスト通過
- [ ] Bold/Italic/Code/Link/Heading/画像挿入/Outlineジャンプが動作

---

## Unit 1b: 複数ウィンドウ検証（FR-02）

**目的**: Unit 1aのProtocol/Delegate導入により複数ウィンドウが独立動作することを検証

**変更対象ファイル**:
- `shoechooTests/` — 新規テスト追加

**タスク**:
1. 2つの独立した EditorViewModel + Coordinator ペアでコマンド干渉なしを検証するユニットテスト
2. XCUITest: 2ウィンドウ同時操作テスト（可能な範囲で）

**完了基準**:
- [ ] テストで複数ウィンドウ独立動作が検証済み
- [ ] ビルド成功 + 全テスト通過

---

## Unit 1c: Timer → Task デバウンス（FR-09）

**目的**: Timer ベースのデバウンスを Task ベースに置換し、nonisolated(unsafe) を排除

**変更対象ファイル**:
- `Editor/WYSIWYGTextView.swift` — Coordinator の Timer → DebounceTask

**新規ファイル**:
- `Models/DebounceTask.swift` — Task ベースデバウンスユーティリティ

**タスク**:
1. DebounceTask クラス実装 + テスト
2. `highlightTimer` → `highlightDebounce: DebounceTask` に置換
3. `autoSaveTimer` → `autoSaveDebounce: DebounceTask` に置換
4. `notificationObservers` 配列の削除（Unit 1a完了後は不要）
5. Coordinator の `nonisolated(unsafe)` が0箇所であることを確認

**完了基準**:
- [ ] Coordinator に `nonisolated(unsafe)` が0箇所
- [ ] Timer import が不要になっている
- [ ] ハイライトデバウンス（0.15秒）とオートセーブが正常動作
- [ ] ビルド成功 + 全テスト通過

---

## Unit 2: Model層クリーンアップ（FR-07 + FR-08 + FR-10）

**目的**: EditorViewModel の責務分割、heading抽出の重複解消、MarkdownDocument の unsafe排除

**変更対象ファイル**:
- `Models/EditorViewModel.swift` — 統計/エクスポート/画像を分離
- `App/MarkdownDocument.swift` — SnapshotStore 使用、fileURL保護
- `Views/EditorView.swift` — 分離されたコンポーネントの参照更新

**新規ファイル**:
- `Models/DocumentStatistics.swift` — 語数/文字数/行数
- `Models/ExportHandler.swift` — エクスポート委譲
- `Models/ImageDropHandler.swift` — 画像D&D処理
- `Models/SnapshotStore.swift` — Sendable snapshot管理

**タスク**:
1. SnapshotStore（final class）実装 + テスト
2. MarkdownDocument に SnapshotStore 導入、lock + _snapshotText を置換
3. DocumentStatistics 実装 + テスト
4. ExportHandler 実装（EditorViewModelから extractHTML/exportPDF を移動）
5. ImageDropHandler 実装（handleImageDrop を移動）
6. EditorViewModel のメソッド削除 + 参照更新
7. heading抽出ロジックの統合（FR-08）

**完了基準**:
- [ ] EditorViewModel が UI状態管理 + コマンドディスパッチのみ
- [ ] MarkdownDocument の lock + _snapshotText が SnapshotStore に集約
- [ ] heading抽出が単一ユーティリティに統合
- [ ] ビルド成功 + 全テスト通過

---

## Unit 3: TextKit 2 PoC + Go/No-Go判定（FR-03）

**目的**: TextKit 2 移行の実現可能性を検証し、Go/No-Go を判定

**タスク**:
1. **ベースライン計測**: TextKit 1 でのハイライト速度（1,000行/10,000行）を `os_signpost` で計測・記録
2. **PoC実装**: 最小限の TextKit 2 NSTextView + 簡易 SyntaxHighlighter
3. **IMEテスト**: 日本語入力→変換→確定→ハイライト保持を検証
4. **パフォーマンス比較**: 同条件で TextKit 2 の速度を計測
5. **Go/No-Go判定**

**Go条件**: IME正常 + パフォーマンスがTextKit 1の80%以上
**No-Go条件**: IME問題 or パフォーマンス20%以上劣化
**No-Go時**: ブランチ破棄、TextKit 1 + isRichText=true で継続

**完了基準**:
- [ ] ベースライン計測データが記録済み
- [ ] PoC でIMEテスト実施済み
- [ ] パフォーマンス比較データが記録済み
- [ ] Go/No-Go 判定が明確に文書化

---

## Unit 4: WYSIWYG体験向上 + コードブロックハイライト（FR-04 + FR-05）

**目的**: 差分ハイライト、ちらつき軽減、Highlightrによるコードブロックハイライト

**依存**: Unit 3 Go → TextKit 2上で実装 / No-Go → TextKit 1上で実装

**変更対象ファイル**:
- `Renderer/SyntaxHighlighter.swift` — 差分ハイライト、Highlightr統合
- `Editor/WYSIWYGTextView.swift` — カーソル移動時の軽量リハイライト

**タスク**:
1. Highlightr の評価（最終コミット日、Swift 6対応、代替候補との比較）
2. 採用ライブラリを決定
3. カーソル移動時の軽量リハイライト実装（パース不要）
4. 差分ハイライト（変更ブロックのみ再適用）
5. コードブロック内シンタックスハイライト統合
6. テーマ連動（`EditorTheme.highlightrTheme`）

**完了基準**:
- [ ] カーソル移動でブロック切替がちらつきなく動作
- [ ] コードブロックに言語別シンタックスハイライトが適用
- [ ] ビルド成功 + 全テスト通過

---

## Unit 5: ドキュメント再設計 + テスト補完（FR-11 + NFR残件）

**目的**: ARCHITECTURE.md を実装に合わせて全面改訂、テストカバレッジ80%達成

**タスク**:
1. ARCHITECTURE.md を現在の実装パイプラインに合わせて改訂
2. CLAUDE.md の NSRange ルール更新（TextKit 2移行時）
3. 未テストコンポーネントのテスト追加:
   - EditorViewModel（toggleBold, setHeading等）
   - MarkdownDocument（save/load cycle）
   - Coordinator（EditorCommandHandler経由のコマンド）
   - ImageService（パストラバーサル防止、サイズ制限）
4. カバレッジ計測: `swift test --enable-code-coverage` で80%+を確認
5. 最終ビルド検証

**完了基準**:
- [ ] ARCHITECTURE.md が実装と完全一致
- [ ] テストカバレッジ 80%以上
- [ ] 全AC 12項目をクリア
- [ ] ビルドエラー0 + 全テスト通過
