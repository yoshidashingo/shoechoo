import Testing
import Foundation
@testable import shoechoo

@Suite("MarkdownParser")
struct MarkdownParserTests {

    let parser = MarkdownParser()

    // MARK: - Empty & Simple

    @Test("Parse empty string produces 0 blocks")
    func parseEmpty() {
        let result = parser.parse("", revision: 1)
        #expect(result.blocks.isEmpty)
        #expect(result.revision == 1)
    }

    @Test("Parse single paragraph produces 1 paragraph block")
    func parseSingleParagraph() {
        let result = parser.parse("Hello, world!", revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .paragraph)
        #expect(result.blocks[0].sourceText.contains("Hello, world!"))
    }

    // MARK: - Headings

    @Test("Parse heading levels 1 through 6", arguments: 1...6)
    func parseHeading(level: Int) {
        let prefix = String(repeating: "#", count: level)
        let source = "\(prefix) Heading \(level)"
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .heading(level: level))
    }

    // MARK: - Code Block

    @Test("Parse fenced code block with language")
    func parseCodeBlockWithLanguage() {
        let source = """
        ```swift
        let x = 1
        ```
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .codeBlock(language: "swift"))
    }

    @Test("Parse fenced code block without language")
    func parseCodeBlockNoLanguage() {
        let source = """
        ```
        some code
        ```
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        if case .codeBlock(let lang) = result.blocks[0].kind {
            #expect(lang == nil || lang?.isEmpty == true)
        } else {
            Issue.record("Expected codeBlock kind")
        }
    }

    // MARK: - Lists

    @Test("Parse unordered list produces unorderedList with listItem children")
    func parseUnorderedList() {
        let source = """
        - Apple
        - Banana
        - Cherry
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .unorderedList)
        #expect(result.blocks[0].children.count == 3)
        for child in result.blocks[0].children {
            #expect(child.kind == .listItem(marker: .bullet))
        }
    }

    @Test("Parse ordered list produces orderedList with listItem children")
    func parseOrderedList() {
        let source = """
        1. First
        2. Second
        3. Third
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .orderedList)
        #expect(result.blocks[0].children.count == 3)
        #expect(result.blocks[0].children[0].kind == .listItem(marker: .ordered(start: 1)))
        #expect(result.blocks[0].children[1].kind == .listItem(marker: .ordered(start: 2)))
        #expect(result.blocks[0].children[2].kind == .listItem(marker: .ordered(start: 3)))
    }

    @Test("Parse task list produces items with taskListItem kind")
    func parseTaskList() {
        let source = """
        - [ ] Todo
        - [x] Done
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .unorderedList)
        #expect(result.blocks[0].children.count == 2)
        #expect(result.blocks[0].children[0].kind == .taskListItem(isChecked: false))
        #expect(result.blocks[0].children[1].kind == .taskListItem(isChecked: true))
    }

    // MARK: - Blockquote

    @Test("Parse blockquote produces blockquote block with children")
    func parseBlockquote() {
        let source = """
        > This is a quote
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .blockquote)
        #expect(!result.blocks[0].children.isEmpty)
    }

    // MARK: - Table

    @Test("Parse table produces table block with tableRow children")
    func parseTable() {
        let source = """
        | A | B |
        |---|---|
        | 1 | 2 |
        | 3 | 4 |
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .table)
        // 1 head row + 2 body rows
        #expect(result.blocks[0].children.count == 3)
        for child in result.blocks[0].children {
            #expect(child.kind == .tableRow)
        }
    }

    // MARK: - Horizontal Rule

    @Test("Parse horizontal rule")
    func parseHorizontalRule() {
        let source = """
        ---
        """
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        #expect(result.blocks[0].kind == .horizontalRule)
    }

    // MARK: - Inline Runs

    @Test("Parse bold inline produces bold InlineRun")
    func parseBoldInline() {
        let source = "This is **bold** text"
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        let runs = result.blocks[0].inlineRuns
        let boldRuns = runs.filter { $0.type == .bold }
        #expect(!boldRuns.isEmpty)
    }

    @Test("Parse italic inline produces italic InlineRun")
    func parseItalicInline() {
        let source = "This is *italic* text"
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        let runs = result.blocks[0].inlineRuns
        let italicRuns = runs.filter { $0.type == .italic }
        #expect(!italicRuns.isEmpty)
    }

    @Test("Parse link inline produces link InlineRun with URL")
    func parseLinkInline() {
        let source = "Visit [Example](https://example.com) now"
        let result = parser.parse(source, revision: 1)
        #expect(result.blocks.count == 1)
        let runs = result.blocks[0].inlineRuns
        let linkRuns = runs.filter {
            if case .link = $0.type { return true }
            return false
        }
        #expect(linkRuns.count == 1)
        if case .link(let url) = linkRuns[0].type {
            #expect(url == "https://example.com")
        }
    }

    @Test("Parse inline code produces inlineCode InlineRun")
    func parseInlineCode() {
        let source = "Use `print()` here"
        let result = parser.parse(source, revision: 1)
        let runs = result.blocks[0].inlineRuns
        let codeRuns = runs.filter { $0.type == .inlineCode }
        #expect(!codeRuns.isEmpty)
    }

    // MARK: - Mixed Document

    @Test("Parse mixed document with multiple block types")
    func parseMixedDocument() {
        let source = """
        # Title

        A paragraph.

        - Item 1
        - Item 2

        ```swift
        let x = 1
        ```

        ---

        > A quote
        """
        let result = parser.parse(source, revision: 1)
        // Expect: heading, paragraph, unorderedList, codeBlock, horizontalRule, blockquote
        #expect(result.blocks.count >= 6)

        #expect(result.blocks[0].kind == .heading(level: 1))
        #expect(result.blocks[1].kind == .paragraph)
        #expect(result.blocks[2].kind == .unorderedList)
        #expect(result.blocks[3].kind == .codeBlock(language: "swift"))
        #expect(result.blocks[4].kind == .horizontalRule)
        #expect(result.blocks[5].kind == .blockquote)
    }

    // MARK: - Revision

    @Test("ParseResult carries the correct revision")
    func parseResultRevision() {
        let result = parser.parse("Hello", revision: 42)
        #expect(result.revision == 42)
    }
}
