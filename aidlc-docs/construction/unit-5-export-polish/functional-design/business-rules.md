# Business Rules: Unit 5 — Export & Polish

## BR-01: HTML Export

| Rule | Description |
|------|-------------|
| BR-01.1 | HTML export MUST parse the full source text via swift-markdown and walk the AST to produce HTML — not regex-based conversion |
| BR-01.2 | All GFM elements supported by the editor (headings, bold, italic, strikethrough, code, links, images, lists, task lists, tables, blockquotes, horizontal rules) MUST be represented in HTML output |
| BR-01.3 | Image `src` attributes MUST preserve the original relative paths from the Markdown source |
| BR-01.4 | HTML text content MUST be entity-escaped (`<`, `>`, `&`, `"`, `'`) to prevent injection |
| BR-01.5 | Generated HTML MUST be a complete standalone document with `<!DOCTYPE html>`, `<html>`, `<head>` (with `<meta charset="UTF-8">`), and `<body>` |
| BR-01.6 | Generated HTML MUST include embedded CSS styles (not external stylesheet) for portable rendering |
| BR-01.7 | The `<title>` element MUST be set to the document file name (without `.md` extension), or "Untitled" for unsaved documents |
| BR-01.8 | Empty source text MUST produce `ExportError.emptySource` — do not generate an empty HTML file |
| BR-01.9 | Fenced code blocks with a language specifier MUST include a `class="language-{lang}"` attribute on the `<code>` element |
| BR-01.10 | Task list items MUST render as `<input type="checkbox" disabled>` (disabled — not interactive in exported HTML) |

---

## BR-02: PDF Export

| Rule | Description |
|------|-------------|
| BR-02.1 | PDF export MUST first generate HTML (identical to BR-01 output), then render that HTML to PDF via `WKWebView.createPDF(configuration:)` |
| BR-02.2 | The WKWebView used for PDF rendering MUST be offscreen (not visible to the user) |
| BR-02.3 | The WKWebView MUST be loaded with `baseURL` set to the source document's parent directory so that relative image paths resolve correctly |
| BR-02.4 | PDF rendering MUST wait for `WKNavigationDelegate.webView(_:didFinish:)` before capturing — do not snapshot mid-load |
| BR-02.5 | PDF rendering MUST enforce a timeout of 30 seconds; if exceeded, throw `ExportError.pdfRenderingTimedOut` |
| BR-02.6 | Default paper size MUST be A4 (595.28 x 841.89 points) with 72pt (1-inch) margins on all sides |
| BR-02.7 | PDF output MUST preserve the visual appearance of the HTML rendering (fonts, colors, table borders, code block backgrounds) |
| BR-02.8 | The offscreen WKWebView MUST be deallocated after PDF data is captured to avoid memory leaks |
| BR-02.9 | WKWebView operations MUST execute on the main thread (`@MainActor`) as required by WebKit |

---

## BR-03: Export Dialog

| Rule | Description |
|------|-------------|
| BR-03.1 | Export MUST present `NSSavePanel` for the user to choose the destination — do not auto-save to a default location |
| BR-03.2 | `NSSavePanel.allowedContentTypes` MUST be set to the exported format's UTType (`.html` or `.pdf`) |
| BR-03.3 | The suggested file name MUST be the document name with the appropriate extension (e.g., `MyDocument.html`) |
| BR-03.4 | The default save directory MUST be the same directory as the source `.md` file, or the user's Documents folder for unsaved documents |
| BR-03.5 | If the user cancels the save panel, the export operation MUST be silently abandoned — no error shown |
| BR-03.6 | If file write fails, an `NSAlert` MUST be presented with the error description from `ExportError.fileWriteFailed` |
| BR-03.7 | Export MUST NOT block the editor — the user should be able to continue editing while the export runs in the background |

---

## BR-04: Sidebar

