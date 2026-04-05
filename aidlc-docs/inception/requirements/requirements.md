# Requirements — Cycle 2: WYSIWYG Editor Refactoring (Rev.3 — Red Team修正)

## Intent Analysis

| 項目 | 内容 |
|------|------|
| **User Request** | WYSIWYGエディタの品質・体験が貧弱でクラッシュが多発。根本的にリファクタリング |
| **Request Type** | Refactoring + Enhancement |
| **Scope** | System-wide（21ソースファイル + 6テストファイル = 27 Swift files） |
| **Complexity** | Complex |
| **Depth** | Comprehensive |

## Red Team Reviews Incorporated

- **Rev.2**: Red Team #1 全11件反映（TD-06/07/08追加、PoC計画、依存グラフ等）
- **Rev.3**: Red Team #2 全11件反映（TD番号修正、Unit分割、ブランチ戦略、MarkdownDocument対応等）

---

## Functional Requirements

### FR-01: NotificationCenter廃止と型安全なコマンドパターン

**優先度**: Critical | **TD対応**: TD-01, TD-05

5つのNotification（`toggleFormatting`, `insertFormattedText`, `setLinePrefix`, `insertImageMarkdown`, `scrollToPosition`）を廃止し、Protocol/Delegate + クロージャのハイブリッドに置換。

- [ ] `EditorCommandHandler` プロトコルを定義
- [ ] Coordinator が `EditorCommandHandler` を実装
- [ ] EditorViewModel が `weak var commandHandler: EditorCommandHandler?` を保持
- [ ] SwiftUI メニューコマンド → EditorViewModel → commandHandler の呼び出しチェーン
- [ ] 全5つの Notification.Name 定義と NotificationCenter 購読を削除
- [ ] `scrollToPosition`（OutlineView.swift:39 から post）も Protocol 経由に移行

**段階的移行方針**:
1. `EditorCommandHandler` プロトコル定義 + Coordinator実装
2. Notification を1つずつ Protocol 呼び出しに置換（各置換後にビルド+テスト）
3. 全Notification置換後に Notification.Name 定義を削除

**ロールバック**: 各Notification単位でコミットするため、問題発生時は該当コミットのみrevert可能

### FR-02: 複数ウィンドウ完全対応

**優先度**: Critical | **依存**: FR-01 完了後

各ウィンドウ/ドキュメントが独立して動作。

- [ ] FR-01のProtocol/Delegate導入でコマンドが特定Coordinatorにのみ伝達されることを保証
- [ ] `EditorViewModel` がウィンドウ固有の状態のみ保持
- [ ] UIテスト: 2ウィンドウ同時操作で干渉なしを検証

### FR-03: TextKit 2 への移行

**優先度**: High | **依存**: FR-01 完了後 | **TD対応**: TD-04

**現状**: `isRichText = true`（コミット05b055dで変更済み）。ShoechooTextView.swift:53 で `textLayoutManager` / `NSTextContentStorage` を既に使用（部分的TextKit 2）。一方 SyntaxHighlighter は `NSTextStorage` 直接操作（TextKit 1）。**TextKit 1/2が混在**。

**移行スコープ**:
- [ ] SyntaxHighlighter を `NSTextContentStorage` + `NSTextLayoutManager` API に対応
- [ ] NSRange（UTF-16）→ NSTextRange への段階的移行
- [ ] ペースト時のリッチ属性除去
- [ ] IME互換性の検証（TextKit 2の`NSTextInputClient`挙動はTextKit 1と異なる）
- [ ] タイプライタースクロールを TextKit 2 API で再実装

**PoC フェーズ（必須）**:
- [ ] 最小限のTextKit 2ベースNSTextView + SyntaxHighlighter PoCを実装
- [ ] IME（日本語入力）の動作検証
- [ ] パフォーマンス比較（TextKit 1 vs TextKit 2、1,000行/10,000行ドキュメント）
- [ ] PoC成功後に本実装へ進む

**ロールバック計画**:
- **撤退基準**: PoC でIME互換性が確保できない、またはパフォーマンスが20%以上劣化
- **撤退方法**: TextKit 1ベースのまま`isRichText = true`で継続
- **判定タイミング**: Unit 3のFunctional Design完了時にGo/No-Go判定

