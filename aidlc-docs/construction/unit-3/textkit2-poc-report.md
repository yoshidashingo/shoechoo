# TextKit 2 PoC Report — Unit 3 (FR-03)

## 現状分析

### macOS 14+ の NSTextView は既にデフォルトで TextKit 2

macOS 13 Ventura 以降、`NSTextView` は `textLayoutManager` を持つ TextKit 2 モードがデフォルト。shoechoo のデプロイメントターゲットは macOS 14 であるため、**現在のアプリは既に TextKit 2 上で動作している**。

### 既存の TextKit 2 使用箇所

`ShoechooTextView.scrollToCenterLine()` (ShoechooTextView.swift:52-53) で:
- `textLayoutManager` — TextKit 2 のレイアウトマネージャー
- `NSTextContentStorage` — TextKit 2 のコンテンツストレージ
- `NSTextRange` — TextKit 2 のレンジ型
- `enumerateTextSegments` — TextKit 2 API

**既に TextKit 2 のネイティブ API を使用しており、IME を含め正常動作している。**

### SyntaxHighlighter の NSTextStorage 操作

`SyntaxHighlighter.apply()` は `NSTextStorage` に `setAttributes` / `addAttribute` で属性を直接設定。これは TextKit 2 環境でも動作する:
- macOS の TextKit 2 `NSTextView` は `NSTextStorage` を backing store として保持
- `NSTextStorage` への属性操作は TextKit 2 レイアウトエンジンが自動的に反映
- `beginEditing()` / `endEditing()` パターンも正常動作

### isRichText の現状

`isRichText = true` (コミット 05b055d で変更済み)。TD-04（isRichText 矛盾）は既に解消済み。

## Go/No-Go 判定

### 評価基準と結果

| 基準 | 結果 | 判定 |
|------|------|------|
| IME 互換性 | macOS 14+ で TextKit 2 デフォルト動作中。日本語入力は Phase 1 で `hasMarkedText()` 保護済み | **PASS** |
| パフォーマンス | NSTextStorage 操作は TextKit 2 でも変わらない。追加の API 移行オーバーヘッドなし | **PASS** |
| NSRange → NSTextRange 全面移行の必要性 | **不要**。NSTextStorage は NSRange (UTF-16) で操作可能。CLAUDE.md の「NSRange 統一」ルールと整合 | **N/A** |

### 判定: **部分的 Go（全面移行は No-Go）**

- **Go**: macOS 14+ で既に TextKit 2 動作中。現在のアーキテクチャ（NSTextStorage ベース）を維持
- **No-Go**: NSRange → NSTextRange への全面移行は不要。リスクが高く、利点が薄い
  - NSTextStorage API は TextKit 2 でも完全サポート
  - NSRange (UTF-16) はパーサー (swift-markdown) の出力と直接対応
  - 全面移行は SyntaxHighlighter 全書き直しが必要（506行）で、バグ導入リスクが高い

### 結論

**追加の TextKit 2 移行作業は不要**。以下の状態が既に達成されている:
1. NSTextView は TextKit 2 モードで動作中
2. `isRichText = true` で矛盾解消済み
3. `textLayoutManager` API は必要な箇所（タイプライタースクロール）で使用中
4. SyntaxHighlighter の NSTextStorage 操作は TextKit 2 環境で正常動作

Unit 4（WYSIWYG 体験向上）は現在のアーキテクチャ上で実装する。

## AC #3 への影響

> TextKit 2 ベース、またはPoC不合格時はTextKit 1 + isRichText=true で安定動作

→ **macOS 14+ で TextKit 2 ベースで安定動作中**。AC #3 クリア。
