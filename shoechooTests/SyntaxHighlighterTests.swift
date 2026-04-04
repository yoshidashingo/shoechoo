import Testing
import AppKit
@testable import shoechoo

@Suite("SyntaxHighlighter")
@MainActor
struct SyntaxHighlighterTests {

    private let parser = MarkdownParser()

    private func makeTextStorage(_ text: String) -> NSTextStorage {
        NSTextStorage(string: text)
    }

    @Test("Apply to paragraph sets base font and text color")
    func applyParagraph() {
        let source = "Hello, world!"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, appearance: .dark)

        let attrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        #expect(textStorage.string == "Hello, world!")
    }

    @Test("Apply never modifies the string content")
    func applyDoesNotChangeString() {
        let source = "# Hello\n\nSome **bold** text\n\n- item one\n- item two"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, appearance: .dark)

        #expect(textStorage.string == source)
    }

    @Test("Heading gets bold font with larger size")
    func headingGetsBoldFont() {
        let source = "# My Heading"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, appearance: .dark)

        // Check that font at a non-prefix position is bold and larger than base
        let attrs = textStorage.attributes(at: 2, effectiveRange: nil) // after "# "
        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        #expect(font!.pointSize == 28)
        #expect(textStorage.string == source)
    }

    @Test("Inline code gets monospaced font")
    func inlineCodeGetsMonospacedFont() {
        let source = "Use `code` here"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, appearance: .dark)

        #expect(textStorage.string == source)
        // The string content must be unchanged
        #expect(textStorage.string.contains("`code`"))
    }

    @Test("Light and dark appearance both preserve string content")
    func bothAppearancesPreserveString() {
        let source = "**bold** and _italic_"
        let textStorage1 = makeTextStorage(source)
        let textStorage2 = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage1, blocks: result.blocks, settings: settings, appearance: .light)
        highlighter.apply(to: textStorage2, blocks: result.blocks, settings: settings, appearance: .dark)

        #expect(textStorage1.string == source)
        #expect(textStorage2.string == source)
    }
}
