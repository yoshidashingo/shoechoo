# Domain Entities: Unit 5 — Export & Polish

## ExportFormat

Enumerates the supported export target formats.

```swift
enum ExportFormat: String, CaseIterable, Identifiable {
    case html                                   // Standalone HTML file
    case pdf                                    // PDF document via WKWebView snapshot

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .html: return "html"
        case .pdf:  return "pdf"
        }
    }

    var utType: UTType {
        switch self {
        case .html: return .html
        case .pdf:  return .pdf
        }
    }
}
```

---

## ExportResult

Outcome of an export operation, carrying either generated data or an error.

```swift
struct ExportResult {
    var format: ExportFormat
    var data: Data                              // Generated file bytes (HTML UTF-8 or PDF)
    var suggestedFileName: String               // e.g., "My Document.html"
    var sourceDocumentURL: URL?                 // Original .md file URL, if saved
}
```

---

## ExportError

Typed errors for the export pipeline.

```swift
enum ExportError: LocalizedError {
    case emptySource                            // Source text is empty
    case htmlGenerationFailed(underlying: Error)
    case pdfRenderingFailed(underlying: Error)
    case pdfRenderingTimedOut                   // WKWebView snapshot exceeded timeout
    case fileWriteFailed(url: URL, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .emptySource:
            return "Cannot export an empty document."
        case .htmlGenerationFailed(let e):
            return "HTML generation failed: \(e.localizedDescription)"
        case .pdfRenderingFailed(let e):
            return "PDF rendering failed: \(e.localizedDescription)"
        case .pdfRenderingTimedOut:
            return "PDF rendering timed out."
        case .fileWriteFailed(let url, let e):
            return "Failed to write \(url.lastPathComponent): \(e.localizedDescription)"
        }
    }
}
```

---

## HTMLTemplate

Encapsulates the HTML document structure used for both HTML export and PDF rendering input.

```swift
struct HTMLTemplate {
    var title: String                           // <title> and <h1> if desired
    var cssStyles: String                       // Embedded CSS (light/dark aware)
    var bodyHTML: String                         // Rendered Markdown content as HTML
    var baseURL: URL?                           // For resolving relative image paths

    func assembleFullDocument() -> String {
        // Returns complete <!DOCTYPE html>...<html>...</html>
    }
}
```

### Default CSS Rules

| Element | Style | Rationale |
|---------|-------|-----------|
| body | `font-family: -apple-system; max-width: 720px; margin: auto` | Clean reading width, system font |
| h1-h6 | Scaled sizes matching editor rendering | Visual consistency with WYSIWYG |
| code | `font-family: SF Mono; background: #f5f5f5` | Matches editor code block styling |
| blockquote | `border-left: 3px solid #ccc; padding-left: 1em` | Standard blockquote convention |
| table | `border-collapse: collapse; border: 1px solid #ddd` | Readable table presentation |
| img | `max-width: 100%` | Prevent overflow |

---

## PDFConfiguration

Settings for PDF generation via WKWebView snapshot.

```swift
struct PDFConfiguration {
    var paperSize: CGSize                       // Default: A4 (595.28 x 841.89 points)
    var margins: NSEdgeInsets                   // Default: 72pt (1 inch) all sides
    var timeoutInterval: TimeInterval           // Default: 30 seconds
    var includeBackgroundGraphics: Bool         // Default: true
}
```

### Paper Size Presets

| Preset | Width (pt) | Height (pt) |
|--------|:---:|:---:|
| A4 | 595.28 | 841.89 |
| US Letter | 612 | 792 |

---

## SidebarItem

Represents a single entry displayed in the recent files sidebar.

```swift
struct SidebarItem: Identifiable, Equatable {
    let id: UUID
    var displayName: String                     // File name without .md extension
    var url: URL                                // File URL for opening
    var lastOpened: Date                        // For sorting (most recent first)
    var isCurrentDocument: Bool                 // Highlighted if this is the active document
}
```

---

## SidebarState

Tracks sidebar visibility and selection state.

```swift
@Observable
class SidebarState {
    var isVisible: Bool                         // Toggle via toolbar button or Cmd+Shift+L
    var selectedItemID: SidebarItem.ID?         // Currently selected (highlighted) item
    var items: [SidebarItem]                    // Recent files list, sorted by lastOpened descending

    init() {
        self.isVisible = true                   // Visible by default
        self.selectedItemID = nil
        self.items = []
    }
}
```

---

## AppearanceMode (defined in Unit 2)

Referenced from `EditorSettings.appearanceOverride`. Governs light/dark mode behavior across the entire app.

```swift
// Defined in Unit 2 — EditorSettings
enum AppearanceMode: String, CaseIterable, Codable {
    case system                                 // Follow macOS System Preferences
    case light                                  // Force light appearance
    case dark                                   // Force dark appearance
}
```

### NSAppearance Mapping

| AppearanceMode | NSAppearance.Name | Behavior |
|----------------|:---:|----------|
| .system | `nil` (inherit) | Follows macOS system setting; updates automatically on system toggle |
| .light | `.aqua` | Forces light mode regardless of system setting |
| .dark | `.darkAqua` | Forces dark mode regardless of system setting |

---

## AppearanceColors

Semantic color set for theming. All colors resolve dynamically based on current effective appearance.

```swift
struct AppearanceColors {
    // Editor
    var editorBackground: NSColor               // Light: .white, Dark: #1E1E1E
    var editorText: NSColor                     // Light: .black, Dark: #D4D4D4
    var editorCursor: NSColor                   // Follows system accent color

    // Sidebar
    var sidebarBackground: NSColor              // Light: .windowBackgroundColor, Dark: .windowBackgroundColor
    var sidebarItemText: NSColor                // Light: .labelColor, Dark: .labelColor
    var sidebarItemSelected: NSColor            // System accent with alpha
    var sidebarSeparator: NSColor               // .separatorColor (auto light/dark)

    // Toolbar
    var toolbarBackground: NSColor              // .windowBackgroundColor (auto)

    // Syntax highlighting (active block)
    var syntaxDelimiter: NSColor                // .secondaryLabelColor (auto)
    var syntaxLink: NSColor                     // .linkColor (auto)
    var syntaxCodeFence: NSColor                // .systemOrange (auto)
    var syntaxBlockquoteMarker: NSColor         // .systemGreen (auto)

    static func resolved(for appearance: NSAppearance) -> AppearanceColors
}
```

---

## Factory Defaults

| Setting | Default Value | Rationale |
|---------|:---:|-----------|
| ExportFormat | .html | Most common export target |
| PDFConfiguration.paperSize | A4 | International standard |
| PDFConfiguration.margins | 72pt all sides | Standard 1-inch margins |
| PDFConfiguration.timeoutInterval | 30s | Generous for complex documents |
| SidebarState.isVisible | true | Sidebar visible by default for discoverability |
| AppearanceMode | .system | Respect user's macOS setting |
