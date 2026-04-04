# Component Inventory

## Application Packages

### App Layer
- `ShoechooApp.swift` — @main エントリ、DocumentGroup、メニューコマンド定義
- `MarkdownDocument.swift` — ReferenceFileDocument、snapshot/file I/O、viewModel所有

### Models Layer
- `EditorNode.swift` — BlockKind、InlineType、EditorNode value type（パーサー出力）
- `EditorNodeModel.swift` — ブロックリスト管理、position-based diff、アクティブブロック解決
- `EditorViewModel.swift` — @Observable @MainActor、sourceText管理、フォーマットコマンド発行
- `EditorSettings.swift` — UserDefaults-backed @Observable singleton、フォント/外観設定
- `ParseResult.swift` — パーサー出力コンテナ（revision + blocks）

### Parser Layer
- `MarkdownParser.swift` — swift-markdown AST → EditorNode ツリー変換、Sendable struct

### Renderer Layer
- `SyntaxHighlighter.swift` — EditorTheme に基づき NSTextStorage に属性適用（テキスト内容は変更しない）

### Theme Layer
- `EditorTheme.swift` — テーマのカラー/フォントトークン定義
- `ThemePresets.swift` — 7つのプリセットテーマ（GitHub、Newsprint、Night、Pixyll、Whitey、Solarized Dark/Light）
- `ThemeRegistry.swift` — アクティブテーマの選択・永続化管理

### Editor Layer
- `ShoechooTextView.swift` — NSTextView サブクラス：フォーカスdimming、タイプライタースクロール、画像D&D、オートペア
- `WYSIWYGTextView.swift` — NSViewRepresentable + Coordinator（ハイライト、IME保護、フォーカスモード、オートセーブ）

### Views Layer
- `EditorView.swift` — メインエディタシーン、ツールバー、サイドバー統合
- `OutlineView.swift` — ドキュメントアウトライン（見出しナビゲーター）
- `SidebarView.swift` — ファイルツリー/ファイルリスト/アウトライン表示
- `PreferencesView.swift` — 設定UI（フォント、外観、テーマ）

### Services Layer
- `ExportService.swift` — actor。HTML生成（MarkupWalker）+ PDF（WKWebView）
- `FileService.swift` — actor。アトミックファイル書き込み、ディレクトリ作成
- `ImageService.swift` — actor。画像インポート、ファイル名生成、パス検証

## Test Packages
- `EditorNodeTests.swift` — EditorNode value type のユニットテスト
- `EditorNodeModelTests.swift` — EditorNodeModel の diff/merge/アクティブブロックテスト
- `MarkdownParserTests.swift` — パーサーの各ブロック種別テスト
- `SyntaxHighlighterTests.swift` — ハイライター属性適用テスト
- `HTMLConverterTests.swift` — HTML エクスポートテスト

## Total Count
- **Total Source Files**: 21
- **Application**: 17
- **Theme**: 3
- **Services**: 3 (actors)
- **Test Files**: 5
- **Total Lines**: ~3,150 (source) + ~1,500 (tests)
