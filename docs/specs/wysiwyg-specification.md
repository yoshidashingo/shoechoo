# Shoechoo WYSIWYG Editor Specification

## 1. Overview

Markdownソースをプレーンテキストとして`NSTextStorage`に保持し、`NSAttributedString`の属性操作のみでWYSIWYG表示を実現する。テキスト内容は一切変更しない。

## 2. Core Principle: Active / Inactive Block

| 状態 | 定義 | 表示 |
|------|------|------|
| Active | カーソルが存在するブロック | 生Markdownソース + デリミタにdim色 |
| Inactive | カーソルが存在しないブロック | デリミタ不可視 + スタイル適用済み |

### 2.1 「不可視」の定義

- `NSFont.systemFont(ofSize: 0.01)` でフォントサイズを実質ゼロにする
- `foregroundColor` を `backgroundColor` と同色にする（テーマ依存）
- これにより文字はテキストバッファに残るが、視覚的に見えなくなる

### 2.2 ブロック切替のトリガー

- `textViewDidChangeSelection` でカーソル位置変更を検出
- `resolveActiveBlock(cursorOffset:)` で新しいアクティブブロックを特定
- 前回と異なるブロックの場合のみ再ハイライト
- 再ハイライトは既存のパース結果（`nodeModel.blocks`）を使い、再パースしない

## 3. Markdown Elements — 詳細仕様

### 3.1 Block Elements

#### 3.1.1 Heading (`# `, `## `, ... `###### `)

| パーサー | `BlockKind.heading(level:)` |
|---------|---------------------------|
| ソーステキスト | `## Heading text` |
| Active表示 | `## ` をdim色、テキストをheading色・boldフォント・大きいサイズ |
| Inactive表示 | `## ` を不可視、テキストをheading色・boldフォント・大きいサイズ |
| フォントサイズ | H1=28, H2=24, H3=20, H4=18, H5=16, H6=baseSize |

#### 3.1.2 Code Block (` ``` `)

| パーサー | `BlockKind.codeBlock(language:)` |
|---------|--------------------------------|
| ソーステキスト | ` ```swift\nlet x = 1\n``` ` |
| Active表示 | フェンス行にdim色、コードにモノスペースフォント+背景色 |
| Inactive表示 | フェンス行を不可視、コードにモノスペースフォント+背景色 |

#### 3.1.3 Blockquote (`> `)

| パーサー | `BlockKind.blockquote` |
|---------|----------------------|
| ソーステキスト | `> Quote text` |
| Active表示 | `> ` をblockquoteMarkerColor、テキストをblockquoteColor |
| Inactive表示 | `> ` を不可視、テキストをblockquoteColor、インデント+イタリック |

#### 3.1.4 Unordered List (`- `, `* `, `+ `)

| パーサー | `BlockKind.unorderedList` → children: `BlockKind.listItem(marker: .bullet)` |
|---------|----------------------------------------------------------------------------|
| ソーステキスト | `- Item text` |
| Active表示 | `- ` をdim色 |
| Inactive表示 | `- ` を不可視 |

#### 3.1.5 Ordered List (`1. `)

| パーサー | `BlockKind.orderedList` → children: `BlockKind.listItem(marker: .ordered(start:))` |
|---------|-----------------------------------------------------------------------------------|
| ソーステキスト | `1. Item text` |
| Active表示 | `1. ` をdim色 |
| Inactive表示 | `1. ` を不可視 |

#### 3.1.6 Task List (`- [ ] `, `- [x] `)

| パーサー | `BlockKind.taskListItem(isChecked:)` |
|---------|-------------------------------------|
| ソーステキスト | `- [ ] Todo` / `- [x] Done` |
| Active表示 | `- [ ] ` / `- [x] ` をdim色 |
| Inactive表示 | `- [ ] ` / `- [x] ` を不可視 |

#### 3.1.7 Table

| パーサー | `BlockKind.table` → children: `BlockKind.tableRow` |
|---------|--------------------------------------------------|
| ソーステキスト | `\| A \| B \|\n\|---\|---\|\n\| 1 \| 2 \|` |
| Active表示 | `\|` をdim色、全行表示 |
| Inactive表示 | セパレータ行（`\|---\|`）を不可視、`\|` を薄く(20%)、ヘッダ行を太字 |

#### 3.1.8 Horizontal Rule (`---`, `***`, `___`)

| パーサー | `BlockKind.horizontalRule` |
|---------|--------------------------|
| ソーステキスト | `---` |
| Active表示 | `---` をdim色 |
| Inactive表示 | `---` を不可視、strikethrough効果で視覚的な罫線 |

#### 3.1.9 Image (`![alt](url)`)

