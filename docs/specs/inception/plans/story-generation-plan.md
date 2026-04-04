---
layout: default
---

# Story Generation Plan: Shoe Choo

## Story Development Methodology

### Approach: Feature-Based with Persona Mapping
Stories organized around system features (aligned with FR-01 through FR-11), with each story mapped to the relevant user persona. This approach directly mirrors the requirements document and the established feature priority order.

### Story Format
```
As a [persona], I want [action] so that [benefit].

Acceptance Criteria:
- Given [context], when [action], then [result]
```

---

## Execution Checklist

### Phase 1: Persona Development
- [x] Define primary user personas based on target audience
- [x] Document persona characteristics, goals, and pain points
- [x] Save to `aidlc-docs/inception/user-stories/personas.md`

### Phase 2: Story Generation (by Feature Priority)
- [x] Epic 1: WYSIWYG Markdown Editing (FR-01, FR-02) — Critical (10 stories)
- [x] Epic 2: Focus Mode & Typewriter Scrolling (FR-03, FR-04) — High (3 stories)
- [x] Epic 3: Document Management (FR-05) — High (5 stories)
- [x] Epic 4: Export (FR-08) — Medium (2 stories)
- [x] Epic 5: Sidebar (FR-06) — Medium (1 story)
- [x] Epic 6: Image Support (FR-07) — Medium (2 stories)
- [x] Epic 7: Full-Screen & Dark Mode (FR-09, FR-10) — Medium (2 stories)
- [x] Epic 8: Typography (FR-11) — Low (1 story)

### Phase 3: Story Validation
- [x] Verify all stories meet INVEST criteria
- [x] Verify acceptance criteria are testable
- [x] Map all stories to personas
- [x] Save to `aidlc-docs/inception/user-stories/stories.md`

---

## Clarification Questions

Please answer the following questions to refine the user story generation.

## Question 1
What is the expected behavior when typing Markdown syntax in the WYSIWYG editor?

A) Immediate inline rendering — syntax characters disappear as soon as the element is complete (e.g., typing `**bold**` instantly renders as **bold** with no visible asterisks)
B) Delayed rendering — syntax characters remain visible while typing within the element, then render when the cursor moves away from that line/block
C) Toggle rendering — syntax characters are shown when the cursor is on the element, hidden otherwise (like Typora)
X) Other (please describe after [Answer]: tag below)

[Answer]: X (MVP: B → 将来: C)
Typoraの調査結果: TyporaはC（トグルレンダリング）を採用。カーソルがフォーマット要素上にあるとき構文文字（例: `**`）を表示し、離れると非表示にする。これがTyporaの象徴的UX。
Codexレビュー: 最終目標はCだが、TextKit 2での実装を考慮するとMVPではB（段落レベルの遅延レンダリング）を推奨。NSTextContentManagerでカーソルが離れた段落のみレンダリングする方式は、要素レベルのトグル（C）の30%の複雑さで90%のUX効果が得られる。Phase 2でインライン要素レベルのトグル（C）に段階的に移行すべき。

## Question 2
How should the editor handle keyboard shortcuts for Markdown formatting?

A) Standard shortcuts only — Cmd+B for bold, Cmd+I for italic, Cmd+K for link (no custom shortcuts)
B) Comprehensive shortcuts — standard + Cmd+1-6 for headings, Cmd+Shift+K for code, Cmd+Shift+L for list, etc.
C) Minimal — no Markdown-specific shortcuts, users type raw syntax only
X) Other (please describe after [Answer]: tag below)

[Answer]: X (A+ : 標準 + 見出し + インラインコード)
Typoraの調査結果: Typoraは包括的なショートカット（B相当）を提供。Cmd+1-6で見出し、Cmd+Shift+Kでコードブロック、Cmd+Shift+Mで数式、Cmd+Tでテーブル等。
Codexレビュー: MVPにはフルBは過大。高価値サブセットとして: Cmd+B（太字）、Cmd+I（斜体）、Cmd+K（リンク）のシステム標準 + Cmd+1〜6（見出し、行プレフィクス挿入で実装容易かつ効果大）+ Cmd+Shift+K（インラインコード）を推奨。テーブル挿入、数式、ダイアグラムのショートカットはMVP後に追加。

## Question 3
What should happen when a user opens the app without a file?

A) Show a blank new document immediately (like TextEdit)
B) Show a welcome/start screen with recent files and New Document button (like Typora)
C) Show the last opened document (restore session)
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: Typoraは設定によりウェルカム画面表示または前回のドキュメント復元が可能。デフォルトは無題の新規ドキュメント表示で、サイドバーに最近のファイルを表示。
Codexレビュー: NSDocumentベースアプリではAが最適。理由: (1) NSDocumentControllerが「最近使った項目」をファイルメニューに自動提供、(2) ウェルカム画面はNSDocumentのライフサイクルと競合しカスタムUIが必要で複雑さが増す、(3) macOSのState Restoration (NSWindowRestoration)により前回のセッション復元はシステムが無償で提供、(4)「集中」ブランドは即座に書き始められることと合致。

## Question 4
How should the app handle unsupported Markdown extensions (e.g., LaTeX math `$...$`, Mermaid diagrams)?

A) Show the raw syntax as-is (no special handling) — users see the source text
B) Show a styled placeholder block indicating "unsupported element" with the raw content
C) Render as a code block with appropriate language tag
X) Other (please describe after [Answer]: tag below)

[Answer]: C
Typoraの調査結果: TyporaはLaTeX（MathJax）、Mermaidダイアグラム等すべてネイティブレンダリング。しかしShoe ChooのMVPはGFMスコープのため、未サポート拡張のグレースフルデグラデーション戦略が必要。
Codexレビュー: Cが最適。理由: (1) 生のLaTeX/Mermaidソースがレンダリング済みのプロス中に表示されるとバグに見えWYSIWYG感を損なう、(2) 言語タグ付きコードブロック（例: ```math, ```mermaid）は意味的に正しく往復忠実性を保つ、(3) swift-markdownがフェンスドコードブロックを既に識別するため実装が容易、(4) 将来LaTeX/Mermaidレンダリングを追加する際、コードブロックビューをレンダリングビューに置換するだけで自然なアップグレードパスになる。

## Question 5
What is the expected user persona balance?

A) Primary persona is a **writer/blogger** (long-form prose, focus on distraction-free writing)
B) Primary persona is a **developer** (README, documentation, code-heavy Markdown)
C) Equal balance — both writers and developers are primary personas
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: Typoraは両方のユーザーをターゲットにしているが、マーケティングではライティング/プロスUXを前面に出す。コード機能（シンタックスハイライト、ダイアグラム）は二次的な位置づけ。
Codexレビュー: Aが正解。理由: (1)「集中」ブランドは集中した執筆体験を意味し、開発者向けエディタはVS Codeと競合し勝ち目がない、(2) ライター優先によりMVPスコープ判断が簡素化 — プロス段落、見出し、リンク、画像、リストに最適化、(3) TextKit 2は長文リッチテキスト編集に優れた設計で、開発者向けの等幅フォント+tree-sitter統合とは異なるプロダクト、(4) GFMスコープはライターに十分だが開発者はフロントマター、脚注、カスタムコンテナを即座に求める。ターゲット: 現在Typora/Bear/iA Writerを使用し、ネイティブmacOSのWYSIWYG体験を求めるライター。
