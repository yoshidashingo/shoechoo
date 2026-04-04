import SwiftUI

struct EditorView: View {
    var document: MarkdownDocument

    @Environment(EditorSettings.self) private var settings
    @State private var isExporting = false
    @State private var showOutline = true

    var body: some View {
        HSplitView {
            if showOutline {
                OutlineView(viewModel: document.viewModel)
                    .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)
            }

            VStack(spacing: 0) {
                WYSIWYGTextView(viewModel: document.viewModel, settings: settings)
                    .focusedSceneValue(\.editorViewModel, document.viewModel)
                    .frame(minWidth: 400, minHeight: 300)

                Divider()

                HStack(spacing: 4) {
                    Text("\(document.viewModel.wordCount) words")
                    Text("·")
                    Text("\(document.viewModel.characterCount) characters")
                    Text("·")
                    Text("\(document.viewModel.lineCount) lines")
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
                Button(action: { withAnimation { showOutline.toggle() } }) {
                    Image(systemName: showOutline ? "sidebar.left" : "sidebar.left")
                        .symbolVariant(showOutline ? .fill : .none)
                }
                .help("Toggle Outline (⌃⌘S)")

                Divider()

                Button(action: { document.viewModel.toggleBold() }) {
                    Image(systemName: "bold")
                }
                .help("Bold (⌘B)")

                Button(action: { document.viewModel.toggleItalic() }) {
                    Image(systemName: "italic")
                }
                .help("Italic (⌘I)")

                Button(action: { document.viewModel.toggleInlineCode() }) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                }
                .help("Inline Code (⇧⌘K)")

                Divider()

                Button(action: { document.viewModel.toggleFocusMode() }) {
                    Image(systemName: document.viewModel.isFocusModeEnabled ? "eye.fill" : "eye")
                }
                .help("Focus Mode (⇧⌘F)")

                Button(action: { document.viewModel.toggleTypewriterScroll() }) {
                    Image(systemName: document.viewModel.isTypewriterScrollEnabled ? "arrow.up.and.down.text.horizontal" : "arrow.up.and.down")
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
        let html = await document.viewModel.exportHTML()
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
