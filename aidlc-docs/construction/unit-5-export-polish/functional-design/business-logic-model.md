# Business Logic Model: Unit 5 — Export & Polish

## Pipeline Overview

```
Export Flow (HTML):
  User triggers Cmd+Shift+E
      |
      v
  [1] EditorViewModel.exportHTML()
      | Reads sourceText from document
      v
  [2] ExportService.generateHTML(from: sourceText, title: documentTitle)
      | swift-markdown AST walk → HTML tags
      | Wrap in HTMLTemplate with CSS
      v
  [3] Save Dialog (NSSavePanel)
      | User selects destination
      v
  [4] Write HTML file to disk

Export Flow (PDF):
  User triggers Cmd+Shift+P
      |
      v
  [1] EditorViewModel.exportPDF()
      | Reads sourceText from document
      v
  [2] ExportService.generateHTML(from: sourceText, title: documentTitle)
      | Same HTML generation as above
      v
  [3] ExportService.generatePDF(from: html)
      | Load HTML in offscreen WKWebView
      | WKWebView.createPDF(configuration:)
      v
  [4] Save Dialog (NSSavePanel)
      | User selects destination
      v
  [5] Write PDF data to disk
```

---

## [1] Export Trigger

**Trigger**: Menu item or keyboard shortcut (Cmd+Shift+E for HTML, Cmd+Shift+P for PDF)

**Logic**:
1. Read `sourceText` from `EditorViewModel`
2. Derive `title` from document file name (without `.md` extension), or "Untitled" for unsaved documents
3. Derive `baseURL` from document file URL's parent directory (for relative image paths)
4. Call the appropriate `ExportService` method

---

## [2] HTML Generation Pipeline (ExportService.generateHTML)

**Input**: `source: String` (raw Markdown), `title: String`

**Logic**:
1. Parse source with `MarkdownParser.parse(source)` → `Markup` AST (swift-markdown)
2. Walk the AST depth-first, converting each node to HTML tags:

   | AST Node | HTML Output |
   |----------|-------------|
   | `Heading(level: n)` | `<h{n}>...</h{n}>` |
   | `Paragraph` | `<p>...</p>` |
   | `Strong` | `<strong>...</strong>` |
   | `Emphasis` | `<em>...</em>` |
   | `Strikethrough` | `<del>...</del>` |
   | `InlineCode` | `<code>...</code>` |
   | `CodeBlock(language:)` | `<pre><code class="language-{lang}">...</code></pre>` |
   | `Link(destination:)` | `<a href="{url}">...</a>` |
   | `Image(source:, title:)` | `<img src="{src}" alt="{alt}" title="{title}">` |
   | `UnorderedList` | `<ul>...<li>...</li>...</ul>` |
   | `OrderedList` | `<ol start="{n}">...<li>...</li>...</ol>` |
   | `ListItem` with checkbox | `<li><input type="checkbox" disabled {checked}>...</li>` |
   | `BlockQuote` | `<blockquote>...</blockquote>` |
   | `Table` | `<table>...<thead>...<tbody>...</table>` |
   | `ThematicBreak` | `<hr>` |
   | `SoftBreak` | ` ` (space) |
   | `LineBreak` | `<br>` |
   | `Text` | Escaped plain text |

3. Escape HTML entities in text content (`<`, `>`, `&`, `"`, `'`)
4. Preserve image `src` as-is (relative paths remain relative)
5. Assemble `HTMLTemplate`:
   - Set `title` from parameter
   - Set `cssStyles` from built-in default CSS
   - Set `bodyHTML` from generated HTML
   - Set `baseURL` from document location (passed through)
6. Call `HTMLTemplate.assembleFullDocument()` → complete HTML string
7. Return HTML string encoded as UTF-8

**Concurrency**: Runs on `ExportService` actor (isolated). AST walk is synchronous within the actor.

---

## [3] PDF Generation Pipeline (ExportService.generatePDF)

**Input**: `html: String` (complete HTML document from step 2)

**Logic**:
1. Create an offscreen `WKWebView` (not added to any window)
   - Configure with `WKWebViewConfiguration`:
     - `suppressesIncrementalRendering = true` (wait for full load)
2. Load the HTML string into `WKWebView` via `loadHTMLString(_:baseURL:)`
   - `baseURL` set to document directory for relative image resolution
3. Wait for `WKNavigationDelegate.webView(_:didFinish:)` callback
   - Guard with timeout (`PDFConfiguration.timeoutInterval`, default 30s)
   - If timeout fires before load completes, throw `ExportError.pdfRenderingTimedOut`
4. Call `WKWebView.createPDF(configuration:)` with:
   - `WKPDFConfiguration.rect` set from `PDFConfiguration.paperSize` and `margins`
   - `allowTransparentBackground = false`
5. Receive `Data` (PDF bytes) from completion handler
6. Clean up WKWebView (remove from memory)
7. Return PDF `Data`