| Rule | Description |
|------|-------------|
| BR-04.1 | The sidebar MUST display recently opened `.md` files sourced from `NSDocumentController.shared.recentDocumentURLs` |
| BR-04.2 | Sidebar items MUST be sorted by last opened date, most recent first |
| BR-04.3 | The currently active document MUST be visually distinguished in the sidebar (highlight or accent color) |
| BR-04.4 | Clicking a sidebar item MUST open that document via `NSDocumentController.shared.openDocument(withContentsOf:display:)` |
| BR-04.5 | Sidebar visibility MUST be toggleable via toolbar button and keyboard shortcut Cmd+Shift+L |
| BR-04.6 | Sidebar visibility state MUST persist across app launches (store in UserDefaults) |
| BR-04.7 | When no recent files exist, the sidebar MUST display a "No Recent Files" placeholder — not an empty blank area |
| BR-04.8 | Sidebar MUST update its list when a document is opened or closed (observe `NSDocumentController` notifications) |
| BR-04.9 | Sidebar width MUST be constrained to a reasonable range (180-280 points) to prevent it from dominating the window |
| BR-04.10 | File display names MUST omit the `.md` extension for cleaner presentation |

---

## BR-05: Dark Mode

| Rule | Description |
|------|-------------|
| BR-05.1 | All UI surfaces (editor, sidebar, toolbar, preferences) MUST adapt to the current effective appearance (light or dark) |
| BR-05.2 | The editor background MUST use semantic colors: white-ish in light mode, dark gray (#1E1E1E) in dark mode |
| BR-05.3 | Editor text MUST use `.labelColor` (black in light, near-white in dark) — never hardcoded color values |
| BR-05.4 | Syntax highlighting colors in active blocks MUST use `NSColor` semantic/system colors that resolve dynamically (`.secondaryLabelColor`, `.linkColor`, `.systemOrange`, `.systemGreen`) |
| BR-05.5 | The sidebar MUST use `.windowBackgroundColor` for its background and `.labelColor` / `.secondaryLabelColor` for text |
| BR-05.6 | Inactive rendered blocks (styled output) MUST use semantic colors — bold text in `.labelColor`, links in `.linkColor`, code backgrounds in system-appropriate tint |
| BR-05.7 | Appearance changes MUST trigger a full `RenderCache` invalidation and re-render of all editor blocks (per Unit 1 BR-05.6) |
| BR-05.8 | The transition between light and dark modes MUST be immediate — no fade animation on the editor content |

---

## BR-06: Appearance Override

| Rule | Description |
|------|-------------|
| BR-06.1 | `EditorSettings.appearanceOverride` MUST support three modes: `.system`, `.light`, `.dark` |
| BR-06.2 | `.system` mode MUST follow the macOS system appearance and update automatically when the user toggles Dark Mode in System Settings |
| BR-06.3 | `.light` mode MUST force `NSApp.appearance = NSAppearance(named: .aqua)` regardless of system setting |
| BR-06.4 | `.dark` mode MUST force `NSApp.appearance = NSAppearance(named: .darkAqua)` regardless of system setting |
| BR-06.5 | Appearance override MUST be persisted in UserDefaults (key: `editor.appearanceOverride`) and restored on app launch |
| BR-06.6 | Changing appearance override MUST take effect immediately — no app restart required |
| BR-06.7 | Appearance override applies app-wide — all open document windows MUST reflect the same appearance |
| BR-06.8 | The Preferences UI for appearance selection MUST show a segmented picker or dropdown with the three options, with the current selection highlighted |

---

## Keyboard Shortcuts (Export & Sidebar)

| Shortcut | Action | Notes |
|----------|--------|-------|
| Cmd+Shift+E | Export to HTML | Opens save dialog with `.html` type |
| Cmd+Shift+P | Export to PDF | Opens save dialog with `.pdf` type |
| Cmd+Shift+L | Toggle sidebar | Show/hide recent files sidebar |
