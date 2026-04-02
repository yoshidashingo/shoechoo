# Requirements Clarification Questions

Please answer the following questions to help clarify the requirements for Shoe Choo.
Fill in the letter choice after each [Answer]: tag.

---

## Question 1
What is the core rendering approach for the WYSIWYG Markdown editor?

A) TextKit 2 based (NSTextView + custom rendering) — native, fast, but complex to implement inline WYSIWYG
B) WebView based (WKWebView + JavaScript editor like ProseMirror/CodeMirror) — proven WYSIWYG, but less native feel
C) Hybrid (TextKit 2 for editing, WebView for preview only)
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: TyporaはElectron（Chromiumベース）で構築されており、独自フォークのElectronを使用。WYSIWYG編集エリアはカスタム実装で、CodeMirrorはコードフェンスのシンタックスハイライトにのみ使用。
Codexレビュー: Shoe ChooはネイティブmacOSアプリを目指すため、TextKit 2（NSTextView + カスタムレンダリング）が正解。IME、アクセシビリティ、Undo、スペルチェック、テキストシステム統合がAppKitから無償で得られる。WKWebViewはブラウザアーキテクチャに引きずられ「ネイティブTypora」の目標を弱める。

## Question 2
What document management model should the app use?

A) NSDocument-based architecture — standard macOS document handling (open, save, save-as, recent files, tabs)
B) Custom document management — more flexibility but must reimplement standard behaviors
C) Library-based (like iA Writer) — documents stored in a managed folder, shown in sidebar
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: TyporaはmacOS上でドキュメントベースアプリケーションとして動作。OSのオートセーブ機能と連携し、タブ対応、最近使ったファイルの追跡、ドラフト復元（保存済み・未保存・無題）をサポート。標準的な.mdファイルとして保存され完全にポータブル。

## Question 3
What Markdown parsing library should be used?

A) swift-markdown (Apple) — official, maintained, produces typed AST, but lower-level
B) cmark-gfm (GitHub-flavored Markdown via C) — fast, widely used, GFM support
C) Ink (John Sundell) — pure Swift, simpler API, but less actively maintained
D) Custom parser — full control, but significant implementation effort
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: Typoraは独自カスタムパーサーを使用し、内部AST形式に変換。GFM準拠を目指すが「小さな非互換がある場合がある」と明記。Pandocはエクスポート/インポート変換にのみ使用。
Codexレビュー: swift-markdown（Apple公式）が最適。型付きSwift ASTを生成するため、属性付きテキストやエディタセマンティクスへの変換にHTMLを中間モデルにする必要がない。内部的にcmark-gfmを使用しておりGFM仕様準拠も維持される。

## Question 4
How should images in documents be handled?

A) Copy images to an app-managed subfolder next to the .md file (e.g., `filename.assets/`)
B) Reference images by their original file path (no copying)
C) Embed images as Base64 in the Markdown file
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: Typoraのデフォルトは元ファイルパスを参照（B相当）だが、設定で`filename.assets/`へのコピーが可能。YAMLフロントマターの`typora-copy-images-to`プロパティやグローバル設定で切り替え可能。クラウドアップロード（iPic, PicGo, uPic）、相対パス変換、一括画像移動/コピー/ダウンロードもサポート。Shoe Chooではポータビリティを重視しAが推奨。

## Question 5
What is the initial distribution strategy?

A) GitHub Releases only (DMG + ZIP, Developer ID signed, not notarized)
B) GitHub Releases + Apple notarization (Developer ID + notarization for Gatekeeper)
C) Mac App Store only
D) Both GitHub Releases and Mac App Store
X) Other (please describe after [Answer]: tag below)

[Answer]: B
Typoraの調査結果: Typoraは公式サイト（typora.io）からの直接ダウンロードが主な配布チャネル。Mac App Storeでは配布していない。$14.99の買い切りモデル。macOS Catalina以降のGatekeeper要件を考慮すると署名・公証済みと推測される。
Codexレビュー: App Store外で配布するmacOSアプリはDeveloper ID署名+notarizationが必須。未公証だとGatekeeperにブロックされユーザー体験を損なう。OSSでもnotarizationすべき。

## Question 6
Should the app support file browser / sidebar navigation?

