import Foundation
import Markdown

struct MarkdownParser: Sendable {

    func parse(_ source: String, revision: UInt64) -> ParseResult {
        let document = Document(parsing: source, options: [.parseBlockDirectives, .parseSymbolLinks])
        let nsSource = source as NSString
        var blocks: [EditorNode] = []

        for child in document.children {
            if let node = convertBlock(child, source: source, nsSource: nsSource) {
                blocks.append(node)
            }
        }

        return ParseResult(revision: revision, blocks: blocks)
    }

    // MARK: - Block Conversion

    private func convertBlock(_ markup: any Markup, source: String, nsSource: NSString) -> EditorNode? {
        let range = nsRange(for: markup, in: source, nsSource: nsSource)
        let text = nsSource.substring(with: range)

        switch markup {
        case let heading as Heading:
            let inlines = extractInlineRuns(from: heading, source: source, nsSource: nsSource, blockRange: range)
            return EditorNode(kind: .heading(level: heading.level), sourceRange: range, sourceText: text, inlineRuns: inlines)

        case let paragraph as Paragraph:
            let inlines = extractInlineRuns(from: paragraph, source: source, nsSource: nsSource, blockRange: range)
            return EditorNode(kind: .paragraph, sourceRange: range, sourceText: text, inlineRuns: inlines)

        case let codeBlock as CodeBlock:
            return EditorNode(kind: .codeBlock(language: codeBlock.language), sourceRange: range, sourceText: text)

        case let list as UnorderedList:
            let children = Array(list.listItems).compactMap { item -> EditorNode? in
                let itemRange = nsRange(for: item, in: source, nsSource: nsSource)
                let itemText = nsSource.substring(with: itemRange)
                let inlines = item.children.flatMap { child in
                    extractInlineRuns(from: child, source: source, nsSource: nsSource, blockRange: itemRange)
                }
                if let checkbox = item.checkbox {
                    return EditorNode(kind: .taskListItem(isChecked: checkbox == .checked), sourceRange: itemRange, sourceText: itemText, inlineRuns: inlines)
                }
                return EditorNode(kind: .listItem(marker: .bullet), sourceRange: itemRange, sourceText: itemText, inlineRuns: inlines)
            }
            return EditorNode(kind: .unorderedList, sourceRange: range, sourceText: text, children: children)

        case let list as OrderedList:
            let children = Array(list.listItems).enumerated().compactMap { (index, item) -> EditorNode? in
                let itemRange = nsRange(for: item, in: source, nsSource: nsSource)
                let itemText = nsSource.substring(with: itemRange)
                let inlines = item.children.flatMap { child in
                    extractInlineRuns(from: child, source: source, nsSource: nsSource, blockRange: itemRange)
                }
                return EditorNode(kind: .listItem(marker: .ordered(start: Int(list.startIndex) + index)), sourceRange: itemRange, sourceText: itemText, inlineRuns: inlines)
            }
            return EditorNode(kind: .orderedList, sourceRange: range, sourceText: text, children: children)

        case let quote as BlockQuote:
            let children = quote.children.compactMap { convertBlock($0, source: source, nsSource: nsSource) }
            return EditorNode(kind: .blockquote, sourceRange: range, sourceText: text, children: children)

        case let table as Markdown.Table:
            var children: [EditorNode] = []
            let headRange = nsRange(for: table.head, in: source, nsSource: nsSource)
            children.append(EditorNode(kind: .tableRow, sourceRange: headRange, sourceText: nsSource.substring(with: headRange)))
            for row in table.body.rows {
                let rowRange = nsRange(for: row, in: source, nsSource: nsSource)
                children.append(EditorNode(kind: .tableRow, sourceRange: rowRange, sourceText: nsSource.substring(with: rowRange)))
            }
            return EditorNode(kind: .table, sourceRange: range, sourceText: text, children: children)

        case is ThematicBreak:
            return EditorNode(kind: .horizontalRule, sourceRange: range, sourceText: text)

        case let image as Markdown.Image:
            return EditorNode(kind: .image(src: image.source ?? "", alt: image.plainText), sourceRange: range, sourceText: text)

        default:
            return EditorNode(kind: .paragraph, sourceRange: range, sourceText: text)
        }
    }

    // MARK: - Inline Extraction

