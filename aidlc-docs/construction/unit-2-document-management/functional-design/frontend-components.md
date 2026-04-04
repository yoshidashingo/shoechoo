# Frontend Components: Unit 2 — Document Management

## ShoechooApp (App Entry Point)

### Scene Structure

```
ShoechooApp (@main)
+--------------------------------------------------+
| DocumentGroup                                    |
|   newDocument: MarkdownDocument()                |
|   editor: { config in                            |
|       EditorView(document: config.document)      |
|   }                                              |
|                                                  |
| Settings                                         |
|   PreferencesView()                              |
+--------------------------------------------------+
| .commands {                                      |
|     FileCommands()                               |
|     FormatCommands()                             |
|     ViewCommands()                               |
| }                                                |
+--------------------------------------------------+
```

### App Lifecycle Responsibilities

| Responsibility | Mechanism |
|---------------|-----------|
| Document type registration | UTType `.md` declared in Info.plist, handled by DocumentGroup |
| New document (Cmd+N) | DocumentGroup built-in |
| Open document (Cmd+O) | DocumentGroup built-in (NSOpenPanel) |
| Save / Save As | NSDocument built-in (Cmd+S, Cmd+Shift+S) |
| Recent files | NSDocumentController built-in (File > Open Recent) |
| Tabbed windows | `NSWindow.allowsAutomaticWindowTabbing` (default for DocumentGroup) |
| Preferences window | `Settings` scene with `PreferencesView` |
| Appearance override | Applied via `NSApp.appearance` on launch and on settings change |

---

## EditorView (SwiftUI View)

### Layout

```
EditorView
+---------------------------------------------------+
| .toolbar {                                        |
|   ToolbarItemGroup(placement: .automatic)         |
|     [H1] [H2] [H3] | [B] [I] [S] [Code] | ...  |
| }                                                 |
+---------------------------------------------------+
| WYSIWYGTextView (NSViewRepresentable — Unit 1)    |
|                                                   |
|   Full WYSIWYG editor area                        |
|   Backed by ShoechooTextView (NSTextView)         |
|   TextKit 2 stack                                 |
|                                                   |
+---------------------------------------------------+
```

### View Binding

```swift
struct EditorView: View {
    @Bindable var document: MarkdownDocument
    @State private var viewModel: EditorViewModel

    init(document: MarkdownDocument) {
        self.document = document
        self._viewModel = State(initialValue: document.viewModel
            ?? EditorViewModel(document: document))
    }

    var body: some View {
        WYSIWYGTextView(viewModel: viewModel, settings: .shared)
            .toolbar { EditorToolbar(viewModel: viewModel) }
            .onAppear { document.viewModel = viewModel }
    }
}
```

### EditorToolbar

```swift
struct EditorToolbar: ToolbarContent {
    @Bindable var viewModel: EditorViewModel

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            // Heading group
            Button { viewModel.setHeading(level: 1) } label: {
                Label("Heading 1", systemImage: "number")
            }
            .help("Heading 1 (Cmd+1)")

            Button { viewModel.setHeading(level: 2) } label: {
                Label("Heading 2", systemImage: "number")
            }
            .help("Heading 2 (Cmd+2)")

            Button { viewModel.setHeading(level: 3) } label: {
                Label("Heading 3", systemImage: "number")
            }
            .help("Heading 3 (Cmd+3)")

            Divider()

            // Inline formatting group
            Button { viewModel.toggleBold() } label: {
                Label("Bold", systemImage: "bold")
            }
            .help("Bold (Cmd+B)")

            Button { viewModel.toggleItalic() } label: {
                Label("Italic", systemImage: "italic")
            }
            .help("Italic (Cmd+I)")

            Button { viewModel.toggleStrikethrough() } label: {
                Label("Strikethrough", systemImage: "strikethrough")
            }
            .help("Strikethrough")

            Button { viewModel.toggleInlineCode() } label: {
                Label("Inline Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .help("Inline Code (Cmd+Shift+K)")

            Divider()

            // Insert group
            Button { viewModel.insertLink() } label: {
                Label("Link", systemImage: "link")
            }
            .help("Link (Cmd+K)")

            Button { viewModel.insertImage() } label: {
                Label("Image", systemImage: "photo")
            }
            .help("Insert Image")
        }
    }
}
```

