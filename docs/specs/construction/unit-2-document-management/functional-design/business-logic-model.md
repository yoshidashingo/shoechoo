---
layout: default
---

# Business Logic Model: Unit 2 — Document Management

## Pipeline Overview

```
App Launch
    |
    v
[1] ShoechooApp Scene Setup
    | DocumentGroup scene with MarkdownDocument
    | Tabbed window support via .windowStyle
    v
[2] Document Lifecycle (Create / Open / Save)
    | NSDocument read/write pipeline
    | EditorViewModel binding
    v
[3] Auto-Save & Versions
    | NSDocument autosaving-in-place
    | macOS Versions integration
    v
[4] EditorView Composition
    | Toolbar + WYSIWYGTextView layout
    | EditorSettings observation
    v
[5] EditorSettings Persistence
    | UserDefaults read/write
    | Preferences window
    v
[6] Recent Files
    | NSDocumentController.shared.recentDocumentURLs
    | File > Open Recent menu
```

---

## [1] ShoechooApp Scene Setup

**Trigger**: App launch via `@main` entry point

**Logic**:
1. Declare `DocumentGroup` scene with `MarkdownDocument` as the document type
2. Register `.md` UTType (conforming to `public.plain-text`)
3. Set `windowStyle(.automatic)` for native macOS tabbed window support
4. Register menu commands (File, Edit, Format, View)
5. Apply `EditorSettings.shared.appearanceOverride` to the window's appearance
6. On first launch with no restored windows: create one blank document

```swift
@main
struct ShoechooApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { MarkdownDocument() }) { config in
            EditorView(document: config.document)
        }
        .commands {
            FileCommands()
            FormatCommands()
            ViewCommands()
        }

        Settings {
            PreferencesView()
        }
    }
}
```

---

## [2] Document Lifecycle

### Create New Document

**Trigger**: App launch (blank document) or Cmd+N

**Logic**:
1. `NSDocumentController.shared.newDocument(nil)` creates a new `MarkdownDocument`
2. `MarkdownDocument.init()` sets `sourceText = ""` (blank)
3. `makeWindowControllers()` creates the window and `EditorViewModel`
4. `EditorViewModel` initializes with empty source, applies defaults from `EditorSettings.shared`:
   - `isFocusModeEnabled = EditorSettings.shared.defaultFocusMode`
   - `isTypewriterScrollEnabled = EditorSettings.shared.defaultTypewriterScroll`
5. Document state is `.blank` (untitled, never saved)
6. `defaultDraftName()` returns localized "Untitled" string

### Open Existing Document

**Trigger**: Cmd+O, File > Open, File > Open Recent, double-click .md file, drag onto Dock icon

**Logic**:
1. `NSDocumentController.shared.openDocument(withContentsOf:display:completionHandler:)`
2. `MarkdownDocument.read(from:ofType:)` is called:
   - Decode `Data` as UTF-8 string
   - If decoding fails, try other encodings (Shift_JIS, EUC-JP) as fallback
   - Store decoded string in `sourceText`
3. `makeWindowControllers()` creates window + `EditorViewModel`
4. `EditorViewModel.sourceText` is set, triggering Unit 1 parse pipeline
5. Document state is `.saved(url:)`
6. URL is added to recent documents via `NSDocumentController.noteNewRecentDocumentURL()`

### Save Document (Cmd+S)

**Trigger**: Cmd+S or File > Save

**Logic**:
1. If document is untitled (never saved): redirect to Save As (NSSavePanel)
2. `MarkdownDocument.data(ofType:)` is called:
   - Encode `sourceText` as UTF-8 `Data`
   - Return data for NSDocument to write
3. NSDocument writes to the file URL
4. Document state transitions to `.saved(url:)`
5. `isDocumentEdited` is set to `false`

### Save As (Cmd+Shift+S)

**Trigger**: Cmd+Shift+S or File > Save As

**Logic**:
1. NSDocument presents `NSSavePanel` with `.md` file extension filter
2. User selects destination URL
3. `data(ofType:)` encodes source text
4. NSDocument writes to the new URL
5. Document's `fileURL` is updated to the new location
6. Previous file is NOT deleted (standard Save As behavior)

---

## [3] Auto-Save & Versions

**Trigger**: Periodic auto-save by NSDocument (macOS default interval)

**Logic**:
1. `MarkdownDocument` declares `override class var autosavesInPlace: Bool { true }`
2. macOS calls `data(ofType:)` automatically at save intervals
3. NSDocument manages version snapshots via macOS Versions:
   - File > Revert To > Browse All Versions
   - Time Machine integration