    private func extractInlineRuns(
        from markup: any Markup,
        source: String,
        nsSource: NSString,
        blockRange: NSRange
    ) -> [InlineRun] {
        var runs: [InlineRun] = []

        for child in markup.children {
            let absRange = nsRange(for: child, in: source, nsSource: nsSource)
            let blockText = nsSource.substring(with: blockRange) as NSString

            switch child {
            case is Strong:
                // Check if parent is Emphasis → handled by parent
                if child.parent is Emphasis { break }
                // Check if child contains Emphasis → boldItalic
                let hasInnerEmphasis = child.children.contains(where: { $0 is Emphasis })
                if hasInnerEmphasis {
                    let expanded = expandRange(absRange, delimiter: "***", in: nsSource)
                    let localRange = toLocalRange(expanded, blockRange: blockRange, blockText: blockText)
                    if let lr = localRange { runs.append(InlineRun(type: .boldItalic, range: lr)) }
                } else {
                    let expanded = expandRange(absRange, delimiter: "**", in: nsSource)
                    let localRange = toLocalRange(expanded, blockRange: blockRange, blockText: blockText)
                    if let lr = localRange { runs.append(InlineRun(type: .bold, range: lr)) }
                }

            case is Emphasis:
                // Check if child contains Strong → boldItalic
                let hasInnerStrong = child.children.contains(where: { $0 is Strong })
                if hasInnerStrong {
                    let expanded = expandRange(absRange, delimiter: "***", in: nsSource)
                    let localRange = toLocalRange(expanded, blockRange: blockRange, blockText: blockText)
                    if let lr = localRange { runs.append(InlineRun(type: .boldItalic, range: lr)) }
                } else {
                    let expanded = expandRange(absRange, delimiter: "*", in: nsSource)
                    let localRange = toLocalRange(expanded, blockRange: blockRange, blockText: blockText)
                    if let lr = localRange { runs.append(InlineRun(type: .italic, range: lr)) }
                }

            case is Strikethrough:
                let expanded = expandRange(absRange, delimiter: "~~", in: nsSource)
                let localRange = toLocalRange(expanded, blockRange: blockRange, blockText: blockText)
                if let lr = localRange { runs.append(InlineRun(type: .strikethrough, range: lr)) }

            case is InlineCode:
                let expanded = expandRange(absRange, delimiter: "`", in: nsSource)
                let localRange = toLocalRange(expanded, blockRange: blockRange, blockText: blockText)
                if let lr = localRange { runs.append(InlineRun(type: .inlineCode, range: lr)) }

            case let link as Markdown.Link:
                // Link range from swift-markdown includes [text](url)
                let localRange = toLocalRange(absRange, blockRange: blockRange, blockText: blockText)
                if let lr = localRange { runs.append(InlineRun(type: .link(url: link.destination ?? ""), range: lr)) }

            case let image as Markdown.Image:
                let localRange = toLocalRange(absRange, blockRange: blockRange, blockText: blockText)
                if let lr = localRange { runs.append(InlineRun(type: .image(src: image.source ?? "", alt: image.plainText), range: lr)) }

            case is SoftBreak, is LineBreak:
                let localRange = toLocalRange(absRange, blockRange: blockRange, blockText: blockText)
                if let lr = localRange { runs.append(InlineRun(type: .lineBreak, range: lr)) }

            case is Text:
                let localRange = toLocalRange(absRange, blockRange: blockRange, blockText: blockText)
                if let lr = localRange { runs.append(InlineRun(type: .text, range: lr)) }

            default:
                runs.append(contentsOf: extractInlineRuns(from: child, source: source, nsSource: nsSource, blockRange: blockRange))
            }
        }

        return runs
    }

    /// Expand an AST range to include surrounding delimiter characters.
    /// swift-markdown's Strong/Emphasis/InlineCode/Strikethrough ranges exclude delimiters.
    private func expandRange(_ range: NSRange, delimiter: String, in nsSource: NSString) -> NSRange {
        let delimLen = (delimiter as NSString).length
        let newLoc = max(0, range.location - delimLen)
        let newEnd = min(nsSource.length, range.location + range.length + delimLen)

        // Verify the expanded range actually contains the delimiters
        let prefix = nsSource.substring(with: NSRange(location: newLoc, length: delimLen))
        let suffix = nsSource.substring(with: NSRange(location: newEnd - delimLen, length: delimLen))

        if prefix == delimiter && suffix == delimiter {
            return NSRange(location: newLoc, length: newEnd - newLoc)
        }
        // Fallback: return original range if delimiters not found
        return range
    }

    /// Convert absolute range to block-relative range.
    private func toLocalRange(_ absRange: NSRange, blockRange: NSRange, blockText: NSString) -> NSRange? {
        let localRange = NSRange(location: absRange.location - blockRange.location, length: absRange.length)
        guard localRange.location >= 0,
              localRange.location + localRange.length <= blockText.length else { return nil }
        return localRange
    }

    // MARK: - Source Range Mapping (NSRange with UTF-16 offsets)

    private func nsRange(for markup: any Markup, in source: String, nsSource: NSString) -> NSRange {
        guard let markupRange = markup.range else {
            return NSRange(location: 0, length: 0)
        }

        let startUTF16 = utf16Offset(line: markupRange.lowerBound.line,
                                      column: markupRange.lowerBound.column,
                                      in: source, nsSource: nsSource)
        let endUTF16 = utf16Offset(line: markupRange.upperBound.line,
                                    column: markupRange.upperBound.column,
                                    in: source, nsSource: nsSource)

        let location = max(0, startUTF16)
        let length = max(0, endUTF16 - location)
        return NSRange(location: location, length: min(length, nsSource.length - location))
    }

    /// Converts a 1-based line/column to a UTF-16 offset.
    /// swift-markdown columns count Unicode scalars, so we step through
    /// the scalars view (#46 fix).
    private func utf16Offset(line: Int, column: Int, in source: String, nsSource: NSString) -> Int {
        let scalars = source.unicodeScalars
        var scalarIdx = scalars.startIndex
        var currentLine = 1

        // Advance to the target line
        while currentLine < line && scalarIdx < scalars.endIndex {
            if scalars[scalarIdx] == "\n" {
                currentLine += 1
            }
            scalarIdx = scalars.index(after: scalarIdx)
        }

        // Advance by (column - 1) Unicode scalars
        var col = 1
        while col < column && scalarIdx < scalars.endIndex && scalars[scalarIdx] != "\n" {
            scalarIdx = scalars.index(after: scalarIdx)
            col += 1
        }

        // Convert scalar index to UTF-16 offset
        let stringIdx = String.Index(scalarIdx, within: source) ?? source.endIndex
        return source[source.startIndex..<stringIdx].utf16.count
    }
}
