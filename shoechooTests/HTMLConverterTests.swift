import Testing
import Foundation
import Markdown
@testable import shoechoo

@Suite("HTMLConverter")
struct HTMLConverterTests {

    /// Helper: convert Markdown source to HTML using HTMLConverter.
    private func convert(_ markdown: String) -> String {
        let document = Document(parsing: markdown)
        var converter = HTMLConverter()
        converter.visit(document)
        return converter.result
    }

    // MARK: - Headings

    @Test("Heading levels 1 through 6", arguments: 1...6)
    func testHeadingConversion(level: Int) {
        let prefix = String(repeating: "#", count: level)
        let html = convert("\(prefix) Title")
        #expect(html.contains("<h\(level)>Title</h\(level)>"))
    }

    // MARK: - Paragraph

    @Test("Paragraph wraps text in <p> tags")
    func testParagraphConversion() {
        let html = convert("Hello, world!")
        #expect(html.contains("<p>Hello, world!</p>"))
    }

    // MARK: - Emphasis and Strong

    @Test("Emphasis produces <em> tag")
    func testEmphasis() {
        let html = convert("This is *italic* text")
        #expect(html.contains("<em>italic</em>"))
    }

    @Test("Strong produces <strong> tag")
    func testStrong() {
        let html = convert("This is **bold** text")
        #expect(html.contains("<strong>bold</strong>"))
    }

    @Test("Emphasis and strong combined")
    func testEmphasisAndStrong() {
        let html = convert("Use **bold** and *italic* together")
        #expect(html.contains("<strong>bold</strong>"))
        #expect(html.contains("<em>italic</em>"))
    }

    // MARK: - Code Blocks

    @Test("Code block with language produces class attribute")
    func testCodeBlockWithLanguage() {
        let source = """
        ```swift
        let x = 1
        ```
        """
        let html = convert(source)
        #expect(html.contains("<pre><code class=\"language-swift\">"))
        #expect(html.contains("let x = 1"))
        #expect(html.contains("</code></pre>"))
    }

    @Test("Code block without language omits class attribute")
    func testCodeBlockWithoutLanguage() {
        let source = """
        ```
        some code
        ```
        """
        let html = convert(source)
        #expect(html.contains("<pre><code>"))
        #expect(html.contains("some code"))
        #expect(html.contains("</code></pre>"))
    }

    // MARK: - Inline Code

    @Test("Inline code produces <code> tag")
    func testInlineCode() {
        let html = convert("Use `print()` here")
        #expect(html.contains("<code>print()</code>"))
    }

    // MARK: - Unordered List

    @Test("Unordered list produces <ul> with <li> items")
    func testUnorderedList() {
        let source = """
        - Apple
        - Banana
        - Cherry
        """
        let html = convert(source)
        #expect(html.contains("<ul>"))
        #expect(html.contains("<li>"))
        #expect(html.contains("Apple"))
        #expect(html.contains("Banana"))
        #expect(html.contains("Cherry"))
        #expect(html.contains("</li>"))
        #expect(html.contains("</ul>"))
    }

    // MARK: - Ordered List

    @Test("Ordered list with start index produces <ol> with start attribute")
    func testOrderedListWithStartIndex() {
        let source = """
        3. Third
        4. Fourth
        """
        let html = convert(source)
        #expect(html.contains("<ol start=\"3\">"))
        #expect(html.contains("<li>"))
        #expect(html.contains("Third"))
        #expect(html.contains("Fourth"))
    }

    @Test("Ordered list starting at 1 omits start attribute")
    func testOrderedListStartAtOne() {
        let source = """
        1. First
        2. Second
        """
        let html = convert(source)
        #expect(html.contains("<ol>"))
        #expect(!html.contains("<ol start="))
    }

    // MARK: - Task List Items

    @Test("Task list items produce checkboxes")
    func testTaskListItems() {
        let source = """
        - [ ] Todo
        - [x] Done
        """
        let html = convert(source)
        #expect(html.contains("<input type=\"checkbox\" disabled>"))
        #expect(html.contains("<input type=\"checkbox\" disabled checked>"))
        #expect(html.contains("Todo"))
        #expect(html.contains("Done"))
    }

    // MARK: - Blockquote

    @Test("Blockquote produces <blockquote> tag")
    func testBlockQuote() {
        let html = convert("> This is a quote")
        #expect(html.contains("<blockquote>"))
        #expect(html.contains("This is a quote"))
        #expect(html.contains("</blockquote>"))
    }

    // MARK: - Table

    @Test("Table produces <table> with thead and tbody")
    func testTable() {
        let source = """
        | A | B |
        |---|---|
        | 1 | 2 |
        """
        let html = convert(source)
        #expect(html.contains("<table>"))
        #expect(html.contains("<thead>"))
        #expect(html.contains("<th>A</th>"))
        #expect(html.contains("<th>B</th>"))
        #expect(html.contains("<tbody>"))
        #expect(html.contains("<td>1</td>"))
        #expect(html.contains("<td>2</td>"))
        #expect(html.contains("</table>"))
    }

    // MARK: - Link

    @Test("Link produces <a> tag with href")
    func testLink() {
        let html = convert("[Example](https://example.com)")
        #expect(html.contains("<a href=\"https://example.com\">Example</a>"))
    }

    // MARK: - Image

    @Test("Image produces <img> tag with src and alt")
    func testImage() {
        let html = convert("![Alt text](image.png)")
        #expect(html.contains("<img src=\"image.png\" alt=\"Alt text\">"))
    }

    // MARK: - HTML Escaping

    @Test("Ampersand is escaped in text")
    func testHTMLEscaping() {
        let html = convert("Tom & Jerry")
        #expect(html.contains("Tom &amp; Jerry"))
    }

    @Test("Angle brackets in inline code are escaped")
    func testHTMLEscapingInCode() {
        let html = convert("Use `<div>`")
        #expect(html.contains("&lt;div&gt;"))
    }

    // MARK: - Thematic Break

    @Test("Thematic break produces <hr> tag")
    func testThematicBreak() {
        let html = convert("---")
        #expect(html.contains("<hr>"))
    }
}
