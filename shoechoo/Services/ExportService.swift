import AppKit
import WebKit
import Markdown

// MARK: - HTMLConverter

/// Walks the swift-markdown AST and produces an HTML string.
/// swift-markdown 0.5.0 does not include a built-in HTML formatter,
/// so we implement one using the MarkupWalker protocol.
struct HTMLConverter: MarkupWalker {
    private(set) var result = ""

    mutating func visitDocument(_ document: Document) {
        descendInto(document)
    }

    mutating func visitHeading(_ heading: Heading) {
        let tag = "h\(heading.level)"
        result += "<\(tag)>"
        descendInto(heading)
        result += "</\(tag)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        result += "<p>"
        descendInto(paragraph)
        result += "</p>\n"
    }

    mutating func visitText(_ text: Markdown.Text) {
        result += escapeHTML(text.string)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        descendInto(emphasis)
        result += "</em>"
    }

    mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        descendInto(strong)
        result += "</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += "<del>"
        descendInto(strikethrough)
        result += "</del>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        if let lang = codeBlock.language, !lang.isEmpty {
            result += "<pre><code class=\"language-\(escapeHTML(lang))\">"
        } else {
            result += "<pre><code>"
        }
        result += escapeHTML(codeBlock.code)
        result += "</code></pre>\n"
    }

    mutating func visitLink(_ link: Markdown.Link) {
        let href = link.destination ?? ""
        result += "<a href=\"\(escapeHTML(href))\">"
        descendInto(link)
        result += "</a>"
    }

    mutating func visitImage(_ image: Markdown.Image) {
        let src = image.source ?? ""
        let alt = image.plainText
        result += "<img src=\"\(escapeHTML(src))\" alt=\"\(escapeHTML(alt))\">"
    }

    mutating func visitUnorderedList(_ list: UnorderedList) {
        result += "<ul>\n"
        descendInto(list)
        result += "</ul>\n"
    }

    mutating func visitOrderedList(_ list: OrderedList) {
        if list.startIndex != 1 {
            result += "<ol start=\"\(list.startIndex)\">\n"
        } else {
            result += "<ol>\n"
        }
        descendInto(list)
        result += "</ol>\n"
    }

    mutating func visitListItem(_ item: ListItem) {
        if let checkbox = item.checkbox {
            let checked = checkbox == .checked
            result += "<li><input type=\"checkbox\" disabled\(checked ? " checked" : "")> "
            descendInto(item)
            result += "</li>\n"
        } else {
            result += "<li>"
            descendInto(item)
            result += "</li>\n"
        }
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        result += "<blockquote>\n"
        descendInto(blockQuote)
        result += "</blockquote>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr>\n"
    }

    mutating func visitTable(_ table: Markdown.Table) {
        result += "<table>\n"
        // Head
        result += "<thead>\n<tr>\n"
        for cell in table.head.cells {
            result += "<th>"
            descendInto(cell)
            result += "</th>\n"
        }
        result += "</tr>\n</thead>\n"
        // Body
        let bodyRows = Array(table.body.rows)
        if !bodyRows.isEmpty {
            result += "<tbody>\n"
            for row in bodyRows {
                result += "<tr>\n"
                for cell in row.cells {
                    result += "<td>"
                    descendInto(cell)
                    result += "</td>\n"
                }
                result += "</tr>\n"
            }
            result += "</tbody>\n"
        }
        result += "</table>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += html.rawHTML
    }

    mutating func visitInlineHTML(_ html: InlineHTML) {
        result += html.rawHTML
    }

    // MARK: - Helpers

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - WebViewLoadDelegate

@MainActor
private final class WebViewLoadDelegate: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Error>?

    func waitForLoad() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume()
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// MARK: - ExportService

actor ExportService {
    static let shared = ExportService()

    /// Generate standalone HTML from Markdown source.
    func generateHTML(from source: String, title: String) -> String {
        let document = Document(parsing: source, options: [.parseBlockDirectives, .parseSymbolLinks])
        var converter = HTMLConverter()
        converter.visit(document)
        let htmlBody = converter.result

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>\(escapeHTML(title))</title>
        <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 800px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #333; }
        h1 { font-size: 2em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid #eee; padding-bottom: 0.3em; }
        code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: 'SF Mono', Menlo, monospace; }
        pre code { display: block; padding: 16px; overflow-x: auto; background: #f4f4f4; }
        blockquote { border-left: 4px solid #ddd; margin-left: 0; padding-left: 16px; color: #666; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background: #f4f4f4; }
        img { max-width: 100%; }
        input[type="checkbox"] { margin-right: 4px; }
        hr { border: none; border-top: 1px solid #eee; margin: 24px 0; }
        </style>
        </head>
        <body>
        \(htmlBody)
        </body>
        </html>
        """
    }

    /// Generate PDF from HTML using an offscreen WKWebView.
    @MainActor
    func generatePDF(from html: String) async throws -> Data {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: config)

        // Wait for page load using navigation delegate
        let loadDelegate = WebViewLoadDelegate()
        webView.navigationDelegate = loadDelegate
        webView.loadHTMLString(html, baseURL: nil)
        try await loadDelegate.waitForLoad()

        let pdfConfig = WKPDFConfiguration()
        pdfConfig.rect = NSRect(x: 0, y: 0, width: 595, height: 842) // A4

        let data = try await webView.pdf(configuration: pdfConfig)
        return data
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
