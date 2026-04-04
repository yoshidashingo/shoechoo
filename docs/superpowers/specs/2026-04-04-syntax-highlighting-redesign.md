# Syntax Highlighting Redesign

## Date: 2026-04-04

## Problem

4つの連鎖するバグが同一のアーキテクチャ欠陥に起因:

- **#9** Dark mode: 背景が暗いのにテキストが黒
- **#10** Line breaks: ブロック間に改行がない
- **#11** Focus mode: ディミング位置がずれる
- **#12** Editing: テキスト編集ができない

## Root Cause

`WYSIWYGTextView.updateNSView()` が `textStorage?.setAttributedString()` でテキスト全体を毎回置換。WYSIWYGレンダリングがソースを変換（`#`削除、`**`除去等）するため、表示テキスト ≠ ソーステキストとなり、編集・範囲計算・改行すべてが破綻。

## Solution: Syntax Highlighting方式

テキスト内容を変更せず、属性（フォント・色・段落スタイル）のみを適用する。

### Changes

1. **新規: `SyntaxHighlighter`** — `NSTextStorage` に属性を直接適用。テキスト内容は一切変更しない。
   - ヘッダ: `#` を残したまま大フォント適用、`#` 部分はセカンダリカラー
   - ボールド: `**text**` のままボールドフォント適用、`**` はセカンダリカラー
   - コードブロック: フェンス含めモノスペースフォント
   - リスト/引用: インデントとマーカーカラー

2. **変更: `WYSIWYGTextView.updateNSView()`** — `setAttributedString` 廃止。代わりに `SyntaxHighlighter.apply()` で属性のみ更新。

3. **変更: `EditorView`** — `appearanceOverride` を `preferredColorScheme` / `NSAppearance` で適用。

4. **変更: `EditorViewModel`** — `attributedStringForDisplay` 廃止。代わりにブロック情報を提供し、`SyntaxHighlighter` が直接 textStorage に適用。

5. **削除対象**: `MarkdownRenderer` の WYSIWYG レンダリングパス（inactive rendering）。Active rendering の構造は `SyntaxHighlighter` に吸収。

### Focus Mode

sourceRange がそのまま表示テキストの位置と一致するため、既存の `applyFocusModeDimming` が正しく動作する。

### Dark Mode

- `NSTextView.backgroundColor` と `NSScrollView.backgroundColor` を appearance に応じて設定
- `appearanceOverride` 設定を `NSAppearance` として view hierarchy に適用
