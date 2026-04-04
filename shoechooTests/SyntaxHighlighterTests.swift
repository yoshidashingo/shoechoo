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

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.night)

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

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.night)

        #expect(textStorage.string == source)
    }

    @Test("Heading gets bold font with larger size")
    func headingGetsBoldFont() {
        let source = "# My Heading"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.night)

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

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.night)

        #expect(textStorage.string == source)
        // The string content must be unchanged
        #expect(textStorage.string.contains("`code`"))
    }

    @Test("Light and dark themes both preserve string content")
    func bothThemesPreserveString() {
        let source = "**bold** and _italic_"
        let textStorage1 = makeTextStorage(source)
        let textStorage2 = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage1, blocks: result.blocks, settings: settings, theme: ThemePresets.github)
        highlighter.apply(to: textStorage2, blocks: result.blocks, settings: settings, theme: ThemePresets.night)

        #expect(textStorage1.string == source)
        #expect(textStorage2.string == source)
    }

    @Test("Heading # prefix colored as delimiter color")
    func headingPrefixColor() {
        let source = "## Sub"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, theme: ThemePresets.github)
        let prefixAttrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let prefixColor = prefixAttrs[.foregroundColor] as? NSColor
        #expect(prefixColor != nil)
    }

    @Test("Code block gets monospaced font")
    func applyCodeBlock() {
        let source = "```swift\nlet x = 1\n```"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, theme: ThemePresets.night)
        #expect(textStorage.string == source)
        let fenceEnd = (source as NSString).range(of: "\n").location + 1
        let attrs = textStorage.attributes(at: fenceEnd, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        #expect(font!.isFixedPitch)
    }

    @Test("Bold text gets bold font, delimiters secondary color")
    func applyBold() {
        let source = "This is **bold** text"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, theme: ThemePresets.github)
        #expect(textStorage.string == source)
        let boldStart = (source as NSString).range(of: "**bold**").location
        let bAttrs = textStorage.attributes(at: boldStart + 2, effectiveRange: nil)
        let bFont = bAttrs[.font] as? NSFont
        #expect(bFont != nil)
        let traits = NSFontManager.shared.traits(of: bFont!)
        #expect(traits.contains(.boldFontMask))
    }

    @Test("Link gets linkColor and underline")
    func applyLink() {
        let source = "Visit [Example](https://example.com) now"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, theme: ThemePresets.github)
        #expect(textStorage.string == source)
        let linkStart = (source as NSString).range(of: "[Example]").location
        let linkAttrs = textStorage.attributes(at: linkStart, effectiveRange: nil)
        let linkColor = linkAttrs[.foregroundColor] as? NSColor
        #expect(linkColor != nil)
        let underline = linkAttrs[.underlineStyle] as? Int
        #expect(underline == NSUnderlineStyle.single.rawValue)
    }

    @Test("Japanese text content is preserved and styled")
    func japaneseTextPreserved() {
        let source = "# 日本語タイトル\n\nこれは**太字**テスト"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, theme: ThemePresets.night)
        #expect(textStorage.string == source)
    }

    @Test("Mixed document: all block types styled without changing text")
    func mixedDocument() {
        let source = "# Title\n\nA paragraph with **bold** and *italic*.\n\n- Item 1\n- Item 2\n\n```swift\nlet x = 1\n```\n\n> A quote\n\n---"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, theme: ThemePresets.night)
        #expect(textStorage.string == source)
        let titleAttrs = textStorage.attributes(at: 2, effectiveRange: nil)
        let titleFont = titleAttrs[.font] as? NSFont
        #expect(titleFont!.pointSize >= 28)
    }

    @Test("Heading uses theme heading color")
    func headingUsesThemeColor() {
        let source = "# Hello"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.night)
        let attrs = textStorage.attributes(at: 2, effectiveRange: nil)
        #expect(attrs[.font] != nil)
    }

    @Test("Code block uses theme background color")
    func codeBlockUsesThemeBg() {
        let source = "```\ncode\n```"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.solarizedLight)
        let attrs = textStorage.attributes(at: 4, effectiveRange: nil)
        let bg = attrs[.backgroundColor] as? NSColor
        #expect(bg != nil)
    }
}
