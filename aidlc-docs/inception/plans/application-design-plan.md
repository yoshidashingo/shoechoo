# Application Design Plan: Shoe Choo

## Design Approach
MVVM architecture with SwiftUI as the primary UI framework and AppKit integration for the core editor (NSTextView/TextKit 2). Components organized by responsibility with clear dependency boundaries.

## Execution Checklist

### Phase 1: Component Identification
- [x] Identify core components and responsibilities (13 components)
- [x] Define component boundaries and interfaces
- [x] Save to `aidlc-docs/inception/application-design/components.md`

### Phase 2: Component Methods
- [x] Define method signatures for each component
- [x] Define input/output types
- [x] Save to `aidlc-docs/inception/application-design/component-methods.md`

### Phase 3: Service Layer
- [x] Define services and orchestration patterns (5 services)
- [x] Save to `aidlc-docs/inception/application-design/services.md`

### Phase 4: Dependencies
- [x] Map component dependency relationships
- [x] Define communication patterns and data flow (4 primary flows)
- [x] Save to `aidlc-docs/inception/application-design/component-dependency.md`

### Phase 5: Consolidated Design
- [x] Create consolidated application-design.md
- [x] Validate design completeness and consistency

---

## Design Clarification Questions

## Question 1
How should the SwiftUI/AppKit boundary be structured for the editor?

A) SwiftUI shell with NSViewRepresentable wrapping a single NSTextView — SwiftUI handles window, toolbar, sidebar; AppKit handles only the text editing surface
B) Primarily AppKit (NSViewController-based editor) embedded in SwiftUI via NSViewControllerRepresentable — more AppKit control over text system lifecycle
C) Full AppKit window with SwiftUI views embedded for sidebar and preferences only
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: TyporaはElectronベースのためUI境界の参考にはならないが、エディタ表面とその周囲のUI（サイドバー、ツールバー等）を明確に分離している設計思想は共通。
Codexレビュー: Aが最適。エディタ表面のみAppKit（NSTextView + TextKit 2）にし、それ以外はSwiftUIが担当する構成。理由: (1) TextKit 2はNSTextViewが必須だがウィンドウ全体をAppKitにする必要はない、(2) Focus Mode・Typewriter ScrollingはNSTextViewの振る舞いなのでラップされたAppKit surface内に収まる、(3) NSDocumentはSwiftUIホストのドキュメントウィンドウで問題なく動作、(4) BはMVPに不要なコントローラ中心アーキテクチャ、CはレガシーUI基盤に過度に依存。構成: SwiftUIドキュメントシーン → NSViewRepresentable（カスタムNSTextView） → AppKitがTextKit 2、選択、スクロール、段落レベルレンダリングを担当。

## Question 2
How should the Markdown rendering pipeline be structured?

A) Two-stage: Parser (swift-markdown AST) → Renderer (AST → NSAttributedString) — clean separation, renderer maps AST nodes to text attributes
B) Three-stage: Parser → Intermediate Model (app-specific node types) → Renderer — more flexibility for custom rendering rules but more code
C) Unified: Parser + Renderer combined in one component — simpler but harder to test independently
X) Other (please describe after [Answer]: tag below)

[Answer]: B
Typoraの調査結果: Typoraは独自カスタムパーサーで内部AST形式に変換し、そこからレンダリング。エクスポート時のみPandocを使用。独自の中間モデルを持つ三段階構成に近い。
Codexレビュー: Bが最適。理由: (1) 段落レベルの遅延レンダリング（カーソルがある段落は生構文、離れた段落はレンダリング済み）には「どのブロックがソース表示中か」を追跡する編集モデルが必要で、直接AST→NSAttributedStringでは対応困難、(2) 中間モデルにより変更ブロックのみ増分再レンダリング可能（全ドキュメント再パースを回避）、(3) NSDocumentは正規のMarkdownソースを永続化し、中間モデルは一時的・per-document、(4) MVP中間モデル: 安定IDとソース範囲を持つブロックレベルエディタノード（段落、見出し、リスト項目、タスク、コードブロック、引用、テーブル、水平線 + インラインラン）。Aでは遅延レンダリング追加時にレンダラーが隠れた中間モデル化する。

## Question 3
How should editor state (cursor position, scroll offset, focus mode, zoom) be managed?

A) Single EditorViewModel (@Observable) owns all editor state — simple, centralized
B) Split: EditorViewModel for document content + EditorSettings for UI preferences (persisted) — cleaner separation
C) Per-document state model attached to NSDocument — each document tracks its own cursor, scroll, focus mode state
X) Other (please describe after [Answer]: tag below)

[Answer]: B
Typoraの調査結果: Typoraはドキュメントごとの状態（カーソル、スクロール）とアプリ全体の設定（テーマ、フォント）を分離して管理。各ドキュメントウィンドウは独立した編集状態を持つ。
Codexレビュー: Bが最適。各NSDocumentが自身のEditorViewModelを生成し、EditorSettingsはアプリ全体で共有・永続化。具体的な責務分担: EditorViewModel（per-document）= ソーステキスト/レンダリングブロックモデル連携、選択・カーソル位置、スクロールオフセット、フォーカスモード有効/無効、タイプライタースクロール有効/無効、アクティブ段落の一時的レンダリング状態。EditorSettings（共有）= フォントファミリー/サイズ、テーマ/外観、エディタ全体のデフォルト。Aは複数ウィンドウでグローバル状態が偶発的に共有される。Cはファイル永続化とライブエディタセッションを過度に結合させる（NSDocumentは永続化指向、テキストシステムはビュー駆動の高速状態変更）。
