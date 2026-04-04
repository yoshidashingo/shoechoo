# Architecture

## Project Overview

Shoechoo (集中) is a distraction-free Markdown editor for macOS. It provides a WYSIWYG-style editing experience where the active block shows raw Markdown source while inactive blocks display styled output. The app supports focus mode, typewriter scrolling, image drag-and-drop, and export to HTML/PDF.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI framework | SwiftUI (scene/window management, preferences, toolbar) |
| Text editing | AppKit `NSTextView` via `NSViewRepresentable` |
| Markdown parsing | [swift-markdown](https://github.com/swiftlang/swift-markdown) (`Document`, `MarkupWalker`) |
| Syntax highlighting | [Highlightr](https://github.com/nicklama/Highlightr) (code blocks) |
| PDF generation | WebKit `WKWebView.pdf(configuration:)` |
| Persistence | `ReferenceFileDocument` (SwiftUI document model) |
| Settings | `UserDefaults` via `@Observable` singleton |

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     ShoechooApp                         │
│  DocumentGroup + Commands (Format, Heading, Focus, ...) │
└──────────────┬──────────────────────────────────────────┘
               │ creates per-window
               ▼
┌──────────────────────────┐    ┌─────────────────────────┐
│    MarkdownDocument      │    │    EditorSettings       │
│  (ReferenceFileDocument) │    │  (@Observable singleton)│
│  owns EditorViewModel    │    │  font, spacing, theme   │
└──────────┬───────────────┘    └─────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────────┐
│                   EditorViewModel                        │
│  @Observable · @MainActor                                │
│                                                          │
│  sourceText ──► MarkdownParser ──► EditorNodeModel       │
│                                       │                  │
│  cursorPosition ──► resolveActiveBlock ┘                  │
│                                                          │
│  applyHighlightNow() ──► MarkdownParser.parse()          │
│                      └─► SyntaxHighlighter.apply()       │
│                          (attributes only, no text edit) │
│  exportHTML / exportPDF ──► ExportService                 │
│  handleImageDrop ──────────► ImageService                 │
└──────────────────┬───────────────────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────────────────┐
│              EditorView (SwiftUI)                        │
│  ┌────────────────────────────────────────────────────┐  │
│  │          WYSIWYGTextView (NSViewRepresentable)     │  │
│  │  ┌──────────────────────────────────────────────┐  │  │
│  │  │     ShoechooTextView (NSTextView subclass)   │  │  │
│  │  │     focus dimming · typewriter scroll · D&D  │  │  │
│  │  └──────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## Directory Structure

```
shoechoo/
├── App/
│   ├── ShoechooApp.swift          # @main entry, DocumentGroup, menu commands
│   └── MarkdownDocument.swift     # ReferenceFileDocument, snapshot/file I/O
├── Models/
│   ├── EditorNode.swift           # BlockKind, InlineType, EditorNode value type
│   ├── EditorNodeModel.swift      # Block list with diff/merge and active-block tracking
│   ├── EditorSettings.swift       # UserDefaults-backed @Observable settings
│   ├── EditorViewModel.swift      # Central coordinator: parse, highlight, format, export
│   └── ParseResult.swift          # Parser output container
├── Parser/
│   └── MarkdownParser.swift       # swift-markdown AST → EditorNode tree
├── Highlighter/
│   └── SyntaxHighlighter.swift    # EditorNode → NSTextStorage attributes (active/inactive)
├── Editor/
│   ├── ShoechooTextView.swift     # NSTextView subclass: focus dimming, typewriter, D&D
│   └── WYSIWYGTextView.swift      # NSViewRepresentable bridge + Coordinator
├── Views/
│   ├── EditorView.swift           # Main editor scene with toolbar
│   ├── OutlineView.swift          # Document outline / heading navigator
│   ├── SidebarView.swift          # Recent files list
│   └── PreferencesView.swift      # Settings UI (font, appearance)
├── Theme/
│   └── EditorTheme.swift          # Color/font token definitions
├── Services/
│   ├── ExportService.swift        # HTML generation (MarkupWalker) + PDF via WKWebView
│   ├── FileService.swift          # Atomic file writes, directory creation
│   └── ImageService.swift         # Image import, filename generation, path validation
├── Extensions/                    # (reserved for future extensions)
└── Resources/
    ├── Info.plist
    └── shoechoo.entitlements
```

## Key Components

### Document Model

`MarkdownDocument` is a `ReferenceFileDocument` that owns an `EditorViewModel`. It uses an `NSLock`-guarded snapshot string for thread-safe file I/O. Each document window gets its own view model instance. An assets directory (`<filename>.assets/`) sits alongside the document for embedded images.

### Parser

`MarkdownParser` is a `Sendable` struct that wraps `swift-markdown`'s `Document(parsing:)`. It converts the AST into a flat array of `EditorNode` values, each tagged with a `BlockKind` (heading, paragraph, code block, list, table, etc.) and carrying `InlineRun` spans for bold, italic, links, and other inline formatting. Source ranges map back to the original text for cursor-aware editing.

### Highlighter

`SyntaxHighlighter` applies `NSTextStorage` attributes to `EditorNode` blocks via two paths:

- **Inactive blocks**: styled output where Markdown syntax delimiters are hidden (font size 0.01, foreground color matches background) and visual formatting is applied (bold fonts, heading sizes, syntax-highlighted code via Highlightr, colored links).
- **Active blocks**: raw Markdown source with subtle syntax coloring on delimiters (`**`, `` ` ``, `#`, etc.) so the user can edit the source directly.

All changes are attribute-only — the underlying text content in `NSTextStorage` is never modified. Attribute updates are wrapped in `textStorage.beginEditing()`/`endEditing()` to prevent undo registration.

### Editor

`ShoechooTextView` extends `NSTextView` with three features: focus-mode dimming (non-active blocks fade to 30% opacity), typewriter scrolling (current line stays vertically centered), and image drag-and-drop. `WYSIWYGTextView` wraps it in `NSViewRepresentable` with a `Coordinator` that bridges `NSTextViewDelegate` callbacks to the view model and handles formatting commands via `NotificationCenter`.

### Export Pipeline

`ExportService` is an `actor` with two stages:

1. **HTML**: A custom `HTMLConverter` (implementing `MarkupWalker`) walks the swift-markdown AST and produces a standalone HTML page with embedded CSS.
2. **PDF**: The HTML is loaded into an offscreen `WKWebView`, rendered, then exported as A4 PDF data via `WKWebView.pdf(configuration:)`.

## Data Flow

```
User types in NSTextView
        │
        ▼
Coordinator.textDidChange()
        │
        ▼
EditorViewModel.textDidChange()
        │  stores sourceText
        │  schedules parse (150ms debounce)
        ▼
MarkdownParser.parse()              ← runs after debounce
        │  swift-markdown Document → [EditorNode]
        ▼
EditorNodeModel.applyParseResult()  ← position-based diff preserves stable IDs
        │
        ▼
SyntaxHighlighter.apply()          ← attributes only, no text replacement
        │  active block → colored delimiters
        │  inactive blocks → hidden delimiters + styled output
        ▼
NSTextStorage (attributes updated) ← cursor position preserved
```

Cursor movement follows a parallel path: `textViewDidChangeSelection` updates `cursorPosition`, which resolves the active block via `EditorNodeModel.resolveActiveBlock()`. Changed block IDs trigger selective cache invalidation and re-render.

## Concurrency Model

| Component | Isolation | Rationale |
|-----------|-----------|-----------|
| `EditorViewModel` | `@MainActor` | Drives UI state; all property access is on the main thread |
| `EditorSettings` | `@MainActor` | Shared singleton accessed by views and view model |
| `EditorNodeModel` | `@unchecked Sendable` | Mutated only from `@MainActor` context via the view model |
| `MarkdownParser` | `Sendable` struct | Stateless; safe to call from any context |
| `MarkdownDocument` | `@unchecked Sendable` | `NSLock` guards the snapshot; `viewModel` accessed on `@MainActor` |
| `ExportService` | `actor` | PDF generation involves async WebKit calls |
| `FileService` | `actor` | File system operations serialized to avoid races |
| `ImageService` | `actor` | Image import delegates to `FileService` |

Parse scheduling uses `Task` with a 150ms sleep for debouncing. Each new keystroke cancels the previous parse task via `Task.isCancelled` checks, ensuring only the latest revision is applied.

## Design Decisions

### NSTextView over SwiftUI TextEditor

SwiftUI's `TextEditor` lacks fine-grained control over attributed string rendering, text storage manipulation, and selection management. `NSTextView` provides direct access to `NSTextStorage` for applying per-block styling, custom drag-and-drop handling, and IME composition awareness (`hasMarkedText()`).

### Dual rendering paths (active vs. inactive)

The active block shows raw Markdown so the user always edits plain text. Inactive blocks render styled output for a live-preview feel. This avoids the complexity of a true rich-text editor while still providing visual feedback. The `ActivationScope` enum controls how deeply activation propagates (e.g., activating a list item vs. the whole list).

### Block-level architecture with stable IDs

The document is parsed into a flat list of `EditorNode` blocks rather than maintaining a persistent tree. `EditorNodeModel.applyParseResult()` performs a position-based diff that preserves UUIDs for unchanged blocks, enabling the render cache to skip re-rendering unmodified content.

### Debounced parsing

A 150ms debounce (`Task.sleep`) prevents excessive re-parsing during fast typing. The revision counter ensures stale parse results are discarded. This keeps the editor responsive even for large documents.

### NotificationCenter for formatting commands

Menu commands and keyboard shortcuts post notifications (`toggleFormatting`, `insertFormattedText`, `setLinePrefix`) that the `WYSIWYGTextView.Coordinator` observes. This decouples SwiftUI command definitions from the AppKit text view without requiring a shared mutable reference.

### Actor-based services

`ExportService`, `FileService`, and `ImageService` are Swift `actor` types, serializing I/O operations and ensuring thread safety without manual locking. The export pipeline chains HTML generation (CPU-bound) with PDF rendering (async WebKit), both isolated within the actor.
