# Components: Shoe Choo

## Component Overview

```
+-----------------------------------------------------------+
|                    ShoechooApp (SwiftUI)                   |
|  +-------+  +------------------------------------------+  |
|  |Sidebar|  |           DocumentWindow                  |  |
|  |Recent |  |  +--------------------------------------+ |  |
|  |Files  |  |  |        EditorView (SwiftUI)          | |  |
|  |       |  |  |  +--------------------------------+  | |  |
|  |       |  |  |  | WYSIWYGTextView (AppKit)       |  | |  |
|  |       |  |  |  | NSTextView + TextKit 2         |  | |  |
|  |       |  |  |  | FocusMode + TypewriterScroll   |  | |  |
|  |       |  |  |  +--------------------------------+  | |  |
|  |       |  |  +--------------------------------------+ |  |
|  +-------+  +------------------------------------------+  |
+-----------------------------------------------------------+
```

---

## C-01: ShoechooApp
- **Type**: SwiftUI App entry point
- **Responsibility**: App lifecycle, document scene, menu commands
- **Framework**: SwiftUI (@main)
- **Key Behaviors**:
  - Registers `MarkdownDocument` as the document type
  - Provides DocumentGroup scene for NSDocument integration
  - Configures app-level menus (File, Edit, Format, View)
  - Owns shared `EditorSettings`

## C-02: MarkdownDocument
- **Type**: NSDocument subclass
- **Responsibility**: File I/O, auto-save, versioning, document state ownership
- **Framework**: AppKit (NSDocument)
- **Key Behaviors**:
  - Reads/writes `.md` files as UTF-8 text
  - Provides macOS auto-save, Versions, Revert support
  - Creates and owns per-document `EditorViewModel`
  - Manages the `{filename}.assets/` image folder
  - Tracks recently opened files

## C-03: EditorViewModel
- **Type**: @Observable class (per-document)
- **Responsibility**: Editor business logic, rendering pipeline orchestration
- **Framework**: Swift / Observation
- **Key Behaviors**:
  - Holds source text and syncs with `MarkdownDocument`
  - Manages `EditorNodeModel` (intermediate block model)
  - Tracks cursor position, active paragraph, selection
  - Controls focus mode and typewriter scrolling state
  - Triggers incremental re-parsing on text changes
  - Coordinates rendering pipeline: source text → Parser → EditorNodeModel → Renderer

## C-04: EditorSettings
- **Type**: @Observable class (singleton, persisted)
- **Responsibility**: App-wide user preferences
- **Framework**: Swift / Observation + UserDefaults
- **Key Behaviors**:
  - Font family and size
  - Line spacing
  - Theme / appearance override (system, light, dark)
  - Focus mode default, typewriter scrolling default
  - Persisted via UserDefaults or @AppStorage

## C-05: MarkdownParser
- **Type**: Struct (stateless service)
- **Responsibility**: Parse Markdown source text into swift-markdown AST
- **Framework**: swift-markdown (Apple)
- **Key Behaviors**:
  - Parses full document or incremental block range
  - Returns typed `Markup` AST (Document, Heading, Paragraph, CodeBlock, etc.)
  - Supports GFM extensions (tables, task lists, strikethrough)

## C-06: EditorNodeModel
- **Type**: Class (per-document, mutable)
- **Responsibility**: Intermediate editing model — bridge between parser AST and rendered output
- **Framework**: Custom Swift
- **Key Behaviors**:
  - Maintains ordered list of `EditorNode` (block-level: paragraph, heading, list, code block, table, blockquote, horizontal rule)
  - Each `EditorNode` has: stable ID, node type, source range, inline runs (bold, italic, link, code, image, strikethrough)
  - Tracks which block is "active" (cursor is inside → show raw syntax)
  - Supports incremental update: re-parse changed blocks only, reuse unchanged nodes
  - Does NOT persist — rebuilt from source text on document open

## C-07: MarkdownRenderer
- **Type**: Struct (stateless service)
- **Responsibility**: Convert EditorNode blocks into NSAttributedString for display
- **Framework**: AppKit (NSAttributedString, NSFont, NSColor)
- **Key Behaviors**:
  - Renders "inactive" blocks: heading styles, bold/italic, links, images, code highlighting, tables, blockquotes
  - Renders "active" block: raw Markdown source with subtle syntax highlighting
  - Adapts to light/dark appearance
  - Reads font/spacing from `EditorSettings`
  - Renders unsupported extensions (LaTeX, Mermaid) as styled code blocks

## C-08: WYSIWYGTextView
- **Type**: NSViewRepresentable wrapping custom NSTextView subclass
- **Responsibility**: Core text editing surface with TextKit 2
- **Framework**: AppKit (NSTextView, NSTextContentManager, NSTextLayoutManager)
- **Key Behaviors**:
  - Renders NSAttributedString from MarkdownRenderer
  - Handles text input, IME composition, selection, Undo/Redo
  - Implements focus mode overlay (dim inactive paragraphs via alpha)
  - Implements typewriter scrolling (scroll to center active line)
  - Notifies EditorViewModel of text changes and cursor movement
  - Supports drag & drop for images

## C-09: EditorView
- **Type**: SwiftUI View
- **Responsibility**: SwiftUI wrapper composing editor surface + toolbar
- **Framework**: SwiftUI
- **Key Behaviors**:
  - Hosts WYSIWYGTextView
  - Provides toolbar (focus mode toggle, export button)
  - Manages sidebar visibility toggle
  - Passes EditorViewModel and EditorSettings to subviews

## C-10: SidebarView
- **Type**: SwiftUI View
- **Responsibility**: Recent files list sidebar
- **Framework**: SwiftUI
- **Key Behaviors**:
  - Displays list of recently opened files (from NSDocumentController)
  - Click to open document
  - Collapsible/toggleable

## C-11: ExportService
- **Type**: Actor (async)
- **Responsibility**: Export documents to HTML and PDF
- **Framework**: Swift + WebKit (for PDF rendering)
- **Key Behaviors**:
  - Converts Markdown source → HTML (via swift-markdown AST → HTML)
  - Converts HTML → PDF (via macOS native rendering)
  - Preserves styling consistent with editor appearance
  - Handles image path resolution for export

## C-12: ImageService
- **Type**: Actor (async)
- **Responsibility**: Image asset management
- **Framework**: Swift + AppKit (NSImage, NSPasteboard)
- **Key Behaviors**:
  - Handles drag & drop image reception
  - Handles clipboard paste image extraction
  - Copies images to `{filename}.assets/` folder
  - Generates unique filenames (timestamp-based)
  - Returns relative Markdown image reference for insertion
  - Prompts save for untitled documents before image drop

## C-13: FileService
- **Type**: Actor (async)
- **Responsibility**: File I/O utilities beyond NSDocument
- **Framework**: Swift (Foundation)
- **Key Behaviors**:
  - Assets folder creation and management
  - File existence validation
  - Safe atomic file writes