4. During auto-save, the parse pipeline is NOT paused (auto-save reads `sourceText` which is always current)
5. If auto-save fails (disk full, permissions), NSDocument presents system error alert

### Concurrency Note
- `data(ofType:)` runs on the main thread (NSDocument requirement)
- `sourceText` is always up-to-date because `textDidChange()` syncs immediately
- No locking needed: single-writer (main thread) for sourceText

---

## [4] EditorView Composition

**Input**: `MarkdownDocument` from DocumentGroup config

**Logic**:
1. `EditorView` receives the `MarkdownDocument` binding
2. Creates or reuses `EditorViewModel` (owned by the document)
3. Layout structure:
   ```
   EditorView (SwiftUI)
   +-------------------------------------------+
   | Toolbar                                   |
   |  [H1] [H2] [B] [I] [K] [Code] [Link] .. |
   +-------------------------------------------+
   | WYSIWYGTextView (NSViewRepresentable)     |
   |                                           |
   |  (Full editor area from Unit 1)           |
   |                                           |
   +-------------------------------------------+
   ```
4. Toolbar buttons invoke `EditorViewModel` methods (toggleBold, setHeading, etc.)
5. `EditorSettings.shared` is observed — font/spacing changes trigger re-render via Unit 1 pipeline
6. Appearance override applied via `.preferredColorScheme()` or `NSApp.appearance`

---

## [5] EditorSettings Persistence

### Load (App Launch)

**Logic**:
1. `EditorSettings.init()` reads from `UserDefaults.standard`
2. For each key in `EditorSettingsKey`:
   - If value exists in UserDefaults: use it
   - If missing: use factory default (see domain-entities.md)
3. Settings object is immediately available as `EditorSettings.shared`

### Save (User Changes)

**Logic**:
1. User modifies setting in Preferences window
2. `@Observable` property setter fires
3. `save()` writes all values to `UserDefaults.standard`
4. All open `EditorView` instances observe the change and re-render:
   - Font change: invalidate all render caches, full re-render
   - Line spacing change: invalidate layout, re-render
   - Appearance change: invalidate render caches (colors change), update window appearance

### Reset

**Logic**:
1. User clicks "Reset to Defaults" in Preferences
2. `reset()` sets all properties to factory defaults
3. `save()` persists factory defaults to UserDefaults
4. All open editors re-render

---

## [6] Recent Files

**Logic**:
1. macOS manages recent files automatically via `NSDocumentController`
2. Opening a document calls `noteNewRecentDocumentURL()` internally
3. File > Open Recent menu is populated by `NSDocumentController.shared.recentDocumentURLs`
4. "Clear Menu" clears the recent list via `clearRecentDocuments(nil)`
5. Maximum recent files count is managed by macOS (default: 10)
6. If a recent file no longer exists on disk, selecting it shows a system "file not found" alert

---

## Tabbed Windows

**Logic**:
1. macOS native tab support is enabled via `DocumentGroup` scene
2. `NSWindow.allowsAutomaticWindowTabbing = true` (default for document-based apps)
3. Window > Merge All Windows merges open documents into tabs
4. Window > Move Tab to New Window separates a tab
5. Cmd+N opens a new tab in the current window (if tab bar is visible) or a new window
6. Tab title shows the document's `displayName` (filename or "Untitled")
7. Tab close button triggers save confirmation if document has unsaved changes
8. Drag-and-drop tab reordering is handled by macOS natively

---

## ViewModel-Document Binding

```
MarkdownDocument                    EditorViewModel
+------------------+               +------------------+
| sourceText       | <--- sync --> | sourceText       |
| fileURL          |               | document (weak)  |
+------------------+               +------------------+
        |                                  |
        v                                  v
  NSDocument auto-save              Unit 1 Parse Pipeline
  reads sourceText                  reads sourceText
  via data(ofType:)                 via textDidChange()
```

**Sync Strategy**:
1. On document open: `MarkdownDocument.sourceText` → `EditorViewModel.sourceText` (one-time push)
2. On every text edit: `EditorViewModel.textDidChange()` updates both `EditorViewModel.sourceText` and `MarkdownDocument.sourceText`
3. On auto-save: `MarkdownDocument.data(ofType:)` reads its own `sourceText` (already current)
4. No bidirectional binding needed — edits always flow from the text view through the ViewModel to the Document
