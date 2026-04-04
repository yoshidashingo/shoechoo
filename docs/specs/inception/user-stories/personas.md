---
layout: default
---

# User Personas: Shoe Choo

## Persona 1: Haruka (Primary — Writer/Blogger)

| Attribute | Detail |
|-----------|--------|
| **Name** | Haruka |
| **Role** | Freelance writer / blogger |
| **Age** | 32 |
| **Technical Level** | Intermediate — comfortable with Markdown basics, not a programmer |
| **Platform** | MacBook Air, uses macOS daily |
| **Current Tools** | Typora, iA Writer, Bear |

### Goals
- Write long-form articles and blog posts with minimal distractions
- See the formatted output as she types without switching between edit/preview modes
- Quickly organize thoughts with headings, lists, and blockquotes
- Export finished articles to HTML for her blog CMS or PDF for clients

### Pain Points
- Typora feels sluggish and non-native on macOS (Electron)
- iA Writer doesn't render Markdown inline (split-pane or preview-only)
- Obsidian is overwhelming with features she doesn't need
- Wants focus mode that actually helps her concentrate on the current paragraph

### Key Stories
- WYSIWYG editing (FR-01), Focus mode (FR-03), Typewriter scrolling (FR-04), Export (FR-08)

---

## Persona 2: Kenji (Secondary — Technical Writer / Developer)

| Attribute | Detail |
|-----------|--------|
| **Name** | Kenji |
| **Role** | Software engineer writing documentation |
| **Age** | 28 |
| **Technical Level** | Advanced — writes Markdown daily for README, docs, ADRs |
| **Platform** | MacBook Pro, VS Code is primary IDE |
| **Current Tools** | VS Code Markdown preview, MacDown, Typora occasionally |

### Goals
- Edit README.md and documentation files with GFM support (tables, task lists, code blocks)
- See syntax-highlighted code blocks while writing technical docs
- Drag & drop screenshots into documentation
- Quick editing sessions — open a file, edit, save, close

### Pain Points
- VS Code's Markdown preview is split-pane and disconnected from editing
- MacDown is outdated and lacks modern macOS integration
- Wants a lightweight editor that launches instantly for quick doc edits

### Key Stories
- GFM support (FR-02), Code block highlighting, Image drag & drop (FR-07), File operations (FR-05)

---

## Persona 3: Miki (Tertiary — Casual Markdown User)

| Attribute | Detail |
|-----------|--------|
| **Name** | Miki |
| **Role** | Graduate student writing research notes |
| **Age** | 24 |
| **Technical Level** | Beginner — knows basic Markdown from GitHub, learning |
| **Platform** | MacBook, new to dedicated Markdown editors |
| **Current Tools** | Apple Notes, Google Docs, occasionally GitHub web editor |

### Goals
- Transition from rich-text editors to Markdown for portable, future-proof notes
- Learn Markdown naturally through WYSIWYG — type syntax, see results immediately
- Simple, non-intimidating interface
- Dark mode for late-night study sessions

### Pain Points
- Existing Markdown editors feel technical and developer-oriented
- Doesn't want to learn a complex tool just to write notes
- Needs the WYSIWYG experience to bridge the gap from rich-text editors

### Key Stories
- WYSIWYG as learning tool, Dark mode (FR-10), Simple file management (FR-05), Clean UI
