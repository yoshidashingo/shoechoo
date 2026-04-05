# Units of Work: Shoe Choo

## Decomposition Strategy

**Deployment Model**: Single monolithic macOS application (`.app` bundle)
**Unit Strategy**: Logical modules within a single Xcode target, organized by feature domain
**Rationale**: Desktop macOS app has no microservice boundary — units represent development phases aligned with feature priority and dependency order

---

## Unit Definitions

### Unit 1: Core Editor Engine
**Priority**: Critical — Foundation for all other units
**Scope**: Markdown parsing, intermediate model, rendering pipeline, TextKit 2 editor surface

| Component | Role in Unit |
|-----------|-------------|
| C-05 MarkdownParser | Parse Markdown to AST |
| C-06 EditorNodeModel | Intermediate block model |
| C-07 MarkdownRenderer | AST → NSAttributedString |
| C-08 WYSIWYGTextView | TextKit 2 editing surface |

**Deliverables**:
- Working WYSIWYG editor that renders headings, bold, italic, links, lists, blockquotes, code blocks, tables, task lists, strikethrough, horizontal rules
- Paragraph-level delayed rendering (cursor leaves → render, cursor enters → show syntax)
- IME support, Undo/Redo, spell check via native TextKit 2
- Syntax highlighting for code blocks

**Stories**: 1.1–1.10 (Epic 1: WYSIWYG Editing)

---

### Unit 2: Document Management
**Priority**: High — Required for file operations, depends on Unit 1 for editor integration
**Scope**: NSDocument lifecycle, app entry point, editor settings

| Component | Role in Unit |
|-----------|-------------|
| C-01 ShoechooApp | App lifecycle, DocumentGroup scene |
| C-02 MarkdownDocument | NSDocument file I/O, auto-save |
| C-03 EditorViewModel | Per-document state management |
| C-04 EditorSettings | App-wide preferences |
| C-09 EditorView | SwiftUI editor + toolbar composition |
| C-13 FileService | File utilities |

**Deliverables**:
- Xcode project with SwiftUI DocumentGroup scene
- NSDocument-based open/save/auto-save/versions
- Tabbed windows
- Recent files tracking
- EditorViewModel orchestrating the rendering pipeline from Unit 1
- EditorSettings with font, spacing, appearance preferences

**Stories**: 3.1–3.5 (Epic 3: Document Management), 8.1 (Epic 8: Typography)

---

### Unit 3: Focus & Immersion
**Priority**: High — Core differentiator ("集中"), depends on Unit 1 editor surface
**Scope**: Focus mode, typewriter scrolling, full-screen

| Component | Role in Unit |
|-----------|-------------|
| C-08 WYSIWYGTextView | Focus dimming + typewriter scroll implementation |
| C-03 EditorViewModel | Focus/typewriter state management |
| C-04 EditorSettings | Persistence of preferences |

**Deliverables**:
- Focus mode: dim inactive paragraphs, highlight active paragraph
- Typewriter scrolling: center active line vertically
- Full-screen writing mode with auto-hiding toolbar/sidebar
- Preference persistence across app restarts

**Stories**: 2.1–2.3 (Epic 2: Focus & Typewriter), 7.1 (Epic 7: Full-Screen)

---

### Unit 4: Image & Media
**Priority**: Medium — Enhances editing experience, depends on Unit 1 + Unit 2
**Scope**: Image drag & drop, clipboard paste, asset management

| Component | Role in Unit |
|-----------|-------------|
| C-12 ImageService | Image import and asset management |
| C-13 FileService | Assets directory management |
| C-08 WYSIWYGTextView | Drag & drop handling |
| C-03 EditorViewModel | Image reference insertion |

**Deliverables**:
- Drag & drop images from Finder into editor
- Paste images from clipboard
- Auto-copy to `{filename}.assets/` folder
- Relative path Markdown reference insertion
- Untitled document save prompt

**Stories**: 6.1–6.2 (Epic 6: Image Support)

---

### Unit 5: Export & Polish
**Priority**: Medium — Final MVP features, depends on Unit 1 + Unit 2
**Scope**: HTML/PDF export, sidebar, dark mode

| Component | Role in Unit |
|-----------|-------------|
| C-11 ExportService | HTML and PDF generation |
| C-10 SidebarView | Recent files sidebar |
| C-09 EditorView | Dark mode adaptation |

**Deliverables**:
- Export to HTML (swift-markdown AST → HTML)
- Export to PDF (HTML → macOS native PDF rendering)
- Collapsible recent files sidebar
- Full dark mode support for all UI elements and editor rendering

**Stories**: 4.1–4.2 (Epic 4: Export), 5.1 (Epic 5: Sidebar), 7.2 (Epic 7: Dark Mode)

---

## Code Organization

```
shoechoo/
+-- shoechoo.xcodeproj
+-- shoechoo/
|   +-- App/                          # Unit 2
|   |   +-- ShoechooApp.swift
|   |   +-- MarkdownDocument.swift
|   +-- Models/                        # Unit 1 + Unit 2
|   |   +-- EditorViewModel.swift
|   |   +-- EditorSettings.swift
|   |   +-- EditorNodeModel.swift
|   |   +-- EditorNode.swift
|   +-- Parser/                        # Unit 1
|   |   +-- MarkdownParser.swift
|   +-- Renderer/                      # Unit 1
|   |   +-- MarkdownRenderer.swift
|   +-- Editor/                        # Unit 1 + Unit 3
|   |   +-- WYSIWYGTextView.swift
|   |   +-- ShoechooTextView.swift
|   |   +-- FocusMode.swift
|   |   +-- TypewriterScroll.swift
|   +-- Views/                         # Unit 2 + Unit 5
|   |   +-- EditorView.swift
|   |   +-- SidebarView.swift
|   |   +-- PreferencesView.swift
|   +-- Services/                      # Unit 4 + Unit 5
|   |   +-- ExportService.swift
|   |   +-- ImageService.swift
|   |   +-- FileService.swift
|   +-- Extensions/
|   +-- Resources/
|       +-- Assets.xcassets
+-- shoechooTests/                     # Mirrors source structure
+-- shoechooUITests/
+-- docs/                              # GitHub Pages
+-- aidlc-docs/                        # AI-DLC docs
+-- README.md
+-- README-ja.md
```

## Implementation Order & Timeline

```
Week 1-2: Unit 1 (Core Editor Engine)
    |
    v
Week 2-3: Unit 2 (Document Management)
    |
    +---> Week 3-4: Unit 3 (Focus & Immersion) [parallel possible]
    |
    +---> Week 4:   Unit 4 (Image & Media)     [parallel possible]
    |
    v
Week 4-5: Unit 5 (Export & Polish)
    |
    v
Week 5:   Integration Testing + Build + Notarization
```