| パーサー | `BlockKind.image(src:, alt:)` |
|---------|------------------------------|
| ソーステキスト | `![Photo](image.png)` |
| Active表示 | 全テキストをdim色 |
| Inactive表示 | `![` と `](url)` を不可視、altテキストのみ表示 |

### 3.2 Inline Elements

#### 共通ルール

swift-markdownのASTノードはデリミタ文字を範囲に含まない。パーサーの`expandRange()`でデリミタ分を前後に拡張する。

#### 3.2.1 Bold (`**text**`)

| パーサー | `InlineType.bold` |
|---------|-------------------|
| デリミタ | `**` (各2文字) |
| パーサー範囲拡張 | ±2文字 |
| Active表示 | `**` をdim色、テキストをboldフォント |
| Inactive表示 | `**` を不可視、テキストをboldフォント |

#### 3.2.2 Italic (`*text*`)

| パーサー | `InlineType.italic` |
|---------|---------------------|
| デリミタ | `*` (各1文字) |
| パーサー範囲拡張 | ±1文字 |
| Active表示 | `*` をdim色、テキストをitalicフォント |
| Inactive表示 | `*` を不可視、テキストをitalicフォント |

#### 3.2.3 Bold Italic (`***text***`)

| パーサー | `InlineType.boldItalic` |
|---------|------------------------|
| デリミタ | `***` (各3文字) |
| パーサー範囲拡張 | ±3文字 |
| 検出方法 | Strong>Emphasis または Emphasis>Strong のネスト |
| Active表示 | `***` をdim色、テキストをbold+italicフォント |
| Inactive表示 | `***` を不可視、テキストをbold+italicフォント |

#### 3.2.4 Strikethrough (`~~text~~`)

| パーサー | `InlineType.strikethrough` |
|---------|---------------------------|
| デリミタ | `~~` (各2文字) |
| パーサー範囲拡張 | ±2文字 |
| Active表示 | `~~` をdim色、テキストにstrikethrough |
| Inactive表示 | `~~` を不可視、テキストにstrikethrough |

#### 3.2.5 Inline Code (`` `code` ``)

| パーサー | `InlineType.inlineCode` |
|---------|------------------------|
| デリミタ | `` ` `` (各1文字) |
| パーサー範囲拡張 | ±1文字 |
| Active表示 | `` ` `` をdim色、テキストをモノスペース+背景色 |
| Inactive表示 | `` ` `` を不可視、テキストをモノスペース+背景色 |

#### 3.2.6 Link (`[text](url)`)

| パーサー | `InlineType.link(url:)` |
|---------|------------------------|
| 注意 | swift-markdownのLink範囲は `[text](url)` 全体を含む |
| Active表示 | `[` をdim色、テキストをリンク色、`](url)` をdim色 |
| Inactive表示 | `[` を不可視、テキストをリンク色+下線、`](url)` を不可視 |

### 3.3 Inline Elements Inside Block Elements

インライン要素（bold, italic, inline code, link）はリストアイテム、blockquote、テーブルセルの内部でも段落と同じルールで動作する。

| ルール | 詳細 |
|--------|------|
| 同一仕様 | `InlineType.bold` / `.italic` / `.inlineCode` / `.link` の属性付与ロジックは、親ブロックの種類に関わらず同一 |
| Active/Inactive の制御単位 | 親ブロックの Active/Inactive 状態がそのブロック内のすべてのインライン要素を支配する |
| Active親ブロック内 | インラインデリミタ（`**`, `*`, `` ` ``, `[`, `](...)`）をdim色で表示 |
| Inactive親ブロック内 | インラインデリミタを不可視にし、テキストにスタイル適用 |

インライン要素が独自に Active/Inactive 状態を持つことはない。カーソルがリストアイテム内にある場合、そのリストアイテム（またはリスト全体、`ActivationScope` 設定による）が Active となり、アイテム内のすべてのインライン要素も Active として扱われる。

## 4. Data Flow

```
ユーザー操作 (入力 or カーソル移動)
    │
    ├─ テキスト入力 → Coordinator.textDidChange()
    │       │
    │       ├─ viewModel.sourceText = newText
    │       ├─ document.updateSnapshotText(newText)
    │       └─ scheduleHighlight() [150ms debounce]
    │               │
    │               └─ applyHighlightNow()
    │                       ├─ MarkdownParser.parse() → blocks
    │                       ├─ nodeModel.applyParseResult()
    │                       ├─ resolveActiveBlock(cursor) → activeBlockID
    │                       └─ SyntaxHighlighter.apply(textStorage, blocks, activeBlockID, settings, theme)
    │
    └─ カーソル移動 → Coordinator.textViewDidChangeSelection()
            │
            ├─ resolveActiveBlock(cursor) → newActiveID
            └─ if newActiveID ≠ currentActiveBlockID
                    │
                    └─ applyHighlightFromCache() [20ms debounce]
                            └─ SyntaxHighlighter.apply() [再パースなし]
```

