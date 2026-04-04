---
layout: default
---

# Functional Design Plan: Unit 1 — Core Editor Engine

## Unit Context
- **Unit**: Core Editor Engine
- **Components**: C-05 MarkdownParser, C-06 EditorNodeModel, C-07 MarkdownRenderer, C-08 WYSIWYGTextView
- **Stories**: 1.1–1.10 (WYSIWYG Editing)
- **Priority**: Critical — foundation for all other units

## Execution Checklist

### Phase 1: Domain Entities
- [ ] Define EditorNode block types and inline run types
- [ ] Define rendering state model (active vs inactive blocks)
- [ ] Save to `domain-entities.md`

### Phase 2: Business Logic Model
- [ ] Define parsing pipeline (source text → AST → EditorNodeModel)
- [ ] Define incremental update algorithm (edit → re-parse affected blocks)
- [ ] Define rendering pipeline (EditorNodeModel → NSAttributedString)
- [ ] Define cursor tracking and active block switching logic
- [ ] Save to `business-logic-model.md`

### Phase 3: Business Rules
- [ ] Define paragraph-level delayed rendering rules
- [ ] Define GFM element rendering rules (per-type: heading, bold, italic, link, code, table, list, task, blockquote, image, HR)
- [ ] Define IME composition handling rules
- [ ] Define unsupported extension fallback rules
- [ ] Save to `business-rules.md`

### Phase 4: Frontend Components
- [ ] Define WYSIWYGTextView interaction model
- [ ] Define keyboard shortcut mapping
- [ ] Save to `frontend-components.md`

---

## Clarification Questions

## Question 1
How should incremental re-parsing work when the user edits text?

A) Re-parse only the edited block (paragraph/heading/etc.) — fastest, but may miss cross-block effects (e.g., opening a code fence)
B) Re-parse the edited block plus adjacent blocks — balanced approach for detecting multi-block elements
C) Re-parse the entire document on every edit — simplest to implement, may be slow on large documents
X) Other (please describe after [Answer]: tag below)

[Answer]: C
Claude Code分析: swift-markdownは増分パースAPIを持たず、クロスブロック効果（コードフェンス開始で後続ブロックすべてが変化等）は実在する。cmark（C実装）は大きなドキュメントでも極めて高速であり、MVPでのボトルネックはパースよりもNSAttributedStringの適用・レンダリング側にある。
Codexレビュー: Cが最適。正確性と実装コストが決め手。MVPの最適分割は「正確性のための全ドキュメントパース + UI コスト制御のための選択的ブロック再レンダリング」。実装戦略: (1) 編集ごとにパーサーアクターでオフメインスレッド解析、(2) 旧/新EditorNodeModel配列を安定IDとコンテンツハッシュでdiff、(3) 変更された非アクティブブロックのみNSAttributedStringに再レンダリング、(4) TextKit 2のテキスト要素/段落範囲で該当領域のみ置換。リスク軽減: ドキュメントリビジョンで古い結果を破棄、短いデバウンスでキーストロークごとの再パースを抑制、IME composition中のアクティブブロック置換を回避。将来の最適化パスも同じAPIの背後に隠蔽可能。

## Question 2
How should the active block boundary be defined for paragraph-level delayed rendering?

A) Structural block — the AST-level block containing the cursor (paragraph, heading, list item, code block as a whole)
B) Visual line — the single line the cursor is on
C) Paragraph cluster — the paragraph plus any attached inline elements (e.g., a paragraph followed by its sub-list)
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Claude Code分析: Typoraは要素レベルのトグルだが、Shoe ChooのMVPは段落レベルの遅延レンダリング。TextKit 2のNSTextParagraphが自然な単位であり、構造ブロック（A）はswift-markdownのASTノードに直接マッピングされる。コードブロック内のどこにカーソルがあっても全体を生表示すべきであり、視覚行（B）では不十分。
Codexレビュー: Aが最適。構造ブロック＋構文種別ごとの明示的ルールを推奨。MVP境界ルール: 段落/見出し→そのノード、コードフェンス→ブロック全体（フェンス構文+内容すべて）、テーブル→テーブル全体（行をまたぐ構造）、リスト項目→現在のリスト項目のみ（リスト全体ではない）、ブロック引用→引用内の現在の子ブロック（引用コンテナ全体ではない）、ブロック引用内のネストリスト→最内のリスト項目。UX上の利点: 「編集中のブロックは生表示、他はレンダリング済み」という説明可能な動作。実装: EditorNodeModelに`kind`、`sourceRange`、`containerPath`、`activationScope`を格納し、キャレット位置→ソースオフセット変換→最内ノード検出→ルールで正規化→アクティブノードとしてマーク。
