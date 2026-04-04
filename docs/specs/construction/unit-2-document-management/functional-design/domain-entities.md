---
layout: default
---

# Domain Entities: Unit 2 — Document Management

## MarkdownDocument (NSDocument)

The document model for Shoe Choo, subclassing `NSDocument` to leverage macOS native document architecture (auto-save, Versions, Recent Files).

```swift
class MarkdownDocument: NSDocument {
    var sourceText: String                      // Raw Markdown source
    var viewModel: EditorViewModel?             // Attached editor (created on makeWindowControllers)

    // NSDocument overrides
    override func read(from data: Data, ofType typeName: String) throws
    override func data(ofType typeName: String) throws -> Data
    override func defaultDraftName() -> String

    // Asset management
    func assetsDirectoryURL() -> URL?           // .md file's sibling assets/ directory
    func ensureAssetsDirectory() throws         // Create assets/ if needed
}
```

### DocumentState

Tracks the lifecycle state of a document within the app.

```swift
enum DocumentState: Equatable {
    case blank                                  // New untitled document, never saved
    case saved(url: URL)                        // Saved to disk at known URL
    case edited                                 // Has unsaved changes (NSDocument.isDocumentEdited)
    case conflict                               // Save conflict detected (NSDocument ubiquity)
}
```

---

## EditorSettings (@Observable Singleton)

Global user preferences for the editor, persisted via UserDefaults.

```swift
@Observable
final class EditorSettings {
    static let shared = EditorSettings()

    var fontFamily: String                      // e.g., "SF Mono", "Menlo"
    var fontSize: CGFloat                       // Points, e.g., 14.0
    var lineSpacing: CGFloat                    // Multiplier, e.g., 1.4
    var appearanceOverride: AppearanceMode      // .system, .light, .dark
    var defaultFocusMode: Bool                  // Default state for new documents
    var defaultTypewriterScroll: Bool           // Default state for new documents

    private init()                              // Singleton — load from UserDefaults
    func save()                                 // Persist to UserDefaults
    func reset()                                // Restore factory defaults
}
```

### AppearanceMode

```swift
enum AppearanceMode: String, CaseIterable, Codable {
    case system                                 // Follow macOS appearance
    case light                                  // Force light
    case dark                                   // Force dark
}
```

### EditorSettingsKey

UserDefaults keys for EditorSettings persistence.

```swift
enum EditorSettingsKey: String {
    case fontFamily         = "editor.fontFamily"
    case fontSize           = "editor.fontSize"
    case lineSpacing        = "editor.lineSpacing"
    case appearanceOverride = "editor.appearanceOverride"
    case defaultFocusMode   = "editor.defaultFocusMode"
    case defaultTypewriterScroll = "editor.defaultTypewriterScroll"
}
```

---

## EditorViewModel (@Observable)

Per-document view model bridging the document model, parser pipeline (Unit 1), and the view layer.

```swift
@Observable
class EditorViewModel {
    // State
    var sourceText: String                      // Synced with MarkdownDocument.sourceText
    var nodeModel: EditorNodeModel              // Block tree from Unit 1 parser
    var cursorPosition: Int                     // UTF-16 offset
    var activeBlockID: EditorNode.ID?           // Currently active block
    var isFocusModeEnabled: Bool
    var isTypewriterScrollEnabled: Bool

    // Document binding
    weak var document: MarkdownDocument?        // Back-reference for save coordination

    // Methods
    func textDidChange(_ newText: String, editedRange: NSRange)
    func cursorDidMove(to position: Int)
    func attributedStringForDisplay() -> NSAttributedString
    func rerenderBlock(_ blockID: EditorNode.ID)
    func toggleFocusMode()
    func toggleTypewriterScroll()
    func insertImage(url: URL)
    func exportHTML() -> String
    func exportPDF() -> Data
}
```

---

## RecentFileEntry

Represents a recently opened file for the File > Open Recent menu. Managed by NSDocumentController automatically; this entity is for internal tracking if needed.

```swift
struct RecentFileEntry: Identifiable, Codable {
    let id: UUID
    var url: URL                                // File URL
    var lastOpened: Date                        // Last access timestamp
    var displayName: String                     // File name without extension
}
```

---

## FileService (Actor)

Low-level async file I/O service, isolated via Swift actor for thread safety.

```swift
actor FileService {
    func createDirectoryIfNeeded(at url: URL) throws
    func fileExists(at url: URL) -> Bool
    func safeWrite(data: Data, to url: URL) throws   // Atomic write via temporary file
}
```

---

## ToolbarItem

Represents a toolbar button in the editor toolbar.

```swift
struct ToolbarItem: Identifiable {
    let id: String                              // e.g., "bold", "heading1"
    var label: String                           // Display label
    var systemImage: String                     // SF Symbol name
    var shortcutHint: String?                   // e.g., "Cmd+B"
    var action: () -> Void                      // Callback
}
```

---

## FontDescriptor

Describes a selectable font for the Preferences UI.

```swift
struct FontDescriptor: Identifiable, Hashable {
    let id: String                              // Font family name
    var displayName: String                     // Localized display name
    var isMonospaced: Bool                      // For code-friendly fonts
    var sampleText: String                      // Preview string
}
```

---

## Factory Defaults

| Setting | Default Value | Rationale |
|---------|:---:|-----------|
| fontFamily | "SF Mono" | macOS system monospace, excellent readability |
| fontSize | 14.0 | Standard comfortable reading size |
| lineSpacing | 1.4 | Balanced density vs readability |
| appearanceOverride | .system | Respect user's macOS setting |
| defaultFocusMode | false | Not all users want focus mode on launch |
| defaultTypewriterScroll | false | Opt-in feature |
