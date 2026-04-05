import SwiftUI
import UniformTypeIdentifiers

@main
struct ShoechooApp: App {
    init() {
        // UI Tests: suppress the "Reopen documents?" dialog and Open Dialog
        if CommandLine.arguments.contains("--uitesting") {
            UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
            // Prevent state restoration from previous sessions
            UserDefaults.standard.set(true, forKey: "ApplePersistenceIgnoreState")
        }
    }

    @State private var settings = EditorSettings.shared
    @State private var themeRegistry = ThemeRegistry()

    var body: some Scene {
        DocumentGroup(newDocument: { MarkdownDocument() }) { file in
            EditorView(document: file.document, fileURL: file.fileURL)
                .environment(settings)
                .environment(themeRegistry)
        }
        .commands {
            CommandGroup(replacing: .textFormatting) {
                FormatCommands()
            }
            CommandGroup(after: .textFormatting) {
                HeadingCommands()
            }
            CommandGroup(after: .toolbar) {
                FocusCommands()
            }
            CommandGroup(after: .importExport) {
                ExportCommands()
            }
            CommandGroup(after: .sidebar) {
                SidebarCommands()
            }
        }

        Settings {
            PreferencesView()
                .environment(settings)
                .environment(themeRegistry)
        }
    }
}

struct FormatCommands: View {
    @FocusedValue(\.editorViewModel) private var viewModel

    var body: some View {
        Button("Bold") { viewModel?.toggleBold() }
            .keyboardShortcut("b", modifiers: .command)
        Button("Italic") { viewModel?.toggleItalic() }
            .keyboardShortcut("i", modifiers: .command)
        Button("Link") { viewModel?.insertLink() }
            .keyboardShortcut("k", modifiers: .command)
        Button("Inline Code") { viewModel?.toggleInlineCode() }
            .keyboardShortcut("k", modifiers: [.command, .shift])
    }
}

struct HeadingCommands: View {
    @FocusedValue(\.editorViewModel) private var viewModel

    var body: some View {
        ForEach(1...6, id: \.self) { level in
            Button("Heading \(level)") { viewModel?.setHeading(level: level) }
                .keyboardShortcut(KeyEquivalent(Character("\(level)")), modifiers: .command)
        }
    }
}

struct FocusCommands: View {
    @FocusedValue(\.editorViewModel) private var viewModel

    var body: some View {
        Button("Toggle Focus Mode") { viewModel?.toggleFocusMode() }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        Button("Toggle Typewriter Scroll") { viewModel?.toggleTypewriterScroll() }
            .keyboardShortcut("t", modifiers: [.command, .shift])
    }
}

struct ExportCommands: View {
    @FocusedValue(\.editorViewModel) private var viewModel

    var body: some View {
        Button("Export HTML...") {
            guard let viewModel else { return }
            Task {
                let html = await viewModel.exportHTML()
                let panel = NSSavePanel()
                panel.allowedContentTypes = [.html]
                panel.nameFieldStringValue = "Export.html"
                let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
                guard response == .OK, let url = panel.url else { return }
                try? html.write(to: url, atomically: true, encoding: .utf8)
            }
        }
        .keyboardShortcut("e", modifiers: [.command, .shift])

        Button("Export PDF...") {
            guard let viewModel else { return }
            Task {
                do {
                    let data = try await viewModel.exportPDF()
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.pdf]
                    panel.nameFieldStringValue = "Export.pdf"
                    let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
                    guard response == .OK, let url = panel.url else { return }
                    try data.write(to: url)
                } catch {
                    let alert = NSAlert(error: error)
                    alert.runModal()
                }
            }
        }
        .keyboardShortcut("e", modifiers: [.command, .shift, .option])
    }
}

struct SidebarCommands: View {
    var body: some View {
        Button("Toggle Sidebar") {
            NSApp.keyWindow?.firstResponder?.tryToPerform(
                #selector(NSSplitViewController.toggleSidebar(_:)), with: nil
            )
        }
        .keyboardShortcut("s", modifiers: [.command, .control])
    }
}

struct EditorViewModelKey: FocusedValueKey {
    typealias Value = EditorViewModel
}

extension FocusedValues {
    var editorViewModel: EditorViewModel? {
        get { self[EditorViewModelKey.self] }
        set { self[EditorViewModelKey.self] = newValue }
    }
}
