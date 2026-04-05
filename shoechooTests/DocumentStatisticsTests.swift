import Testing
@testable import shoechoo

@Suite("DocumentStatistics")
struct DocumentStatisticsTests {

    @Test("Empty text produces zero counts")
    func emptyText() {
        let stats = DocumentStatistics(from: "")
        #expect(stats.wordCount == 0)
        #expect(stats.characterCount == 0)
        #expect(stats.lineCount == 0)
    }

    @Test("Single line counts correctly")
    func singleLine() {
        let stats = DocumentStatistics(from: "Hello world")
        #expect(stats.wordCount == 2)
        #expect(stats.characterCount == 11)
        #expect(stats.lineCount == 1)
    }

    @Test("Multiple lines counts correctly")
    func multipleLines() {
        let stats = DocumentStatistics(from: "Line one\nLine two\nLine three")
        #expect(stats.wordCount == 6)
        #expect(stats.lineCount == 3)
    }

    @Test("Japanese text word count")
    func japaneseText() {
        let stats = DocumentStatistics(from: "こんにちは 世界")
        #expect(stats.wordCount == 2)
        #expect(stats.characterCount == 8)
    }

    @Test("Whitespace-only text has zero words")
    func whitespaceOnly() {
        let stats = DocumentStatistics(from: "   \n  \n  ")
        #expect(stats.wordCount == 0)
        #expect(stats.lineCount == 3)
    }

    @Test("Trailing newline counts as extra line")
    func trailingNewline() {
        let stats = DocumentStatistics(from: "line1\nline2\n")
        #expect(stats.lineCount == 3)
        #expect(stats.wordCount == 2)
    }

    @Test("CJK text without spaces is one word")
    func cjkNoSpaces() {
        let stats = DocumentStatistics(from: "こんにちは世界")
        #expect(stats.wordCount == 1)
    }
}

@Suite("SnapshotStore")
struct SnapshotStoreTests {

    @Test("Read returns empty string initially")
    func initialEmpty() {
        let store = SnapshotStore()
        #expect(store.read() == "")
    }

    @Test("Write then read returns written text")
    func writeRead() {
        let store = SnapshotStore()
        store.write("Hello")
        #expect(store.read() == "Hello")
    }

    @Test("Multiple writes keep last value")
    func multipleWrites() {
        let store = SnapshotStore()
        store.write("First")
        store.write("Second")
        #expect(store.read() == "Second")
    }
}
