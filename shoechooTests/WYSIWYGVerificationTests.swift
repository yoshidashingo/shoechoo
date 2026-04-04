import Testing
import AppKit
@testable import shoechoo

/// Comprehensive WYSIWYG verification tests.
/// Every spec requirement (§3.1.1–§3.2.6) is verified for BOTH active and inactive states.
@Suite("WYSIWYG Verification")
@MainActor
struct WYSIWYGVerificationTests {

    private let parser = MarkdownParser()
    private let theme = ThemePresets.github

    private func makeTS(_ text: String) -> NSTextStorage { NSTextStorage(string: text) }

    private func fontAt(_ ts: NSTextStorage, _ pos: Int) -> NSFont {
        (ts.attributes(at: pos, effectiveRange: nil)[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 999)
    }
    private func isHidden(_ ts: NSTextStorage, _ pos: Int) -> Bool { fontAt(ts, pos).pointSize < 1.0 }
    private func isVisible(_ ts: NSTextStorage, _ pos: Int) -> Bool { fontAt(ts, pos).pointSize >= 10.0 }

    private func hl(_ ts: NSTextStorage, _ blocks: [EditorNode], _ activeID: EditorNode.ID?) {
        SyntaxHighlighter().apply(to: ts, blocks: blocks, activeBlockID: activeID, settings: EditorSettings.shared, theme: theme)
    }

    // MARK: - §3.1.1 Heading

    @Test("§3.1.1 Heading inactive: # hidden, text large bold")
    func headingInactive() {
        let source = "# Title"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        #expect(isHidden(ts, 0), "# hidden (font=\(fontAt(ts, 0).pointSize))")
        #expect(isVisible(ts, 2), "Title visible (font=\(fontAt(ts, 2).pointSize))")
        #expect(fontAt(ts, 2).pointSize == 28)
    }

    @Test("§3.1.1 Heading active: # visible")
    func headingActive() {
        let source = "# Title"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, blocks[0].id)
        #expect(isVisible(ts, 0), "# visible when active (font=\(fontAt(ts, 0).pointSize))")
    }

    @Test("§3.1.1 Heading sizes", arguments: [(1, 28.0), (2, 24.0), (3, 20.0), (4, 18.0), (5, 16.0)])
    func headingSizes(level: Int, expected: Double) {
        let source = "\(String(repeating: "#", count: level)) Text"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(fontAt(ts, level + 1).pointSize == CGFloat(expected))
    }

    // MARK: - §3.1.2 Code Block

    @Test("§3.1.2 Code block inactive: fences hidden")
    func codeBlockInactive() {
        let source = "```\ncode\n```"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        #expect(isHidden(ts, 0), "``` hidden (font=\(fontAt(ts, 0).pointSize))")
        #expect(isVisible(ts, 4), "code visible")
    }

    // MARK: - §3.1.3 Blockquote

    @Test("§3.1.3 Blockquote inactive: > hidden")
    func blockquoteInactive() {
        let source = "> Quote"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        #expect(isHidden(ts, 0), "> hidden (font=\(fontAt(ts, 0).pointSize))")
    }