### FR-04: WYSIWYG体験の向上

**優先度**: High | **依存**: FR-03 判定後

- [ ] 非アクティブブロックでのデリミタ非表示の安定化
- [ ] アクティブブロック切替時のちらつき軽減（差分ハイライト適用）
- [ ] カーソル移動時の軽量リハイライト（パース不要、キャッシュ済みブロック使用）
- [ ] EditorNodeModel の position-based diff を活用したインクリメンタルハイライト

### FR-05: コードブロックシンタックスハイライト

**優先度**: Medium | **依存**: FR-04 完了後 | **TD対応**: TD-09

**Highlightr 採用前の評価基準**:
- [ ] Highlightr の最終コミット日、Swift 6対応、macOS 15+互換性を確認
- [ ] 代替候補（TreeSitter ベース等）との比較評価
- [ ] 評価結果に基づき採用ライブラリを決定
- [ ] テーマ連動（`EditorTheme.highlightrTheme`）
- [ ] 言語自動検出または明示指定

### FR-06: insertImageMarkdown バグ修正

**優先度**: High | **依存**: FR-01 と同時実装

- [ ] FR-01で Protocol/Delegate 移行時に画像マークダウン挿入コマンドを含める
- [ ] 画像ドロップ→アセットディレクトリ保存→Markdown構文挿入の完全フローをテスト
- [ ] **注**: FR-06はFR-01の一部として実装。独立FRはトレーサビリティのため

### FR-07: EditorViewModel 責務分割

**優先度**: Medium | **TD対応**: TD-06 | **依存**: なし（独立）

- [x] 統計情報を専用の `DocumentStatistics` struct に抽出 ✅ 実装済み
- [ ] エクスポート関連（ExportCoordinator）をEditorViewModelから分離 — **未実装**（EditorViewModel に残存）
- [ ] 画像ハンドリング（ImageDropHandler）をEditorViewModelから分離 — **未実装**（EditorViewModel に残存）
- [ ] EditorViewModelはUI状態管理とコマンドディスパッチに専念 — **部分達成**（exportHTML/exportPDF/handleImageDrop が残存）

> **実装ステータス**: DocumentStatistics のみ完了。ExportCoordinator/ImageDropHandler はコア機能（FR-01 NotificationCenter廃止）に影響しないため後続対応

### FR-08: heading抽出ロジックの重複解消

**優先度**: Low | **TD対応**: TD-07 | **依存**: なし（独立）

- [ ] パーサー結果からheadingを抽出する単一ユーティリティに統合 — **未実装**

> **実装ステータス**: 未着手。EditorViewModel.headings は手動文字列パースのまま残存。Low 優先度のため後続サイクルで対応

### FR-09: Timer → Task ベースデバウンスへの移行

**優先度**: Medium | **TD対応**: TD-08 | **依存**: なし（FR-01と並行可能）

- [ ] `highlightTimer: Timer?` を `Task` ベースのデバウンスに置換
- [ ] `autoSaveTimer: Timer?` も同様に置換
- [ ] Coordinator の `nonisolated(unsafe)` 3箇所を排除

### FR-10: MarkdownDocument の nonisolated(unsafe) 排除

**優先度**: Medium | **TD対応**: TD-10 | **依存**: なし（独立）

MarkdownDocument の `nonisolated(unsafe)` 4箇所（`viewModel`, `_snapshotText`, `lock`, `_fileURL`）を解消。

- [ ] `_snapshotText` + `lock` は既に `nonisolated(unsafe)` で NSLock保護済み → Sendable wrapper struct に抽出検討
- [ ] `viewModel` の `nonisolated(unsafe)` → `@MainActor` 明示化 + Optional 排除
- [ ] `_fileURL` → lock保護追加 or actor パターンに統合
- [ ] Phase 1で部分修正済み（`DispatchQueue.main.sync`廃止）の確認と残件対応

### FR-11: ARCHITECTURE.md と実装の再設計

**優先度**: Medium | **依存**: 全FR完了後 | **TD対応**: TD-03

- [ ] 現在の実装パイプラインを正式なアーキテクチャとして文書化
- [ ] 不要コンポーネント記述を削除
- [ ] 不整合（ディレクトリ名、デバウンス値等）を統一
- [ ] Concurrency Model テーブルを更新

