---
layout: default
---

# Frontend Components: Unit 5 — Export & Polish

## Window Layout — NavigationSplitView

```
+-----------------------------------------------------------------------+
| Toolbar: [Toggle Sidebar] [Bold] [Italic] ... [Export HTML] [Export PDF] |
+-----------------------------------------------------------------------+
|            |                                                          |
| Sidebar    |  Editor (WYSIWYGTextView)                                |
| (Recent    |                                                          |
|  Files)    |                                                          |
|            |                                                          |
| - Doc A    |  # My Document                                           |
| - Doc B  * |                                                          |
| - Doc C    |  Some paragraph text with **bold** and *italic*.         |
|            |                                                          |
|            |                                                          |
| [180-280pt]|  [Remaining width]                                       |
+-----------------------------------------------------------------------+
```

### NavigationSplitView Structure

```swift
struct EditorView: View {
    @Bindable var viewModel: EditorViewModel
    @State private var sidebarState = SidebarState()
    let settings = EditorSettings.shared

    var body: some View {
        NavigationSplitView(
            columnVisibility: sidebarVisibilityBinding
        ) {
            SidebarView(state: $sidebarState)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            WYSIWYGTextView(viewModel: viewModel, settings: settings)
        }
        .toolbar { editorToolbarContent }
        .commands { exportCommandGroup }
        .preferredColorScheme(resolvedColorScheme)
    }
}
```

---

## SidebarView (SwiftUI)

### Layout

```
+------------------------+
| RECENT FILES     [pin] |   ← Section header
+------------------------+
| 📄 Meeting Notes       |   ← SidebarItem row
|    Opened 2 hours ago  |
+------------------------+
| 📄 Project Plan      * |   ← Current document (highlighted)
|    Opened today        |
+------------------------+
| 📄 Draft Blog Post     |
|    Opened yesterday    |
+------------------------+
|                        |
|  (scrollable list)     |
|                        |
+------------------------+
```

### Empty State

```
+------------------------+
|                        |
|   📂                   |
|   No Recent Files      |
|                        |
|   Open a .md file to   |
|   see it here.         |
|                        |
+------------------------+
```

### Implementation

```swift
struct SidebarView: View {
    @Binding var state: SidebarState

    var body: some View {
        Group {
            if state.items.isEmpty {
                emptyStateView
            } else {
                recentFilesList
            }
        }
        .onAppear { loadRecentFiles() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            loadRecentFiles()       // Refresh when app regains focus
        }
    }

    private var recentFilesList: some View {
        List(state.items, selection: $state.selectedItemID) { item in
            SidebarItemRow(item: item)
                .onTapGesture { openDocument(item) }
        }
        .listStyle(.sidebar)
    }

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No Recent Files")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Open a .md file to see it here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func loadRecentFiles() {
        let urls = NSDocumentController.shared.recentDocumentURLs
        let currentURL = (NSDocumentController.shared.currentDocument as? MarkdownDocument)?.fileURL
        state.items = urls.compactMap { url in
            guard url.pathExtension == "md" else { return nil }
            let accessed = (try? url.resourceValues(forKeys: [.contentAccessDateKey]))?.contentAccessDate ?? Date.distantPast
            return SidebarItem(
                id: UUID(),
                displayName: url.deletingPathExtension().lastPathComponent,
                url: url,
                lastOpened: accessed,
                isCurrentDocument: url == currentURL
            )
        }.sorted { $0.lastOpened > $1.lastOpened }
    }

    private func openDocument(_ item: SidebarItem) {
        NSDocumentController.shared.openDocument(
            withContentsOf: item.url, display: true
        ) { _, _, _ in }
    }
}
```

### SidebarItemRow

```swift
struct SidebarItemRow: View {
    let item: SidebarItem

    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(item.isCurrentDocument ? .accent : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(.body)
                    .fontWeight(item.isCurrentDocument ? .semibold : .regular)
                Text(item.lastOpened.relativeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.isCurrentDocument {
                Circle()
                    .fill(.accent)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 2)
    }
}
```

---

## Export Menu & Toolbar Integration

### Menu Commands

```swift
// In ShoechooApp or EditorView .commands modifier
CommandGroup(after: .saveItem) {
    Divider()
    Button("Export as HTML...") {
        Task { await viewModel.exportHTML() }
    }
    .keyboardShortcut("e", modifiers: [.command, .shift])

    Button("Export as PDF...") {
        Task { await viewModel.exportPDF() }
    }
    .keyboardShortcut("p", modifiers: [.command, .shift])
}
```

### Toolbar Buttons

```swift
@ToolbarContentBuilder
var editorToolbarContent: some ToolbarContent {
    // Leading: Sidebar toggle
    ToolbarItem(placement: .navigation) {
        Button {
            withAnimation {
                sidebarState.isVisible.toggle()
            }
        } label: {
            Image(systemName: "sidebar.leading")
        }
        .help("Toggle Sidebar (Cmd+Shift+L)")
        .keyboardShortcut("l", modifiers: [.command, .shift])
    }

    // Trailing: Export actions
    ToolbarItemGroup(placement: .primaryAction) {
        Menu {
            Button("Export as HTML...") {
                Task { await viewModel.exportHTML() }
            }
            Button("Export as PDF...") {
                Task { await viewModel.exportPDF() }
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .help("Export Document")
    }
}
```

