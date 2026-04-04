import SwiftUI

struct EditorView: View {
    var document: MarkdownDocument
    var fileURL: URL?

    @Environment(EditorSettings.self) private var settings
    @Environment(ThemeRegistry.self) private var themeRegistry
    @State private var isExporting = false
    @State private var showSidebar = true

    var body: some View {
        if let vm = document.viewModel {
            editorBody(vm: vm)
        } else {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func editorBody(vm: EditorViewModel) -> some View {
        HSplitView {
            if showSidebar {
                SidebarContainerView(
                    viewModel: vm,
                    documentURL: fileURL
                )
                .frame(minWidth: 150, idealWidth: 220, maxWidth: 300)
            }

            VStack(spacing: 0) {
                WYSIWYGTextView(viewModel: vm, settings: settings, themeRegistry: themeRegistry, document: document)
                    .focusedSceneValue(\.editorViewModel, vm)
                    .frame(minWidth: 400, minHeight: 300)

                Divider()

                HStack(spacing: 4) {
                    Text("\(vm.wordCount) words")
                    Text("·")
                    Text("\(vm.characterCount) characters")
                    Text("·")
                    Text("\(vm.lineCount) lines")
                    Spacer()
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.bar)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { withAnimation { showSidebar.toggle() } }) {
                    Image(systemName: "sidebar.left")
                        .symbolVariant(showSidebar ? .fill : .none)
                }
                .help("Toggle Sidebar (⌃⌘S)")

                Divider()

                Button(action: { vm.toggleBold() }) {
                    Image(systemName: "bold")
                }
                .help("Bold (⌘B)")

                Button(action: { vm.toggleItalic() }) {
                    Image(systemName: "italic")
                }
                .help("Italic (⌘I)")

                Button(action: { vm.toggleInlineCode() }) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .help("Inline Code (⇧⌘K)")

                Divider()

                Button(action: { vm.toggleFocusMode() }) {
                    Image(systemName: vm.isFocusModeEnabled ? "eye.fill" : "eye")
                }
                .help("Focus Mode (⇧⌘F)")

                Button(action: { vm.toggleTypewriterScroll() }) {
                    Image(systemName: vm.isTypewriterScrollEnabled ? "arrow.up.and.down.text.horizontal" : "arrow.up.and.down")
                }
                .help("Typewriter Scroll")

                Divider()

                Button(action: { isExporting = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Export HTML (⇧⌘E)")
            }
        }
        .task(id: isExporting) {
            guard isExporting else { return }
            defer { isExporting = false }
            await exportHTML()
        }
    }

    private func exportHTML() async {
        guard let vm = document.viewModel else { return }
        let html = await vm.exportHTML()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = "Export.html"
        let response = await panel.beginSheetModal(for: NSApp.keyWindow ?? NSWindow())
        guard response == .OK, let url = panel.url else { return }
        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
}
