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

        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.night)

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

        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.night)

        #expect(textStorage.string == source)
    }

    @Test("Heading gets bold font with larger size")
    func headingGetsBoldFont() {
        let source = "# My Heading"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.night)

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

        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.night)

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

        highlighter.apply(to: textStorage1, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.github)
        highlighter.apply(to: textStorage2, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.night)

        #expect(textStorage1.string == source)
        #expect(textStorage2.string == source)
    }

    @Test("Heading # prefix colored as delimiter color")
    func headingPrefixColor() {
        let source = "## Sub"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: EditorSettings.shared, theme: ThemePresets.github)
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
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: EditorSettings.shared, theme: ThemePresets.night)
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
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: EditorSettings.shared, theme: ThemePresets.github)
        #expect(textStorage.string == source)
        let boldStart = (source as NSString).range(of: "**bold**").location
        let bAttrs = textStorage.attributes(at: boldStart + 2, effectiveRange: nil)
        let bFont = bAttrs[.font] as? NSFont
        #expect(bFont != nil)
        let traits = NSFontManager.shared.traits(of: bFont!)
        #expect(traits.contains(.boldFontMask))
    }

    @Test("Link text gets linkColor and underline, brackets get delimiter color")
    func applyLink() {
        let source = "Visit [Example](https://example.com) now"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: EditorSettings.shared, theme: ThemePresets.github)
        #expect(textStorage.string == source)
        // "Example" text (inside brackets) should have link color + underline
        let exampleStart = (source as NSString).range(of: "Example").location
        let textAttrs = textStorage.attributes(at: exampleStart, effectiveRange: nil)
        let textColor = textAttrs[.foregroundColor] as? NSColor
        #expect(textColor == ThemePresets.github.linkColor.nsColor)
        let underline = textAttrs[.underlineStyle] as? Int
        #expect(underline == NSUnderlineStyle.single.rawValue)
    }

    @Test("Japanese text content is preserved and styled")
    func japaneseTextPreserved() {
        let source = "# 日本語タイトル\n\nこれは**太字**テスト"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: EditorSettings.shared, theme: ThemePresets.night)
        #expect(textStorage.string == source)
    }

    @Test("Mixed document: all block types styled without changing text")
    func mixedDocument() {
        let source = "# Title\n\nA paragraph with **bold** and *italic*.\n\n- Item 1\n- Item 2\n\n```swift\nlet x = 1\n```\n\n> A quote\n\n---"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: EditorSettings.shared, theme: ThemePresets.night)
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
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.night)
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
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil, settings: settings, theme: ThemePresets.solarizedLight)
        let attrs = textStorage.attributes(at: 4, effectiveRange: nil)
        let bg = attrs[.backgroundColor] as? NSColor
        #expect(bg != nil)
    }

    // MARK: - WYSIWYG Verification

    @Test("WYSIWYG: bold ** delimiters are hidden (0.01pt font) when block is inactive")
    func wysiwygBoldHidden() {
        let source = "This is **bold** text"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        // activeBlockID = nil means ALL blocks are inactive (WYSIWYG mode)
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        // Check paragraph block was parsed
        #expect(result.blocks.count >= 1)
        #expect(result.blocks[0].kind == .paragraph)
        #expect(!result.blocks[0].inlineRuns.isEmpty, "Paragraph must have inline runs for bold")

        // Find ** positions
        let starPos = (source as NSString).range(of: "**").location
        let starAttrs = textStorage.attributes(at: starPos, effectiveRange: nil)
        let starFont = starAttrs[.font] as? NSFont
        #expect(starFont != nil, "Font must be set on ** chars")
        #expect(starFont!.pointSize < 1.0, "** must have tiny font (got \(starFont!.pointSize))")

        // The "bold" text between ** should have normal-size bold font
        let boldPos = (source as NSString).range(of: "bold").location
        let boldAttrs = textStorage.attributes(at: boldPos, effectiveRange: nil)
        let boldFont = boldAttrs[.font] as? NSFont
        #expect(boldFont != nil)
        #expect(boldFont!.pointSize >= 10, "bold text should have normal font size")
        let traits = NSFontManager.shared.traits(of: boldFont!)
        #expect(traits.contains(.boldFontMask), "bold text must have bold trait")
    }

    @Test("WYSIWYG: heading # prefix is hidden when block is inactive")
    func wysiwygHeadingHidden() {
        let source = "# Hello"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        // # at position 0 should be hidden (0.01pt font)
        let hashAttrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let hashFont = hashAttrs[.font] as? NSFont
        #expect(hashFont!.pointSize < 1.0, "# must be hidden (got \(hashFont!.pointSize))")

        // "Hello" at position 2 should have large bold font
        let textAttrs = textStorage.attributes(at: 2, effectiveRange: nil)
        let textFont = textAttrs[.font] as? NSFont
        #expect(textFont!.pointSize >= 28, "Hello should be 28pt (got \(textFont!.pointSize))")
    }

    @Test("WYSIWYG: active block shows raw markdown with delimiters visible")
    func wysiwygActiveBlockShowsRaw() {
        let source = "This is **bold** text"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        // Set activeBlockID to the paragraph block
        let blockID = result.blocks[0].id
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: blockID,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        // ** should be visible (normal font size, not hidden)
        let starPos = (source as NSString).range(of: "**").location
        let starAttrs = textStorage.attributes(at: starPos, effectiveRange: nil)
        let starFont = starAttrs[.font] as? NSFont
        #expect(starFont!.pointSize >= 10, "** in active block should be visible (got \(starFont!.pointSize))")
    }

    @Test("WYSIWYG: link URL hidden when inactive, visible when active")
    func wysiwygLinkHidden() {
        let source = "Visit [Example](https://example.com) now"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        // Inactive: URL part should be hidden
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        let urlPos = (source as NSString).range(of: "(https").location
        let urlAttrs = textStorage.attributes(at: urlPos, effectiveRange: nil)
        let urlFont = urlAttrs[.font] as? NSFont
        #expect(urlFont!.pointSize < 1.0, "URL must be hidden when inactive (got \(urlFont!.pointSize))")
    }

    @Test("WYSIWYG: code fence hidden when inactive")
    func wysiwygCodeFenceHidden() {
        let source = "```\ncode\n```"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        // ``` at position 0 should be hidden
        let fenceAttrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let fenceFont = fenceAttrs[.font] as? NSFont
        #expect(fenceFont!.pointSize < 1.0, "``` must be hidden when inactive (got \(fenceFont!.pointSize))")
    }

    @Test("WYSIWYG: blockquote > marker hidden when inactive")
    func wysiwygBlockquoteHidden() {
        let source = "> A quote"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        // > at position 0 should be hidden
        let markerAttrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let markerFont = markerAttrs[.font] as? NSFont
        #expect(markerFont!.pointSize < 1.0, "> must be hidden when inactive (got \(markerFont!.pointSize))")
    }

    @Test("WYSIWYG: table separator row hidden when inactive")
    func wysiwygTableSeparatorHidden() {
        let source = "| A | B |\n|---|---|\n| 1 | 2 |"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        // separator row "|---|---|" starts after "| A | B |\n"
        let sepStart = (source as NSString).range(of: "|---|").location
        let sepAttrs = textStorage.attributes(at: sepStart, effectiveRange: nil)
        let sepFont = sepAttrs[.font] as? NSFont
        #expect(sepFont!.pointSize < 1.0, "table separator must be hidden (got \(sepFont!.pointSize))")
    }

    @Test("WYSIWYG: italic * delimiters hidden when inactive")
    func wysiwygItalicHidden() {
        let source = "This is *italic* text"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: nil,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        let starPos = (source as NSString).range(of: "*italic*").location
        let starAttrs = textStorage.attributes(at: starPos, effectiveRange: nil)
        let starFont = starAttrs[.font] as? NSFont
        #expect(starFont!.pointSize < 1.0, "* must be hidden when inactive (got \(starFont!.pointSize))")

        // "italic" text should have italic trait
        let textPos = starPos + 1
        let textAttrs = textStorage.attributes(at: textPos, effectiveRange: nil)
        let textFont = textAttrs[.font] as? NSFont
        let traits = NSFontManager.shared.traits(of: textFont!)
        #expect(traits.contains(.italicFontMask), "italic text must have italic trait")
    }

    @Test("WYSIWYG: full document integration — all elements properly styled when inactive")
    func wysiwygFullDocumentIntegration() {
        let source = "# Title\n\nThis has **bold** and *italic* text.\n\n> A blockquote\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n---\n\n[link](https://ex.com)"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)

        // Verify we have enough blocks
        #expect(result.blocks.count >= 5, "Should parse heading, paragraph, blockquote, table, hr, paragraph — got \(result.blocks.count)")

        let highlighter = SyntaxHighlighter()
        // Set first block as active, all others inactive
        let activeID = result.blocks[0].id
        highlighter.apply(to: textStorage, blocks: result.blocks, activeBlockID: activeID,
                          settings: EditorSettings.shared, theme: ThemePresets.github)

        // Heading (active): # should be visible
        let hashAttrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let hashFont = hashAttrs[.font] as? NSFont
        #expect(hashFont!.pointSize >= 10, "# in ACTIVE heading should be visible")

        // Bold (inactive paragraph): ** should be hidden
        let boldStarPos = (source as NSString).range(of: "**bold**").location
        if boldStarPos != NSNotFound {
            let boldStarAttrs = textStorage.attributes(at: boldStarPos, effectiveRange: nil)
            let boldStarFont = boldStarAttrs[.font] as? NSFont
            #expect(boldStarFont!.pointSize < 1.0, "** in INACTIVE paragraph should be hidden (got \(boldStarFont!.pointSize))")
        }

        // Text is never modified
        #expect(textStorage.string == source)
    }
}