## 5. Parser Contract

### 5.1 NSRange (UTF-16)

すべての範囲はNSRange (UTF-16オフセット)。String.Indexは使わない。

### 5.2 Block sourceRange

ブロックの`sourceRange`はドキュメント全体に対する絶対位置。

### 5.3 InlineRun range

`InlineRun.range`はブロックの`sourceText`に対する相対位置。デリミタ文字を含む。

### 5.4 Unicode Scalar Stepping

swift-markdownのcolumnはUnicode scalar単位。パーサーの`utf16Offset`は`unicodeScalars.index(after:)`で進む。

### 5.5 expandRange()

Strong/Emphasis/InlineCode/Strikethroughのノード範囲をデリミタ分拡張。実際のソーステキストでデリミタの存在を検証してから拡張する。

## 6. テキスト同期

### 6.1 初期ロード

`MarkdownDocument.init(configuration:)` は非同期で `sourceText` を設定。`makeNSView` 時点では空の可能性がある。`updateNSView` で `viewModel.sourceText` と `textView.string` の不一致を検出して同期する。

### 6.2 同期時のデリゲート無効化

`textView.string = ...` は `textDidChange` を発火する。同期時はデリゲートを一時的に `nil` にして無限ループを防ぐ。

### 6.3 ウィンドウ復元

macOSがウィンドウを復元する場合、`textView` にテキストがあるが `viewModel.sourceText` が空の状態になる。`updateNSView` で逆方向の同期（textView → viewModel）も行う。

## 7. テーマ

色はすべて `EditorTheme` 経由。ハードコードしない。

| 属性 | 用途 |
|------|------|
| `backgroundColor` | テキストビュー背景、hideRange の不可視色 |
| `textColor` | ベーステキスト色 |
| `headingColors[0-5]` | H1-H6の色 |
| `delimiterColor` | Active時のデリミタ色 |
| `linkColor` | リンクテキスト色 |
| `blockquoteColor` | 引用テキスト色 |
| `blockquoteMarkerColor` | Active時の > マーカー色 |
| `codeBackgroundColor` | コードブロック/インラインコード背景 |
| `cursorColor` | カーソル色 |

## 8. Clipboard Behavior

### 8.1 コピー

エディタからのコピーは**生のMarkdownソース**をクリップボードに格納する。

| 項目 | 仕様 |
|------|------|
| コピー内容 | `NSTextStorage` 内の生テキスト（非表示デリミタを含む） |
| フォーマット | プレーンテキスト（`NSPasteboard.PasteboardType.string`） |
| 属性情報 | クリップボードには含めない |

例: Inactive状態の `**bold**` を選択してコピーすると、クリップボードには `**bold**` という文字列が入る（デリミタが不可視であっても）。

### 8.2 ペースト

ペーストはプレーンテキストとして挿入する。

| 項目 | 仕様 |
|------|------|
| ペースト方式 | プレーンテキスト挿入（リッチテキスト属性を除去） |
| Markdown構文 | 挿入後に通常の150msデバウンスで再パース・再ハイライトされる |
| 外部ソース | HTML等のリッチコンテンツをペーストしても、テキスト部分のみ挿入される |

## 9. Undo/Redo

### 9.1 Undo登録の対象

| 操作 | Undo登録 |
|------|---------|
| ユーザーのテキスト入力 | 登録する |
| フォーマットコマンド（Bold挿入など） | 登録する |
| `SyntaxHighlighter` による属性変更 | **登録しない** |

### 9.2 SyntaxHighlighterがUndoを登録しない方法

`SyntaxHighlighter.apply()` 内での属性変更は必ず以下のパターンで行う:

```swift
textStorage.beginEditing()
// setAttributes / addAttributes / removeAttributes の呼び出し
textStorage.endEditing()
```

`beginEditing()` / `endEditing()` で囲まれた属性のみの変更（テキスト内容の変更を伴わない）は `NSUndoManager` にエントリを登録しない。

### 9.3 実装上の注意

- `textStorage.replaceCharacters(in:with:)` は Undo を登録するため、`SyntaxHighlighter` 内では**絶対に使用しない**。
- ハイライト適用中にテキスト内容が変わることがないよう、`SyntaxHighlighter` は属性操作 API のみを使用する。
- カーソル移動によるブロック切替時の再ハイライト（`applyHighlightFromCache()`）も同じルールに従う。
