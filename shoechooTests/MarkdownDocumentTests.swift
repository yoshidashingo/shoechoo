import Testing
import UniformTypeIdentifiers
import Foundation
@testable import shoechoo

@Suite("MarkdownDocument")
@MainActor
struct MarkdownDocumentTests {

    @Test("Default init creates viewModel with empty sourceText")
    func defaultInit() {
        let doc = MarkdownDocument()
        #expect(doc.viewModel.sourceText == "")
    }

    @Test("viewModel is accessible after init")
    func viewModelAccessible() {
        let doc = MarkdownDocument()
        #expect(doc.viewModel.headings.isEmpty)
        #expect(doc.viewModel.statistics.wordCount == 0)
    }

    // MARK: - Snapshot via SnapshotStore

    @Test("snapshot returns empty string for new document")
    func snapshotNewDocument() throws {
        let doc = MarkdownDocument()
        let snap = try doc.snapshot(contentType: .markdown)
        #expect(snap == "")
    }

    @Test("updateSnapshotText makes snapshot return that text")
    func updateSnapshotText() throws {
        let doc = MarkdownDocument()
        doc.updateSnapshotText("Updated content")
        let snap = try doc.snapshot(contentType: .markdown)
        #expect(snap == "Updated content")
    }

    @Test("Multiple updateSnapshotText calls keep last value")
    func multipleSnapshotUpdates() throws {
        let doc = MarkdownDocument()
        doc.updateSnapshotText("First")
        doc.updateSnapshotText("Second")
        doc.updateSnapshotText("Third")
        let snap = try doc.snapshot(contentType: .markdown)
        #expect(snap == "Third")
    }

    @Test("updateSnapshotText with empty string resets snapshot")
    func snapshotEmpty() throws {
        let doc = MarkdownDocument()
        doc.updateSnapshotText("Some text")
        doc.updateSnapshotText("")
        let snap = try doc.snapshot(contentType: .markdown)
        #expect(snap == "")
    }

    @Test("updateSnapshotText handles Japanese text")
    func snapshotJapanese() throws {
        let doc = MarkdownDocument()
        doc.updateSnapshotText("こんにちは世界")
        let snap = try doc.snapshot(contentType: .markdown)
        #expect(snap == "こんにちは世界")
    }

    // MARK: - Snapshot round-trip (simulates fileWrapper encoding)

    @Test("Snapshot text round-trips through UTF-8 encoding")
    func snapshotRoundTripUTF8() throws {
        let doc = MarkdownDocument()
        let text = "Hello, Markdown!"
        doc.updateSnapshotText(text)
        let snap = try doc.snapshot(contentType: .markdown)
        let data = snap.data(using: .utf8)
        #expect(data != nil)
        let decoded = String(data: data!, encoding: .utf8)
        #expect(decoded == text)
    }

    @Test("Japanese snapshot round-trips through UTF-8 encoding")
    func snapshotRoundTripJapanese() throws {
        let doc = MarkdownDocument()
        let text = "こんにちは世界"
        doc.updateSnapshotText(text)
        let snap = try doc.snapshot(contentType: .markdown)
        let data = snap.data(using: .utf8)
        #expect(data != nil)
        #expect(String(data: data!, encoding: .utf8) == text)
    }

    @Test("Empty snapshot produces empty data")
    func snapshotRoundTripEmpty() throws {
        let doc = MarkdownDocument()
        let snap = try doc.snapshot(contentType: .markdown)
        let data = snap.data(using: .utf8)
        #expect(data != nil)
        #expect(data!.isEmpty)
    }

    // MARK: - File URL

    @Test("fileURL is nil initially")
    func fileURLInitiallyNil() {
        let doc = MarkdownDocument()
        #expect(doc.fileURL == nil)
    }

    @Test("setFileURL updates fileURL")
    func setFileURL() {
        let doc = MarkdownDocument()
        let url = URL(fileURLWithPath: "/tmp/test.md")
        doc.setFileURL(url)
        #expect(doc.fileURL == url)
    }

    @Test("setFileURL to nil clears fileURL")
    func setFileURLNil() {
        let doc = MarkdownDocument()
        doc.setFileURL(URL(fileURLWithPath: "/tmp/test.md"))
        doc.setFileURL(nil)
        #expect(doc.fileURL == nil)
    }

    @Test("assetsDirectoryURL returns nil when fileURL is nil")
    func assetsDirectoryURLNil() {
        let doc = MarkdownDocument()
        #expect(doc.assetsDirectoryURL() == nil)
    }

    @Test("assetsDirectoryURL returns correct assets path")
    func assetsDirectoryURL() {
        let doc = MarkdownDocument()
        let url = URL(fileURLWithPath: "/tmp/notes.md")
        doc.setFileURL(url)
        let assetsURL = doc.assetsDirectoryURL()
        #expect(assetsURL != nil)
        #expect(assetsURL!.lastPathComponent == "notes.assets")
    }

    // MARK: - Content types

    @Test("readableContentTypes includes markdown")
    func readableContentTypes() {
        let types = MarkdownDocument.readableContentTypes
        #expect(types.contains(.markdown))
    }

    @Test("writableContentTypes includes markdown")
    func writableContentTypes() {
        let types = MarkdownDocument.writableContentTypes
        #expect(types.contains(.markdown))
    }
}