---

## FR 依存グラフ

```
FR-01 + FR-06 (NotificationCenter廃止、段階的移行)
  │
  ├──→ FR-02 (複数ウィンドウ)
  │
  └──→ FR-03 PoC (TextKit 2) ──→ [Go/No-Go判定]
         │                              │
         ├─ Go ──→ FR-04 (TextKit 2上)  │
         └─ No-Go ──→ FR-04 (TextKit 1上)
                   │
                   └──→ FR-05 (コードブロックハイライト)

FR-07 (ViewModel分割) ── 独立、Unit 1と並行可
FR-08 (heading重複解消) ── 独立、FR-07と同時可
FR-09 (Timer→Task) ── FR-01と並行可
FR-10 (MarkdownDocument unsafe排除) ── 独立

FR-11 (ARCHITECTURE.md) ── 全FR完了後
```

---

## Non-Functional Requirements

### NFR-01: テストカバレッジ 80%以上

- TDDでテスト追加。Swift Testing（`@Test`, `#expect`, `@Suite`）
- カバレッジ計測: `swift test --enable-code-coverage`

### NFR-02: Swift 6 Strict Concurrency 完全準拠

- `nonisolated(unsafe)` を**ゼロ**にする
  - Coordinator 3箇所: FR-09（Timer→Task）で解消
  - MarkdownDocument 4箇所: FR-10 で解消
- `@unchecked Sendable` を可能な限り排除し、proper Sendable or actor 移行

### NFR-03: パフォーマンス

| 指標 | 基準 | 測定方法 |
|------|------|---------|
| ハイライトデバウンス | 0.15秒 | Timer/Task interval |
| カーソル移動リハイライト | 0.02秒以内 | `XCTestMetrics` + `os_signpost` |
| 大規模ドキュメントスクロール | 60fps (Apple Silicon) / 30fps (Intel) | Instruments Core Animation |
| TextKit 2移行後パフォーマンス | TextKit 1ベースラインの80%以上 | PoC時に1,000行/10,000行で比較計測 |

**ベースライン測定**: FR-03 PoC開始前にTextKit 1での計測を実施

### NFR-04: セキュリティベースライン（Enabled）

- 画像パストラバーサル防止、ファイルサイズ制限50MB、XSS防止を維持

### NFR-05: macOS 14+ 互換性

### NFR-06: コード品質

- ファイル400行以下目安、最大800行。関数50行以下
- SyntaxHighlighter.swift（506行）を機能別分割

### NFR-07: E2E / UIテスト基準

| テスト対象 | 検証方法 |
|-----------|---------|
| 複数ウィンドウ独立動作 | XCUITest: 2ウィンドウ同時操作 |
| ちらつき軽減 | 手動検証チェックリスト or スクリーンショット比較 |
| IME互換性 | XCUITest: 日本語入力→変換→確定→ハイライト保持 |
| フォーカスモード | XCUITest: トグル→カーソル移動→dimming適用 |

---

## Acceptance Criteria

1. NotificationCenter による通知が0件
2. 複数ウィンドウで各ドキュメントが独立動作（XCUITestで検証済み）
3. TextKit 2 ベース、またはPoC不合格時はTextKit 1 + isRichText=true で安定動作
4. テストカバレッジ 80%以上
5. コードブロックにシンタックスハイライト動作
6. ARCHITECTURE.md が実装と完全一致
7. 画像D&D→Markdown挿入が正常動作
8. 技術的負債 TD-01〜TD-08, TD-10 が解消（※注記参照）
9. `nonisolated(unsafe)` がpublic/internalインターフェースから排除（※例外: SnapshotStore内部のNSLock保護されたprivate実装、MarkdownDocument.viewModelのReferenceFileDocumentプロトコル制約による1箇所）
10. ビルドエラー0、テスト全通過
11. macOS 14+ で動作確認
12. NFR-03のパフォーマンス基準を全項目クリア

**AC #8 スコープ注記**: TD-09（Unused Highlightr Dependency）はFR-05で対応。TD-03（ARCHITECTURE.md Divergences）はFR-11で対応。時間制約がある場合、FR-11は後続サイクルに延期可。