---

## PreferencesView

### Layout

```
PreferencesView (Settings scene)
+---------------------------------------------------+
| TabView                                           |
| +-----------------------------------------------+ |
| | [Editor] [Appearance]                         | |
| +-----------------------------------------------+ |
| |                                               | |
| | Editor Tab:                                   | |
| |   Font Family:    [Picker: SF Mono     v]    | |
| |   Font Size:      [Stepper: 14 pt]           | |
| |   Line Spacing:   [Slider: 1.4x]             | |
| |                                               | |
| |   [ ] Enable Focus Mode by default           | |
| |   [ ] Enable Typewriter Scroll by default     | |
| |                                               | |
| |   [Reset to Defaults]                         | |
| |                                               | |
| +-----------------------------------------------+ |
| |                                               | |
| | Appearance Tab:                               | |
| |   Appearance:     (o) System                  | |
| |                   ( ) Light                   | |
| |                   ( ) Dark                    | |
| |                                               | |
| |   Preview:                                    | |
| |   +-------------------------------------+    | |
| |   | Sample rendered Markdown text        |    | |
| |   | with current font/spacing settings   |    | |
| |   +-------------------------------------+    | |
| |                                               | |
| +-----------------------------------------------+ |
+---------------------------------------------------+
```

### Implementation

```swift
struct PreferencesView: View {
    @Bindable var settings = EditorSettings.shared

    var body: some View {
        TabView {
            EditorPreferencesTab(settings: settings)
                .tabItem { Label("Editor", systemImage: "pencil") }

            AppearancePreferencesTab(settings: settings)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 450, height: 300)
    }
}
```

```swift
struct EditorPreferencesTab: View {
    @Bindable var settings: EditorSettings

    var body: some View {
        Form {
            Picker("Font Family", selection: $settings.fontFamily) {
                ForEach(FontCatalog.all) { font in
                    Text(font.displayName).tag(font.id)
                }
            }

            Stepper("Font Size: \(settings.fontSize, specifier: "%.0f") pt",
                    value: $settings.fontSize, in: 10...24, step: 1)

            HStack {
                Text("Line Spacing: \(settings.lineSpacing, specifier: "%.1f")x")
                Slider(value: $settings.lineSpacing, in: 1.0...2.0, step: 0.1)
            }

            Divider()

            Toggle("Enable Focus Mode by default", isOn: $settings.defaultFocusMode)
            Toggle("Enable Typewriter Scroll by default", isOn: $settings.defaultTypewriterScroll)

            Divider()

            Button("Reset to Defaults") { settings.reset() }
        }
        .padding()
    }
}
```

```swift
struct AppearancePreferencesTab: View {
    @Bindable var settings: EditorSettings

    var body: some View {
        Form {
            Picker("Appearance", selection: $settings.appearanceOverride) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.radioGroup)

            GroupBox("Preview") {
                Text("The quick brown fox jumps over the lazy dog.\n**Bold text** and *italic text* with `inline code`.")
                    .font(.custom(settings.fontFamily, size: settings.fontSize))
                    .lineSpacing(settings.fontSize * (settings.lineSpacing - 1.0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
        }
        .padding()
    }
}
```

---

## User Interaction Flows

### Flow 1: App Launch (No Restored Windows)

```
1. ShoechooApp.init()
2. EditorSettings.shared loads from UserDefaults
3. DocumentGroup scene activates
4. NSDocumentController detects no restorable windows
5. Creates new MarkdownDocument (blank)
6. makeWindowControllers() → EditorView with empty sourceText
7. User sees blank editor with toolbar, ready to type
```

### Flow 2: Open File via Cmd+O

```
1. User presses Cmd+O
2. NSDocumentController presents NSOpenPanel (filtered to .md files)
3. User selects file → MarkdownDocument.read(from:ofType:)
4. sourceText decoded from file data
5. EditorView created with viewModel bound to document
6. Unit 1 parse pipeline runs → WYSIWYG rendering appears
7. File added to recent documents
```

