import Foundation

/// Thread-safe snapshot text storage for MarkdownDocument (FR-10).
/// Replaces direct NSLock + nonisolated(unsafe) _snapshotText pattern.
/// Internal nonisolated(unsafe) is NSLock-protected private implementation (AC #9 exception).
final class SnapshotStore: Sendable {
    private let lock = NSLock()
    private nonisolated(unsafe) var _text: String = ""

    func read() -> String {
        lock.withLock { _text }
    }

    func write(_ text: String) {
        lock.withLock { _text = text }
    }
}
