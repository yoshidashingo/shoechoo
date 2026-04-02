# Vision Document: Shoe Choo (集中)

## What We're Building

**Shoe Choo** is a distraction-free, WYSIWYG Markdown editor for macOS — inspired by Typora's seamless editing experience. The name "集中" (Shoe Choo) means "focus" in Japanese, reflecting the app's core philosophy: letting writers concentrate on their words without visual noise.

## Who It's For

- Writers, bloggers, and technical authors who work in Markdown daily
- Developers who want a clean Markdown editor for documentation
- Anyone who values a focused, minimal writing environment on macOS

## Why We're Building It

Typora demonstrated that a Markdown editor can feel as natural as a word processor while preserving Markdown's portability. However, as a closed-source, cross-platform Electron app, it doesn't fully leverage macOS's native capabilities. Shoe Choo aims to deliver a Typora-quality writing experience as a native macOS app — fast, lightweight, and deeply integrated with the platform.

## MVP Features (In Scope)

1. **Live WYSIWYG Markdown Editing** — Inline rendering of Markdown syntax as the user types (headings, bold, italic, links, images, lists, blockquotes, code blocks)
2. **Focus Mode** — Dims non-active paragraphs to help the writer concentrate
3. **Typewriter Scrolling** — Keeps the active line vertically centered
4. **Full-Screen Writing** — Immersive distraction-free mode
5. **Syntax Highlighting** — Subtle highlighting for Markdown elements in edit mode
6. **File Operations** — Open, create, save, and auto-save `.md` files with standard macOS file handling
7. **Image Support** — Drag & drop and paste images into documents
8. **Export** — Export to HTML and PDF
9. **Dark Mode** — Full support for macOS light and dark appearances
10. **Typography** — Configurable fonts and line spacing for comfortable reading

## Out of Scope (v1)

- iOS / iPadOS app (planned for future)
- iCloud sync (planned for future)
- Collaboration / real-time editing
- Plugin / extension system
- Table editing GUI
- Math (LaTeX) rendering (may be added post-MVP)
- Version history / change tracking
- Vim / Emacs keybindings

## Open Questions

- Should the app use a document-based architecture (NSDocument) or a custom document management approach?
- What Markdown parsing library to use? (swift-markdown, cmark, Ink, or custom?)
- How to handle inline WYSIWYG rendering — TextKit 2 or a WebView-based approach?
- Should the app be distributed via the Mac App Store or direct download only?

## Competitive Landscape

| App | Strengths | Weaknesses (opportunity) |
|-----|-----------|--------------------------|
| Typora | Best-in-class WYSIWYG, clean UI | Electron (not native), paid, no open source |
| iA Writer | Beautiful typography, focus mode | Limited Markdown rendering, no inline WYSIWYG |
| Obsidian | Powerful features, plugins | Not WYSIWYG by default, complex |
| MacDown | Free, open source | Split-pane preview only, outdated |

## Success Criteria

- Cold launch in under 1 second
- Memory usage under 50MB for typical documents
- Seamless inline Markdown rendering with no visual "mode switching"
- Natural macOS feel (keyboard shortcuts, system integrations, appearance)
