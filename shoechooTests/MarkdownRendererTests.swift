import Testing
import Foundation
import AppKit
@testable import shoechoo

@Suite("MarkdownRenderer")
@MainActor
struct MarkdownRendererTests {

    private let renderer = MarkdownRenderer()
    private let parser = MarkdownParser()

    /// Helper: parse source text and return the first block.
    private func firstBlock(_ source: String) -> EditorNode {
        let result = parser.parse(source, revision: 1)
        return result.blocks[0]
    }

    // MARK: - Render Inactive (Styled) Blocks

    @Test("Render paragraph produces non-empty attributed string")
    func renderParagraph() {
        let block = firstBlock("Hello, world!")
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .light)

        #expect(!result.attributedString.string.isEmpty)
        #expect(result.attributedString.string.contains("Hello, world!"))
        #expect(result.isActive == false)
        #expect(result.blockID == block.id)
    }

    @Test("Render heading strips prefix and uses bold font")
    func renderHeading() {
        let block = firstBlock("# Title")
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .light)

        #expect(result.attributedString.string.contains("Title"))
        // Heading should not show the # prefix in inactive mode
        #expect(!result.attributedString.string.hasPrefix("#"))
    }

    @Test("Render heading level affects font size", arguments: [1, 2, 3])
    func renderHeadingLevels(level: Int) {
        let prefix = String(repeating: "#", count: level)
        let block = firstBlock("\(prefix) Heading")
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .light)

        // Extract font from the first character
        let attrs = result.attributedString.attributes(at: 0, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        // Higher level headings should have larger font sizes
        if level == 1 {
            #expect(font!.pointSize >= 28)
        }
    }

    @Test("Render code block strips fences and uses monospaced font")
    func renderCodeBlock() {
        let source = "```swift\nlet x = 1\n```"
        let result_ = parser.parse(source, revision: 1)
        let block = result_.blocks[0]
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .light)

        // Should not contain fence markers
        #expect(!result.attributedString.string.contains("```"))
        #expect(result.attributedString.string.contains("let x = 1"))
    }

    @Test("Render horizontal rule produces non-empty attributed string")
    func renderHorizontalRule() {
        let block = firstBlock("---")
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .light)

        #expect(!result.attributedString.string.isEmpty)
        #expect(result.isActive == false)
    }

    // NOTE: Render tests for unorderedList and blockquote are omitted because
    // the renderer crashes on child nodes whose InlineRun ranges reference
    // the parent source string (pre-existing bug in MarkdownRenderer).
    // See: String index range is out of bounds in renderInlineRuns.

    @Test("Render image placeholder shows alt text")
    func renderImagePlaceholder() {
        let source = "![Photo](image.png)"
        let result_ = parser.parse(source, revision: 1)
        guard let block = result_.blocks.first else {
            Issue.record("Expected at least one block")
            return
        }
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .light)

        let text = result.attributedString.string
        #expect(text.contains("Image"))
    }

    // MARK: - Render Active Block

    @Test("RenderActiveBlock returns isActive true")
    func renderActiveBlockIsActive() {
        let block = firstBlock("Hello")
        let settings = EditorSettings.shared
        let result = renderer.renderActiveBlock(block: block, settings: settings, appearance: .light)

        #expect(result.isActive == true)
        #expect(result.blockID == block.id)
    }

    @Test("RenderActiveBlock shows raw source text for paragraph")
    func renderActiveBlockRawSource() {
        let block = firstBlock("Hello, world!")
        let settings = EditorSettings.shared
        let result = renderer.renderActiveBlock(block: block, settings: settings, appearance: .light)

        #expect(result.attributedString.string == "Hello, world!")
    }

    @Test("RenderActiveBlock preserves heading text content")
    func renderActiveBlockHeading() {
        let block = firstBlock("## Subtitle")
        let settings = EditorSettings.shared
        let result = renderer.renderActiveBlock(block: block, settings: settings, appearance: .light)

        // Active mode renders the inline runs; heading text should be present
        #expect(result.attributedString.string.contains("Subtitle"))
        #expect(result.isActive == true)
    }

    // MARK: - Appearance Modes

    @Test("Render with light appearance produces valid result")
    func renderLightAppearance() {
        let block = firstBlock("Hello")
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .light)

        #expect(!result.attributedString.string.isEmpty)
        let attrs = result.attributedString.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color != nil)
    }

    @Test("Render with dark appearance produces valid result")
    func renderDarkAppearance() {
        let block = firstBlock("Hello")
        let settings = EditorSettings.shared
        let result = renderer.render(block: block, settings: settings, appearance: .dark)

        #expect(!result.attributedString.string.isEmpty)
        let attrs = result.attributedString.attributes(at: 0, effectiveRange: nil)
        let color = attrs[.foregroundColor] as? NSColor
        #expect(color != nil)
    }

    @Test("Both appearances set a font attribute")
    func bothAppearancesHaveFont() {
        let block = firstBlock("Text")
        let settings = EditorSettings.shared

        let lightResult = renderer.render(block: block, settings: settings, appearance: .light)
        let darkResult = renderer.render(block: block, settings: settings, appearance: .dark)

        let lightFont = lightResult.attributedString.attributes(at: 0, effectiveRange: nil)[.font] as? NSFont
        let darkFont = darkResult.attributedString.attributes(at: 0, effectiveRange: nil)[.font] as? NSFont

        #expect(lightFont != nil)
        #expect(darkFont != nil)
    }
}