### Flow 3: Open Recent File

```
1. User opens File > Open Recent
2. NSDocumentController populates menu from recentDocumentURLs
3. User selects a file
4. NSDocumentController opens the document (same as Flow 2, step 3+)
5. If file not found: system alert displayed
```

### Flow 4: Tabbed Window Management

```
1. User has document open, presses Cmd+N
2. If tab bar visible: new tab created in current window
3. If tab bar hidden: new window created
4. User can: Window > Merge All Windows to combine
5. User can: drag tabs to reorder
6. User can: drag tab out to create new window
7. Each tab has independent EditorViewModel
```

### Flow 5: Change Font in Preferences

```
1. User opens Shoe Choo > Settings (Cmd+,)
2. PreferencesView appears
3. User changes Font Family from "SF Mono" to "Menlo"
4. EditorSettings.shared.fontFamily updates (@ Observable)
5. EditorSettings.save() persists to UserDefaults
6. All open EditorView instances observe the change
7. RenderCache invalidated in each EditorViewModel
8. Full re-render with new font in all editors
```

### Flow 6: Auto-Save Triggers

```
1. User edits text in document
2. EditorViewModel.textDidChange() updates MarkdownDocument.sourceText
3. NSDocument marks document as edited (dot in close button)
4. After macOS auto-save interval:
5. NSDocument calls data(ofType:) → encodes current sourceText
6. File written to disk
7. Document marked as not edited
8. User continues editing uninterrupted
```

---

## Keyboard Shortcut Registration

```swift
// In ShoechooApp .commands block
.commands {
    // File commands (Cmd+N, Cmd+O, Cmd+S, Cmd+Shift+S)
    // are provided by DocumentGroup automatically

    // Format commands (from Unit 1, registered here for menu visibility)
    CommandGroup(replacing: .textFormatting) {
        Button("Bold") { focusedViewModel?.toggleBold() }
            .keyboardShortcut("b", modifiers: .command)
        Button("Italic") { focusedViewModel?.toggleItalic() }
            .keyboardShortcut("i", modifiers: .command)
        Button("Link") { focusedViewModel?.insertLink() }
            .keyboardShortcut("k", modifiers: .command)
        Button("Inline Code") { focusedViewModel?.toggleInlineCode() }
            .keyboardShortcut("k", modifiers: [.command, .shift])
    }
    CommandGroup(after: .textFormatting) {
        ForEach(1...6, id: \.self) { level in
            Button("Heading \(level)") { focusedViewModel?.setHeading(level: level) }
                .keyboardShortcut(KeyEquivalent(Character("\(level)")), modifiers: .command)
        }
    }

    // View commands
    CommandGroup(after: .toolbar) {
        Button("Toggle Focus Mode") { focusedViewModel?.toggleFocusMode() }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        Button("Toggle Typewriter Scroll") { focusedViewModel?.toggleTypewriterScroll() }
            .keyboardShortcut("t", modifiers: [.command, .shift])
    }
}
```

### FocusedValue for ViewModel Access

```swift
// FocusedValue key for accessing the active document's ViewModel
struct FocusedViewModelKey: FocusedValueKey {
    typealias Value = EditorViewModel
}

extension FocusedValues {
    var editorViewModel: EditorViewModel? {
        get { self[FocusedViewModelKey.self] }
        set { self[FocusedViewModelKey.self] = newValue }
    }
}

// In EditorView:
.focusedValue(\.editorViewModel, viewModel)

// In ShoechooApp commands:
@FocusedValue(\.editorViewModel) var focusedViewModel
```

---

## UTType Declaration

```swift
// In Info.plist or via UTType extension
extension UTType {
    static let markdown = UTType(
        exportedAs: "net.danluu.markdown",
        conformingTo: .plainText
    )
}

// Document type declaration
// Supported file extensions: .md, .markdown, .mdown, .mkd
// MIME type: text/markdown
```