**Concurrency**: `WKWebView` must be created and operated on the main thread (`@MainActor`). The `ExportService.generatePDF` method internally dispatches to `MainActor` for WebView operations, then returns the result to the caller.

**Main Actor Isolation for WKWebView**:
```swift
actor ExportService {
    func generatePDF(from html: String, baseURL: URL?, configuration: PDFConfiguration) async throws -> Data {
        try await MainActor.run {
            // Create WKWebView, load HTML, await navigation, create PDF
        }
    }
}
```

---

## [4] Save Dialog

**Input**: `ExportResult` with generated data

**Logic**:
1. Present `NSSavePanel`:
   - `allowedContentTypes`: `[exportResult.format.utType]`
   - `nameFieldStringValue`: `exportResult.suggestedFileName`
   - `directoryURL`: Same directory as source `.md` file, or user's Documents folder
2. If user confirms (`.OK`):
   - Write `exportResult.data` to selected URL
   - On success: no additional feedback (file appears in Finder)
   - On failure: present `NSAlert` with `ExportError.fileWriteFailed`
3. If user cancels: no action

---

## Sidebar Data Flow

```
App Launch / Document Open / Document Close
    |
    v
[1] Sidebar Load
    | Query NSDocumentController.shared.recentDocumentURLs
    | Convert to [SidebarItem]
    v
[2] Sidebar Display
    | SidebarView renders items sorted by lastOpened descending
    | Current document highlighted
    v
[3] User Interaction
    | Click item → open document
    | Toggle visibility → Cmd+Shift+L or toolbar button
```

### [1] Sidebar Load

**Trigger**: App launch, document open, document close, or sidebar becomes visible

**Logic**:
1. Read `NSDocumentController.shared.recentDocumentURLs` (macOS manages this list)
2. For each URL, construct `SidebarItem`:
   - `displayName`: file name without `.md` extension
   - `url`: the file URL
   - `lastOpened`: file's last access date from file attributes (`URLResourceKey.contentAccessDateKey`)
   - `isCurrentDocument`: compare with `NSDocumentController.shared.currentDocument?.fileURL`
3. Sort by `lastOpened` descending (most recent first)
4. Update `SidebarState.items`

### [2] Sidebar Display

**Input**: `SidebarState`

**Logic**:
1. If `sidebarState.isVisible == false`, sidebar column is collapsed (zero width)
2. Render `List` of `SidebarItem` entries
3. Current document row shows a distinct selection highlight
4. Empty state: show "No Recent Files" placeholder text

### [3] User Interaction — Open File

**Input**: User clicks a `SidebarItem`

**Logic**:
1. Set `sidebarState.selectedItemID` to clicked item
2. Call `NSDocumentController.shared.openDocument(withContentsOf: item.url, display: true)`
3. The document system handles window creation and editor attachment

---

## Dark Mode Propagation

```
User changes AppearanceMode in Preferences
    |
    v
[1] EditorSettings.appearanceOverride updated
    | @Observable triggers SwiftUI view updates
    v
[2] NSApp.appearance updated
    | Maps AppearanceMode → NSAppearance
    v
[3] All views re-render
    | NSWindow inherits new appearance
    | SwiftUI views adapt automatically via system colors
    | NSTextView attributed strings re-rendered
    v
[4] RenderCache invalidated
    | All cached block renders flushed
    | Full re-render of editor content
```

### [1] Appearance Override Update

**Trigger**: User selects appearance mode in Preferences (Picker)

**Logic**:
1. `EditorSettings.shared.appearanceOverride` is set to new value
2. Persist to UserDefaults via `EditorSettings.save()`

### [2] NSApp.appearance Propagation

**Logic**:
1. Observe `EditorSettings.shared.appearanceOverride` in `ShoechooApp`
2. Map to `NSAppearance`:
   - `.system` → set `NSApp.appearance = nil` (inherit system)
   - `.light` → set `NSApp.appearance = NSAppearance(named: .aqua)`
   - `.dark` → set `NSApp.appearance = NSAppearance(named: .darkAqua)`
3. All `NSWindow` instances inherit the app-level appearance
4. SwiftUI environment `.colorScheme` updates automatically

### [3] View Re-rendering

**Logic**:
1. SwiftUI views using system colors (`.primary`, `.secondary`, `.background`) adapt automatically
2. `SidebarView` background and text colors update via `NSColor` dynamic resolution
3. `EditorView` toolbar adapts via `.windowToolbarStyle`
4. `WYSIWYGTextView` triggers full re-render:
   - `RenderCache.invalidateAll()` (BR-05.6 from Unit 1)
   - All blocks re-rendered with new appearance colors
   - Syntax highlighting colors resolve to new values via `NSColor` semantic colors

### [4] RenderCache Invalidation

**Logic**:
1. Detect appearance change via `NSApplication.effectiveAppearance` observation
2. Call `RenderCache.invalidateAll()`
3. Trigger selective re-render for all visible blocks
4. TextKit 2 display update applies new attributed strings
