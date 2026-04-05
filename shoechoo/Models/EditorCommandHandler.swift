import Foundation

/// Type-safe command handler protocol replacing NotificationCenter-based command dispatch.
/// Coordinator implements this protocol; EditorViewModel holds a weak reference.
/// This ensures commands target only the specific document window (FR-01, FR-02).
///
/// Not @MainActor at protocol level — required because MarkdownDocument (@unchecked Sendable)
/// references EditorViewModel.commandHandler. Individual methods are @MainActor.
/// Implementations (Coordinator) are @MainActor and guarantee main-thread execution.
protocol EditorCommandHandler: AnyObject {
    /// Toggle inline formatting (bold, italic, inline code) around the current selection.
    @MainActor func toggleFormatting(prefix: String, suffix: String)

    /// Insert formatted text at the current cursor position and move cursor.
    @MainActor func insertFormattedText(_ text: String, cursorOffset: Int)

    /// Set a line-level prefix (e.g., heading markers) on the current line.
    @MainActor func setLinePrefix(_ prefix: String)

    /// Insert image markdown syntax at the specified position.
    @MainActor func insertImageMarkdown(_ markdown: String, at position: Int)

    /// Scroll to a UTF-16 offset position in the document.
    @MainActor func scrollToPosition(_ position: Int)
}