A) Yes — sidebar with file tree for a selected folder (like Typora/iA Writer)
B) No — single document window only, open files via system dialogs
C) Minimal — recent files list in a sidebar, but no folder tree
X) Other (please describe after [Answer]: tag below)

[Answer]: C
Typoraの調査結果: Typoraはフルファイルサイドバーを備え、2つの表示モードがある。(1) File Tree: 開いたフォルダの階層表示、(2) File List: 現在のフォルダ内ファイルのフラットリスト。ドラッグ&ドロップでの整理、ファジー検索（Quick Open）、フォルダ全体のグローバル検索、アウトラインパネル（見出し構造の表示）もサポート。
Codexレビュー: フルファイルツリーはMVPには過大で「集中」のコンセプトに反する。ミニマルな最近使ったファイルリスト+標準macOSのOpen/Saveダイアログで十分。フルツリーは後続リリースで追加可能。

## Question 7
What level of Markdown feature support is needed for MVP?

A) Basic — headings, bold, italic, links, images, lists, blockquotes, code blocks, horizontal rules
B) GFM (GitHub Flavored Markdown) — basic + tables, task lists, strikethrough, fenced code blocks
C) Extended — GFM + footnotes, definition lists, table of contents
X) Other (please describe after [Answer]: tag below)

[Answer]: B
Typoraの調査結果: TyporaはExtended以上のMarkdownをサポート。GFM（テーブル、タスクリスト、取り消し線、コードフェンス100+言語）に加え、脚注、目次（[toc]）、LaTeX数式（MathJax）、ダイアグラム（Mermaid、シーケンス図、フローチャート）、下付き/上付き文字、ハイライト、下線、YAMLフロントマター、GitHub-styleアラート/コールアウト、絵文字もサポート。
Codexレビュー: MVPにはGFM（テーブル、タスクリスト、取り消し線、コードフェンス）が適切。脚注、定義リスト、TOC、数式、ダイアグラムはパーサー・レンダリング・編集の複雑さを大幅に増大させる。Extended以降は後続リリースで段階的に追加すべき。

## Question 8
Should the Security Baseline extension be enabled for this project?

A) Yes — enforce security rules throughout the project
B) No — this is a local-only desktop app with no network/auth, skip security extension
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: Typoraはローカル完結型のデスクトップエディタ。ネットワーク通信は画像のクラウドアップロード（オプション）とライセンス認証程度。
Codexレビュー: ローカルアプリでもApp Sandbox（ユーザー選択ファイルアクセス）、Hardened Runtime、標準的なセキュアファイルハンドリングは有効化すべき。「ローカルのみ」は攻撃面を減らすが、macOS標準のセキュリティ姿勢をオプトアウトする理由にはならない。

## Question 9
What is the target for the first release timeline?

A) Prototype / proof of concept (core editor working) — weeks
B) MVP with core features (editing, focus mode, export) — 1-2 months
C) Polished v1.0 release — 3+ months
X) Other (please describe after [Answer]: tag below)

[Answer]: B
Typoraの調査結果: Typoraは長年の開発を経て現在の完成度に至っている（2015年ベータ開始、2021年に正式版1.0リリース）。Shoe ChooのMVPとしてはコアエディタ機能（WYSIWYG編集、フォーカスモード、エクスポート）に絞った1-2ヶ月が現実的。

## Question 10
What is the priority order for the key features?

A) WYSIWYG editing > Focus mode > Export > File sidebar > Dark mode
B) WYSIWYG editing > File sidebar > Dark mode > Focus mode > Export
C) WYSIWYG editing > Dark mode > Export > Focus mode > File sidebar
X) Other (please describe after [Answer]: tag below)

[Answer]: A
Typoraの調査結果: Typoraのマーケティング上の機能優先順位は (1) シームレスなWYSIWYGライブプレビュー（最大の差別化要素）、(2) 集中執筆環境（フォーカスモード・タイプライターモード）、(3) テーマ/カスタマイズ、(4) コードフェンス、(5) 数式、(6) ダイアグラム、(7) テーブル編集、(8) 画像管理、(9) エクスポート、(10) ファイル管理。Shoe Chooも「集中（Shoe Choo）」の名の通り、WYSIWYG編集とフォーカスモードを最優先とする選択肢Aが適切。