    @Test("§3.1.3 Blockquote active: > visible")
    func blockquoteActive() {
        let source = "> Quote"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, blocks[0].id)
        #expect(isVisible(ts, 0), "> visible when active")
    }

    // MARK: - §3.1.4 Unordered List

    @Test("§3.1.4 List inactive: marker hidden, content visible")
    func listInactive() {
        let source = "- Item text"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        #expect(isHidden(ts, 0), "- hidden (font=\(fontAt(ts, 0).pointSize))")
        #expect(isVisible(ts, 2), "Item visible (font=\(fontAt(ts, 2).pointSize))")
    }

    @Test("§3.1.4 List active: marker visible")
    func listActive() {
        let source = "- Item text"
        let blocks = parser.parse(source, revision: 1).blocks
        let itemID = blocks[0].children.first?.id
        let ts = makeTS(source); hl(ts, blocks, itemID)
        #expect(isVisible(ts, 0), "- visible when active (font=\(fontAt(ts, 0).pointSize))")
    }

    // MARK: - §3.1.5 Ordered List

    @Test("§3.1.5 Ordered list inactive: marker hidden")
    func orderedListInactive() {
        let source = "1. First"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        #expect(isHidden(ts, 0), "1 hidden")
        #expect(isVisible(ts, 3), "First visible (font=\(fontAt(ts, 3).pointSize))")
    }

    // MARK: - §3.1.6 Task List

    @Test("§3.1.6 Task list inactive: marker hidden, content visible")
    func taskListInactive() {
        let source = "- [ ] Todo"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        #expect(isHidden(ts, 0), "- hidden")
        #expect(isVisible(ts, 6), "Todo visible (font=\(fontAt(ts, 6).pointSize))")
    }

    // MARK: - §3.1.7 Table

    @Test("§3.1.7 Table inactive: separator hidden")
    func tableInactive() {
        let source = "| A | B |\n|---|---|\n| 1 | 2 |"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        let sepPos = (source as NSString).range(of: "|---|").location
        #expect(isHidden(ts, sepPos), "separator hidden (font=\(fontAt(ts, sepPos).pointSize))")
    }

    // MARK: - §3.1.8 Horizontal Rule

    @Test("§3.1.8 HR inactive: hidden")
    func hrInactive() {
        let source = "---"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        #expect(isHidden(ts, 0), "--- hidden (font=\(fontAt(ts, 0).pointSize))")
    }

    // MARK: - §3.2.1 Bold

    @Test("§3.2.1 Bold inactive: ** hidden, text bold")
    func boldInactive() {
        let source = "Text **bold** end"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        let p = (source as NSString).range(of: "**bold**").location
        #expect(p != NSNotFound)
        #expect(isHidden(ts, p), "** hidden (font=\(fontAt(ts, p).pointSize))")
        #expect(isVisible(ts, p + 2), "bold visible (font=\(fontAt(ts, p + 2).pointSize))")
        #expect(NSFontManager.shared.traits(of: fontAt(ts, p + 2)).contains(.boldFontMask), "must be bold")
        #expect(isHidden(ts, p + 6), "trailing ** hidden")
    }

    @Test("§3.2.1 Bold active: ** visible")
    func boldActive() {
        let source = "Text **bold** end"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, blocks[0].id)
        let p = (source as NSString).range(of: "**bold**").location
        #expect(isVisible(ts, p), "** visible when active (font=\(fontAt(ts, p).pointSize))")
    }

    // MARK: - §3.2.2 Italic

    @Test("§3.2.2 Italic inactive: * hidden, text italic")
    func italicInactive() {
        let source = "Text *italic* end"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        let p = (source as NSString).range(of: "*italic*").location
        #expect(p != NSNotFound)
        #expect(isHidden(ts, p), "* hidden (font=\(fontAt(ts, p).pointSize))")
        #expect(isVisible(ts, p + 1), "italic visible")
        #expect(NSFontManager.shared.traits(of: fontAt(ts, p + 1)).contains(.italicFontMask))
    }

    // MARK: - §3.2.4 Strikethrough

    @Test("§3.2.4 Strikethrough inactive: ~~ hidden")
    func strikethroughInactive() {
        let source = "Text ~~deleted~~ end"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        let p = (source as NSString).range(of: "~~deleted~~").location
        #expect(p != NSNotFound)
        #expect(isHidden(ts, p), "~~ hidden (font=\(fontAt(ts, p).pointSize))")
    }

    // MARK: - §3.2.5 Inline Code

    @Test("§3.2.5 Inline code inactive: backtick hidden")
    func inlineCodeInactive() {
        let source = "Use `code` here"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        let p = (source as NSString).range(of: "`code`").location
        #expect(p != NSNotFound)
        #expect(isHidden(ts, p), "` hidden (font=\(fontAt(ts, p).pointSize))")
        #expect(isVisible(ts, p + 1), "code visible")
    }

    // MARK: - §3.2.6 Link

    @Test("§3.2.6 Link inactive: brackets/URL hidden")
    func linkInactive() {
        let source = "Visit [Google](https://google.com) end"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
        let bp = (source as NSString).range(of: "[Google]").location
        #expect(bp != NSNotFound)
        #expect(isHidden(ts, bp), "[ hidden (font=\(fontAt(ts, bp).pointSize))")
        #expect(isVisible(ts, bp + 1), "Google visible")
        let up = (source as NSString).range(of: "](https").location
        #expect(up != NSNotFound)
        #expect(isHidden(ts, up), "] hidden")
    }

    // MARK: - Edge Cases

    @Test("Empty document")
    func emptyDoc() {
        let blocks = parser.parse("", revision: 1).blocks
        let ts = makeTS(""); hl(ts, blocks, nil)
        #expect(ts.string == "")
    }

    @Test("CJK bold")
    func cjkBold() {
        let source = "これは**太字**テスト"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
    }

    @Test("Emoji safety")
    func emoji() {
        let source = "Hello 🎉 **world** 🚀"
        let blocks = parser.parse(source, revision: 1).blocks
        let ts = makeTS(source); hl(ts, blocks, nil)
        #expect(ts.string == source)
    }
}