---

## Export Flow — User Interaction

### Flow 1: Export to HTML (Cmd+Shift+E)

```
1. User presses Cmd+Shift+E (or File > Export as HTML...)
2. EditorViewModel.exportHTML() called
3. ExportService.generateHTML() runs on background actor
4. NSSavePanel presented:
   - Suggested name: "MyDocument.html"
   - File type: .html
   - Directory: same as source .md file
5. User selects destination, clicks Save
6. HTML data written to selected URL
7. Panel dismisses — user continues editing
```

### Flow 2: Export to PDF (Cmd+Shift+P)

```
1. User presses Cmd+Shift+P (or File > Export as PDF...)
2. EditorViewModel.exportPDF() called
3. ExportService.generateHTML() runs on background actor
4. ExportService.generatePDF() runs on MainActor (WKWebView)
   - Offscreen WKWebView loads HTML
   - Wait for page load completion
   - WKWebView.createPDF() captures PDF data
   - WKWebView deallocated
5. NSSavePanel presented:
   - Suggested name: "MyDocument.pdf"
   - File type: .pdf
6. User selects destination, clicks Save
7. PDF data written to selected URL
```

### Flow 3: Toggle Sidebar (Cmd+Shift+L)

```
1. User presses Cmd+Shift+L or clicks sidebar toolbar button
2. sidebarState.isVisible toggled
3. NavigationSplitView sidebar column animates in/out
4. Visibility state persisted to UserDefaults
5. On next app launch, sidebar restores to last visibility state
```

### Flow 4: Open File from Sidebar

```
1. User clicks a file entry in SidebarView
2. sidebarState.selectedItemID updated
3. NSDocumentController.openDocument(withContentsOf:display:) called
4. macOS document system opens/focuses the document window
5. SidebarView refreshes: new document marked as current
```

---

## Dark Mode Adaptation

### EditorView

```swift
struct EditorView: View {
    // ...

    /// Resolved color scheme from EditorSettings.appearanceOverride
    private var resolvedColorScheme: ColorScheme? {
        switch settings.appearanceOverride {
        case .system: return nil            // Follow system
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    var body: some View {
        NavigationSplitView { /* ... */ } detail: { /* ... */ }
            .preferredColorScheme(resolvedColorScheme)
    }
}
```

### ShoechooApp — NSApp.appearance Binding

```swift
@main
struct ShoechooApp: App {
    let settings = EditorSettings.shared

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            EditorView(viewModel: file.document.viewModel)
        }
        .commands { /* ... */ }
        .onChange(of: settings.appearanceOverride) { _, newValue in
            switch newValue {
            case .system:
                NSApp.appearance = nil
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
        }

        Settings {
            PreferencesView()
        }
    }
}
```

### WYSIWYGTextView — Appearance Change Handling

```swift
// In WYSIWYGTextView.updateNSView
func updateNSView(_ nsView: ShoechooTextView, context: Context) {
    // Detect appearance change
    let currentAppearance = nsView.effectiveAppearance.name
    if currentAppearance != context.coordinator.lastAppearance {
        context.coordinator.lastAppearance = currentAppearance
        // Invalidate all render caches — colors have changed
        viewModel.invalidateRenderCache()
        // Apply new editor background
        nsView.backgroundColor = resolvedEditorBackground(for: nsView.effectiveAppearance)
        // Re-render all blocks
        viewModel.requestFullRerender()
    }
    // ... rest of updateNSView
}
```

### Semantic Color Usage Across Components

| Component | Property | Color Source |
|-----------|----------|-------------|
| Editor background | `nsView.backgroundColor` | `NSColor.textBackgroundColor` |
| Editor text | Default text attribute | `NSColor.labelColor` |
| Editor cursor | `nsView.insertionPointColor` | `NSColor.controlAccentColor` |
| Sidebar background | SwiftUI `.background` | `.background` (system) |
| Sidebar item text | SwiftUI `Text` | `.primary` / `.secondary` |
| Sidebar selection | SwiftUI `List` selection | `.accent` with alpha |
| Toolbar background | Window toolbar | `.windowBackgroundColor` (auto) |
| Syntax delimiters | Attributed string attribute | `NSColor.secondaryLabelColor` |
| Link coloring | Attributed string attribute | `NSColor.linkColor` |
| Code fence markers | Attributed string attribute | `NSColor.systemOrange` |
| Blockquote markers | Attributed string attribute | `NSColor.systemGreen` |

### Preferences — Appearance Picker

```swift
struct PreferencesView: View {
    @Bindable var settings = EditorSettings.shared

    var body: some View {
        Form {
            // ... other settings ...

            Section("Appearance") {
                Picker("Theme", selection: $settings.appearanceOverride) {
                    Text("System").tag(AppearanceMode.system)
                    Text("Light").tag(AppearanceMode.light)
                    Text("Dark").tag(AppearanceMode.dark)
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
    }
}
```
