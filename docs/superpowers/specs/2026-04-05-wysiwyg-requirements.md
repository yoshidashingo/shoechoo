# WYSIWYG Editor Requirements & Design

## Date: 2026-04-05

## 1. Requirements

### 1.1 Core WYSIWYG Behavior

MarkdownソースをNSTextViewに保持したまま、非アクティブブロックではデリミタを不可視にし、アクティブブロック（カーソルがある）では生Markdownを表示する。

| 要素 | 非アクティブ（WYSIWYG） | アクティブ（編集） |
|------|------------------------|-------------------|
| ヘッダ `# text` | `# ` 不可視、テキスト大きいボールド | `# ` 表示 |
| 太字 `**text**` | `**` 不可視、テキストボールド | `**` 表示 |
| 斜体 `*text*` | `*` 不可視、テキストイタリック | `*` 表示 |
| 太字斜体 `***text***` | `***` 不可視 | `***` 表示 |
| 取消線 `~~text~~` | `~~` 不可視 | `~~` 表示 |
| インラインコード `` `code` `` | `` ` `` 不可視、モノスペース+背景 | `` ` `` 表示 |
| リンク `[text](url)` | `[`, `](url)` 不可視、テキストリンク色+下線 | 全構文表示 |
| コードブロック ` ``` ` | フェンス行不可視、コード背景色 | フェンス表示 |
| 引用 `> text` | `> ` 不可視、インデント+イタリック | `> ` 表示 |
| テーブル | セパレータ行不可視、`|` 薄く、ヘッダ太字 | 全構文表示 |
| 水平線 `---` | テキスト薄く+太ストライクスルー | `---` 表示 |
| 画像 `![alt](url)` | altテキストのみ表示 | 全構文表示 |

### 1.2 「不可視」の定義

- フォントサイズ 0.01pt（NSLayoutManagerで幅ほぼゼロ）
- 前景色 = 背景色（完全に見えない）

### 1.3 ブロック切替タイミング

- カーソル移動（クリック、矢印キー）でアクティブブロック変更 → 即座にWYSIWYG切替
- テキスト入力時は現在ブロックのまま
- IME入力中はWYSIWYG切替しない

### 1.4 テキスト同期

- `MarkdownDocument.init(configuration:)` は非同期で `sourceText` を設定する
- `makeNSView` は `sourceText` が空でも正常動作すべき
- `sourceText` が後から設定された場合、`updateNSView` でテキストを同期してハイライトを発火すべき

## 2. Architecture

```
MarkdownDocument
  └─ EditorViewModel (sourceText, cursorPosition)
       └─ WYSIWYGTextView (NSViewRepresentable)
            ├─ ShoechooTextView (NSTextView)
            │    └─ textStorage (attributes only, never change text)
            ├─ Coordinator
            │    ├─ textDidChange → sourceText更新 + scheduleHighlight
            │    ├─ textViewDidChangeSelection → ブロック切替検出 + 再ハイライト
            │    ├─ applyHighlightNow → parse + SyntaxHighlighter.apply
            │    └─ applyHighlightFromCache → 再ハイライト（再パース不要）
            └─ SyntaxHighlighter.apply(textStorage, blocks, activeBlockID, settings, theme)
                 ├─ 全範囲にベース属性設定
                 ├─ 各ブロック: isActive判定
                 │    ├─ active: デリミタ表示（dim色）
                 │    └─ inactive: デリミタ不可視（hideRange）
                 └─ hideRange: font=0.01pt, fg=bg
```

## 3. Known Issues (Red Team Review)

### CRITICAL

1. **テキスト同期の失敗**: `makeNSView`で`sourceText`が空の場合、`updateNSView`での同期が正しく機能しない可能性がある。`@Observable`の`sourceText`変更がSwiftUI更新サイクルをトリガーしない場合、テキストは永久に空のまま。

2. **ハイライトのトリガー不足**: `scheduleHighlight`がTimer経由（0.15s）だが、`updateNSView`からの呼び出しは`scheduleHighlight()`で非同期。`updateNSView`が完了する前にTimerが発火しない。

3. **`textView.string = viewModel.sourceText` がtextDidChangeを発火**: delegateが設定済みの場合、テキスト設定がdelegateのtextDidChangeを呼び、sourceTextが再設定され、無限ループの可能性。

### HIGH

4. **ブロック境界のギャップ**: パーサーのブロック範囲がドキュメント全体をカバーしない場合（空行等）、カーソルがギャップに入るとactiveBlockIDがnilになりWYSIWYGが全ブロックで無効化。

5. **`isRichText = false` との相互作用**: NSTextViewがプレーンテキストモードの場合、属性変更が内部的にリセットされる可能性（特にユーザー入力直後）。

## 4. Test Strategy

### 4.1 ユニットテスト（SyntaxHighlighter）

既存テストで動作確認済み。SyntaxHighlighter単体は正しい。

### 4.2 統合テスト（必要）

アプリの実際の動作を検証するテスト:

```swift
// テスト: ドキュメントを開いてハイライトが適用されることを検証
@Test func documentLoadTriggersHighlight() async {
    // 1. MarkdownDocumentを作成（テキスト付き）
    // 2. WYSIWYGTextViewのCoordinatorを作成
    // 3. applyHighlightNowを呼ぶ
    // 4. textStorageの属性を検証
}
```

### 4.3 E2Eテスト（Playwright/XCUITest）

実際のアプリウィンドウでの表示を検証:
- スクリーンショット比較
- アクセシビリティAPI経由での属性確認
