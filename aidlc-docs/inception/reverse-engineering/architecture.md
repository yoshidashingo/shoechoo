# Architecture — shoechoo (Reverse Engineering)

## システム全体概要

shoechoo は macOS ネイティブの Document-Based Application 上に構築された WYSIWYG Markdown エディタ。SwiftUI の DocumentGroup をエントリーポイントとし、テキスト編集は AppKit NSTextView に委譲。swift-markdown でソースをブロックツリーに変換し、SyntaxHighlighter がブロック状態に応じて NSTextStorage に属性を適用することで WYSIWYG 表示を実現。

## アーキテクチャ図

```mermaid
graph TB
    subgraph "App Layer"
        ShoechooApp["ShoechooApp (SwiftUI @main)"]
        MarkdownDocument["MarkdownDocument (ReferenceFileDocument)"]
    end
    subgraph "View Layer (SwiftUI)"
        EditorView
        SidebarView
        OutlineView
        PreferencesView
    end
    subgraph "Bridge Layer"
        WYSIWYGTextView["WYSIWYGTextView (NSViewRepresentable)"]
        Coordinator["Coordinator (NSTextViewDelegate)"]
    end
    subgraph "Editor Layer (AppKit)"
        ShoechooTextView["ShoechooTextView (NSTextView)"]
        NSTextStorage
    end
    subgraph "Model Layer"
        EditorViewModel["EditorViewModel (@Observable)"]
        EditorNodeModel["EditorNodeModel (@Observable)"]
        EditorNode["EditorNode (struct)"]
        EditorSettings["EditorSettings (singleton)"]
    end
    subgraph "Parser Layer"
        MarkdownParser["MarkdownParser (Sendable)"]
    end
    subgraph "Renderer Layer"
        SyntaxHighlighter
    end
    subgraph "Theme Layer"
        ThemeRegistry --> EditorTheme
        ThemePresets --> EditorTheme
    end
    subgraph "Service Layer"
        ExportService["ExportService (actor)"]
        FileService["FileService (actor)"]
        ImageService["ImageService (actor)"]
    end

    ShoechooApp --> MarkdownDocument
    ShoechooApp --> EditorView
    EditorView --> WYSIWYGTextView
    EditorView --> SidebarView
    WYSIWYGTextView --> Coordinator
    Coordinator --> ShoechooTextView
    Coordinator --> EditorNodeModel
    Coordinator --> MarkdownParser
    Coordinator --> SyntaxHighlighter
    ShoechooTextView --> NSTextStorage
    SyntaxHighlighter --> NSTextStorage
    SyntaxHighlighter --> EditorTheme
    MarkdownDocument --> EditorViewModel
    EditorViewModel --> ExportService
    EditorViewModel --> ImageService
    ImageService --> FileService
```

## コンポーネント記述

| コンポーネント | 目的 | 依存関係 | タイプ |
|---------------|------|---------|-------|
| ShoechooApp | エントリーポイント、DocumentGroup、メニュー | EditorSettings, ThemeRegistry | SwiftUI App |
| MarkdownDocument | ファイルI/O、snapshot管理 | EditorViewModel | ReferenceFileDocument |
| EditorViewModel | エディタ状態一元管理 | EditorSettings, NotificationCenter | @Observable @MainActor |
| EditorNodeModel | ブロックツリー管理、差分マージ | EditorNode | @Observable |
| MarkdownParser | AST→EditorNode変換 | swift-markdown | Sendable struct |
| SyntaxHighlighter | NSTextStorage属性適用 | EditorTheme, EditorNode | @MainActor struct |
| ShoechooTextView | カスタムNSTextView | EditorViewModel | NSTextView subclass |
| WYSIWYGTextView | SwiftUI↔AppKitブリッジ | 全レイヤー | NSViewRepresentable |
| ExportService | HTML/PDFエクスポート | swift-markdown, WebKit | actor |
| FileService | ファイル操作 | FileManager | actor |
| ImageService | 画像インポート | FileService | actor |

## データフロー

```mermaid
sequenceDiagram
    participant User
    participant TV as ShoechooTextView
    participant C as Coordinator
    participant VM as EditorViewModel
    participant Doc as MarkdownDocument
    participant P as MarkdownParser
    participant NM as EditorNodeModel
    participant SH as SyntaxHighlighter
    participant TS as NSTextStorage

    User->>TV: キー入力
    TV->>C: textDidChange()
    C->>VM: sourceText = newText
    C->>Doc: updateSnapshotText(newText)
    C->>C: scheduleHighlight() [0.15s]
    Note over C: Timer fires
    C->>P: parse(text, revision)
    P-->>C: ParseResult
    C->>NM: applyParseResult(result)
    C->>SH: apply(ts, blocks, theme)
    SH->>TS: 属性適用（テキスト内容は不変）
    TS-->>TV: 画面再描画
```

## 統合ポイント

| 統合先 | 用途 | 箇所 |
|--------|------|------|
| swift-markdown 0.5.0 | Markdown パーサ、HTML変換 | MarkdownParser, ExportService |
| Highlightr 2.2.1 | コードブロックハイライト（宣言のみ、未使用） | project.yml |
| WebKit (WKWebView) | PDFエクスポート | ExportService |
| AppKit (NSTextView) | 中核エディタ | ShoechooTextView |
| SwiftUI (DocumentGroup) | ドキュメントベースアプリ構造 | ShoechooApp |

## 発見された問題

1. **insertImageMarkdown 通知の Observer 未登録**: `EditorViewModel.insertImage()` が `.insertImageMarkdown` をpostするが、`Coordinator.registerNotifications()` にObserverがない → 画像D&D後にMarkdown構文が挿入されない
2. **Highlightr 未使用**: project.yml で依存宣言されているが、コード内で直接利用されていない
