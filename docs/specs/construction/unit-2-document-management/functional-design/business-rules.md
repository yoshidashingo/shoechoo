---
layout: default
---

# Business Rules: Unit 2 — Document Management

## BR-01: Document Lifecycle

| Rule | Description |
|------|-------------|
| BR-01.1 | On app launch with no restored windows, exactly ONE blank document MUST be created |
| BR-01.2 | Cmd+N MUST create a new blank document (new tab if tab bar visible, new window otherwise) |
| BR-01.3 | New blank documents MUST have `defaultDraftName()` as "Untitled" (localized) |
| BR-01.4 | Opening a file MUST decode data as UTF-8; if UTF-8 fails, attempt Shift_JIS and EUC-JP before reporting error |
| BR-01.5 | Save (Cmd+S) on an untitled document MUST present Save As (NSSavePanel) |
| BR-01.6 | Save As (Cmd+Shift+S) MUST NOT delete the original file |
| BR-01.7 | `data(ofType:)` MUST encode sourceText as UTF-8 |
| BR-01.8 | Closing a document with unsaved changes MUST present the standard macOS save confirmation dialog |

---

## BR-02: Auto-Save & Versions

| Rule | Description |
|------|-------------|
| BR-02.1 | `MarkdownDocument` MUST declare `autosavesInPlace` returning `true` |
| BR-02.2 | Auto-save MUST NOT pause or interfere with the Unit 1 parse pipeline |
| BR-02.3 | Auto-save MUST use the current `sourceText` at the time `data(ofType:)` is called |
| BR-02.4 | macOS Versions (File > Revert To > Browse All Versions) MUST be supported via NSDocument |
| BR-02.5 | If auto-save fails (disk full, permissions), the standard NSDocument error alert MUST be shown |
| BR-02.6 | The document MUST NOT be marked as saved (isDocumentEdited = false) if auto-save fails |

---

## BR-03: Tabbed Windows

| Rule | Description |
|------|-------------|
| BR-03.1 | Tabbed windows MUST be enabled via macOS native `NSWindow.allowsAutomaticWindowTabbing` |
| BR-03.2 | Each tab MUST display the document's `displayName` (filename or "Untitled") |
| BR-03.3 | Window > Merge All Windows and Window > Move Tab to New Window MUST function via native macOS behavior |
| BR-03.4 | Tab close MUST trigger save confirmation if the document has unsaved changes |
| BR-03.5 | Drag-and-drop tab reordering MUST be supported (macOS native) |
| BR-03.6 | Each tab MUST have its own independent `EditorViewModel` instance |

---

## BR-04: Recent Files

| Rule | Description |
|------|-------------|
| BR-04.1 | Opening a document MUST add its URL to the recent documents list via NSDocumentController |
| BR-04.2 | File > Open Recent MUST display recent files managed by NSDocumentController |
| BR-04.3 | File > Open Recent > Clear Menu MUST clear the recent documents list |
| BR-04.4 | Selecting a recent file that no longer exists MUST display a system "file not found" error |
| BR-04.5 | The app MUST register the `.md` UTType so that .md files open in Shoe Choo when double-clicked |

---

## BR-05: EditorSettings Persistence

| Rule | Description |
|------|-------------|
| BR-05.1 | EditorSettings MUST be a singleton accessed via `EditorSettings.shared` |
| BR-05.2 | All settings MUST be persisted to `UserDefaults.standard` using `EditorSettingsKey` keys |
| BR-05.3 | On first launch (no UserDefaults values), factory defaults MUST be applied (see domain-entities.md) |
| BR-05.4 | Settings changes MUST be applied immediately to all open editor windows |
| BR-05.5 | "Reset to Defaults" MUST restore all settings to factory defaults and persist them |
| BR-05.6 | Font family change MUST invalidate all render caches and trigger full re-render in all open editors |
| BR-05.7 | Font size change MUST invalidate all render caches and trigger full re-render in all open editors |
| BR-05.8 | Line spacing change MUST invalidate layout and trigger re-render in all open editors |
| BR-05.9 | Appearance override change MUST invalidate render caches (colors differ) and update window appearance |

---

## BR-06: Font & Line Spacing

| Rule | Description |
|------|-------------|
| BR-06.1 | Font family MUST be selectable from a curated list of monospaced and proportional fonts |
| BR-06.2 | Font size MUST be adjustable in the range 10.0 ... 24.0 points, in 1-point increments |
| BR-06.3 | Line spacing MUST be adjustable in the range 1.0 ... 2.0, in 0.1 increments |
| BR-06.4 | Font and line spacing changes MUST be previewed in real-time in all open editors |
| BR-06.5 | The selected font MUST be used for body text rendering; heading sizes are relative to the base font size |
| BR-06.6 | Code blocks and inline code MUST always render in a monospaced font regardless of the body font setting |

### Curated Font List

| Font Family | Type | Bundled with macOS |
|-------------|:---:|:---:|
| SF Mono | Monospaced | Yes (14+) |
| Menlo | Monospaced | Yes |
| Monaco | Monospaced | Yes |
| Courier New | Monospaced | Yes |
| SF Pro | Proportional | Yes (14+) |
| Helvetica Neue | Proportional | Yes |
| Georgia | Proportional | Yes |

---

## BR-07: Toolbar

| Rule | Description |
|------|-------------|
| BR-07.1 | The toolbar MUST be displayed at the top of the EditorView, above the text editor area |
| BR-07.2 | Toolbar buttons MUST include: Heading (1-3), Bold, Italic, Strikethrough, Inline Code, Link, Image |
| BR-07.3 | Each toolbar button MUST invoke the corresponding `EditorViewModel` method |
| BR-07.4 | Toolbar buttons MUST use SF Symbols for icons |
| BR-07.5 | Toolbar buttons MUST show a tooltip with the keyboard shortcut hint on hover |
| BR-07.6 | Toolbar buttons for active formatting (e.g., cursor inside bold text) SHOULD appear highlighted |
| BR-07.7 | The toolbar MUST be implemented using SwiftUI `.toolbar` modifier for native macOS integration |

### Toolbar Button Mapping

| Button | SF Symbol | ViewModel Method | Shortcut |
|--------|-----------|-----------------|----------|
| Heading 1 | `number` | `setHeading(level: 1)` | Cmd+1 |
| Heading 2 | `number` | `setHeading(level: 2)` | Cmd+2 |
| Heading 3 | `number` | `setHeading(level: 3)` | Cmd+3 |
| Bold | `bold` | `toggleBold()` | Cmd+B |
| Italic | `italic` | `toggleItalic()` | Cmd+I |
| Strikethrough | `strikethrough` | `toggleStrikethrough()` | -- |
| Inline Code | `chevron.left.forwardslash.chevron.right` | `toggleInlineCode()` | Cmd+Shift+K |
| Link | `link` | `insertLink()` | Cmd+K |
| Image | `photo` | `insertImage()` | -- |
