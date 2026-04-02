# Services: Shoe Choo

## Service Architecture

Shoe Choo uses a lightweight service layer. Services are stateless actors (async) or structs that provide domain operations to ViewModels and Documents.

```
+------------------+     +------------------+     +------------------+
|  MarkdownParser  |     |  ExportService   |     |  ImageService    |
|  (struct)        |     |  (actor)         |     |  (actor)         |
|  - parse()       |     |  - generateHTML()|     |  - importDropped |
|  - parseBlock()  |     |  - generatePDF() |     |  - importPasted  |
+------------------+     +------------------+     +------------------+
         |                        |                        |
         v                        v                        v
+-------------------------------------------------------------------+
|                    EditorViewModel (per-document)                  |
|  Orchestrates: parse -> model update -> render -> display         |
+-------------------------------------------------------------------+
         |                                                 |
         v                                                 v
+------------------+                              +------------------+
| EditorNodeModel  |                              | MarkdownRenderer |
| (intermediate)   |                              | (struct)         |
+------------------+                              +------------------+
```

---

## S-01: Parsing Service (MarkdownParser)

| Attribute | Detail |
|-----------|--------|
| **Type** | Struct (stateless, synchronous) |
| **Consumers** | EditorViewModel |
| **Responsibility** | Convert Markdown source text to swift-markdown AST |
| **Concurrency** | Synchronous — parsing is fast enough for main thread on typical documents |
| **Error Handling** | Never fails — malformed Markdown produces best-effort AST |

### Orchestration Pattern
1. EditorViewModel detects text change
2. Calls `MarkdownParser.parse()` or `parseBlock()` for changed range
3. Passes AST to `EditorNodeModel.rebuild()` or `updateBlocks()`

---

## S-02: Rendering Service (MarkdownRenderer)

| Attribute | Detail |
|-----------|--------|
| **Type** | Struct (stateless, synchronous) |
| **Consumers** | EditorViewModel → WYSIWYGTextView |
| **Responsibility** | Convert EditorNode blocks to NSAttributedString |
| **Concurrency** | Synchronous — rendering individual blocks is fast |
| **Error Handling** | Graceful degradation — unsupported elements render as code blocks |

### Orchestration Pattern
1. EditorViewModel requests rendering after model update
2. For each block: if active → `renderActiveBlock()` (syntax visible), else → `render()` (styled)
3. Assembled NSAttributedString passed to WYSIWYGTextView

---

## S-03: Export Service (ExportService)

| Attribute | Detail |
|-----------|--------|
| **Type** | Actor (async) |
| **Consumers** | EditorViewModel (via export commands) |
| **Responsibility** | Generate HTML and PDF from Markdown source |
| **Concurrency** | Async — PDF generation may be slow for large documents |
| **Error Handling** | Throws on file I/O errors, HTML generation errors |

### Orchestration Pattern
1. User triggers export (Cmd+Shift+E)
2. EditorViewModel calls `ExportService.generateHTML()`
3. For PDF: `generateHTML()` → `generatePDF()` (WKWebView snapshot)
4. Save dialog presented, file written

---

## S-04: Image Service (ImageService)

| Attribute | Detail |
|-----------|--------|
| **Type** | Actor (async) |
| **Consumers** | WYSIWYGTextView (drag & drop), EditorViewModel (paste) |
| **Responsibility** | Import and manage image assets |
| **Concurrency** | Async — file I/O operations |
| **Error Handling** | Throws on file write errors, prompts save for untitled documents |

### Orchestration Pattern
1. Image dropped/pasted into editor
2. WYSIWYGTextView delegates to ImageService
3. ImageService copies image to `{filename}.assets/`, returns relative path
4. EditorViewModel inserts `![](relative/path)` at cursor position

---

## S-05: File Service (FileService)

| Attribute | Detail |
|-----------|--------|
| **Type** | Actor (async) |
| **Consumers** | ImageService, MarkdownDocument |
| **Responsibility** | Low-level file system operations |
| **Concurrency** | Async — file I/O |
| **Error Handling** | Throws with descriptive FileServiceError cases |

### Orchestration Pattern
- Called by other services for directory creation, existence checks, atomic writes
- Does not interact with UI directly
