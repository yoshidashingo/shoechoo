---
layout: default
---

# Application Design: Shoe Choo (Consolidated)

## Architecture Overview

**Pattern**: MVVM with SwiftUI shell + AppKit editor surface
**UI Framework**: SwiftUI (window, toolbar, sidebar) + NSViewRepresentable (NSTextView/TextKit 2)
**Rendering Pipeline**: 3-stage — Parser → EditorNodeModel → Renderer
**State Management**: EditorViewModel (per-document) + EditorSettings (shared)

---

## Components (13)

| ID | Component | Type | Responsibility |
|----|-----------|------|---------------|
| C-01 | ShoechooApp | SwiftUI App | App lifecycle, document scene, menus |
| C-02 | MarkdownDocument | NSDocument | File I/O, auto-save, versioning |
| C-03 | EditorViewModel | @Observable | Editor logic, rendering orchestration |
| C-04 | EditorSettings | @Observable (singleton) | App-wide preferences (font, theme) |
| C-05 | MarkdownParser | Struct | Markdown → swift-markdown AST |
| C-06 | EditorNodeModel | Class | Intermediate block model with stable IDs |
| C-07 | MarkdownRenderer | Struct | EditorNode → NSAttributedString |
| C-08 | WYSIWYGTextView | NSViewRepresentable | TextKit 2 editing surface |
| C-09 | EditorView | SwiftUI View | Editor + toolbar composition |
| C-10 | SidebarView | SwiftUI View | Recent files list |
| C-11 | ExportService | Actor | HTML/PDF export |
| C-12 | ImageService | Actor | Image asset management |
| C-13 | FileService | Actor | Low-level file I/O utilities |

## Rendering Pipeline

```
Source Text (String)
    |
    v
MarkdownParser (swift-markdown)
    | produces Markup AST
    v
EditorNodeModel
    | block-level EditorNodes with stable IDs
    | tracks active block (cursor location)
    v
MarkdownRenderer
    | active block → raw syntax with highlighting
    | inactive blocks → styled rendering
    v
NSAttributedString → WYSIWYGTextView
```

**Key Design Decision**: Paragraph-level delayed rendering for MVP. When the cursor leaves a paragraph, it renders as styled output. When the cursor enters, raw Markdown syntax is shown. This achieves 90% of Typora's UX at 30% of the implementation complexity. Full inline-element-level toggle rendering planned for post-MVP.

## State Management

```
EditorSettings (shared, persisted)
    |
    +--- font, fontSize, lineSpacing
    +--- appearanceOverride
    +--- defaultFocusMode, defaultTypewriterScroll
    |
EditorViewModel (per-document, transient)
    |
    +--- sourceText (synced with MarkdownDocument)
    +--- nodeModel (EditorNodeModel)
    +--- cursorPosition, activeBlockID
    +--- isFocusModeEnabled, isTypewriterScrollEnabled
```

## Primary Data Flows

1. **Editing**: User types → NSTextView → EditorViewModel.textDidChange() → Parser → NodeModel update → Renderer → Display
2. **Cursor Move**: Cursor moves → EditorViewModel.cursorDidMove() → NodeModel.setActiveBlock() → Re-render affected blocks
3. **Image Drop**: Drop image → ImageService copies to assets/ → EditorViewModel inserts reference → Normal editing flow
4. **Export**: User triggers → ExportService.generateHTML/PDF() → Save dialog → Write file

## Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| SwiftUI/AppKit boundary | SwiftUI shell + NSViewRepresentable | TextKit 2 requires NSTextView; SwiftUI handles everything else |
| Rendering pipeline | 3-stage with intermediate model | Enables paragraph-level delayed rendering and incremental re-rendering |
| State split | Per-document ViewModel + Shared Settings | Avoids accidental state sharing across windows |
| Services as Actors | ExportService, ImageService, FileService | Thread-safe async I/O without manual locking |
| Parser as Struct | MarkdownParser | Stateless, synchronous, fast enough for main thread |

## External Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| swift-markdown (Apple) | Latest stable | Markdown parsing to typed AST |
| Highlightr | Latest stable | Code block syntax highlighting |

---

*Detailed method signatures: see `component-methods.md`*
*Service orchestration: see `services.md`*
*Dependency matrix and data flows: see `component-dependency.md`*
