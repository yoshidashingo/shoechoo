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
            return EditorNode(
                kind: .heading(level: heading.level),
                sourceRange: range,
                sourceText: text,
                inlineRuns: inlines
            )

        case let paragraph as Paragraph:
            let inlines = extractInlineRuns(from: paragraph, source: source, nsSource: nsSource, blockRange: range)
            return EditorNode(
                kind: .paragraph,
                sourceRange: range,
                sourceText: text,
                inlineRuns: inlines
            )

        case let codeBlock as CodeBlock:
            return EditorNode(
                kind: .codeBlock(language: codeBlock.language),
                sourceRange: range,
                sourceText: text
            )

        case let list as UnorderedList:
            let children = Array(list.listItems).compactMap { item -> EditorNode? in
                let itemRange = nsRange(for: item, in: source, nsSource: nsSource)
                let itemText = nsSource.substring(with: itemRange)
                let inlines = item.children.flatMap { child in
                    extractInlineRuns(from: child, source: source, nsSource: nsSource, blockRange: itemRange)
                }
                if let checkbox = item.checkbox {
                    return EditorNode(
                        kind: .taskListItem(isChecked: checkbox == .checked),
                        sourceRange: itemRange,
                        sourceText: itemText,
                        inlineRuns: inlines
                    )
                }
                return EditorNode(
                    kind: .listItem(marker: .bullet),
                    sourceRange: itemRange,
                    sourceText: itemText,
                    inlineRuns: inlines
                )
            }
            return EditorNode(
                kind: .unorderedList,
                sourceRange: range,
                sourceText: text,
                children: children
            )

        case let list as OrderedList:
            let children = Array(list.listItems).enumerated().compactMap { (index, item) -> EditorNode? in
                let itemRange = nsRange(for: item, in: source, nsSource: nsSource)
                let itemText = nsSource.substring(with: itemRange)
                let inlines = item.children.flatMap { child in
                    extractInlineRuns(from: child, source: source, nsSource: nsSource, blockRange: itemRange)
                }
                return EditorNode(
                    kind: .listItem(marker: .ordered(start: Int(list.startIndex) + index)),
                    sourceRange: itemRange,
                    sourceText: itemText,
                    inlineRuns: inlines
                )
            }
            return EditorNode(
                kind: .orderedList,
                sourceRange: range,
                sourceText: text,
                children: children
            )

        case let quote as BlockQuote:
            let children = quote.children.compactMap { convertBlock($0, source: source, nsSource: nsSource) }
            return EditorNode(
                kind: .blockquote,
                sourceRange: range,
                sourceText: text,
                children: children
            )

        case let table as Markdown.Table:
            var children: [EditorNode] = []
            let headRange = nsRange(for: table.head, in: source, nsSource: nsSource)
            children.append(EditorNode(
                kind: .tableRow,
                sourceRange: headRange,
                sourceText: nsSource.substring(with: headRange)
            ))
            for row in table.body.rows {
                let rowRange = nsRange(for: row, in: source, nsSource: nsSource)
                children.append(EditorNode(
                    kind: .tableRow,
                    sourceRange: rowRange,
                    sourceText: nsSource.substring(with: rowRange)
                ))
            }
            return EditorNode(
                kind: .table,
                sourceRange: range,
                sourceText: text,
                children: children
            )

        case is ThematicBreak:
            return EditorNode(
                kind: .horizontalRule,
                sourceRange: range,
                sourceText: text
            )

        case let image as Markdown.Image:
            return EditorNode(
                kind: .image(src: image.source ?? "", alt: image.plainText),
                sourceRange: range,
                sourceText: text
            )

        default:
            return EditorNode(
                kind: .paragraph,
                sourceRange: range,
                sourceText: text
            )
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
            // Convert absolute range to block-relative range
            let localRange = NSRange(
                location: absRange.location - blockRange.location,
                length: absRange.length
            )
            guard localRange.location >= 0,
                  localRange.location + localRange.length <= (nsSource.substring(with: blockRange) as NSString).length else {
                continue
            }

            switch child {
            case is Strong:
                runs.append(InlineRun(type: .bold, range: localRange))
            case is Emphasis:
                runs.append(InlineRun(type: .italic, range: localRange))
            case is Strikethrough:
                runs.append(InlineRun(type: .strikethrough, range: localRange))
            case is InlineCode:
                runs.append(InlineRun(type: .inlineCode, range: localRange))
            case let link as Markdown.Link:
                runs.append(InlineRun(type: .link(url: link.destination ?? ""), range: localRange))
            case let image as Markdown.Image:
                runs.append(InlineRun(type: .image(src: image.source ?? "", alt: image.plainText), range: localRange))
            case is SoftBreak, is LineBreak:
                runs.append(InlineRun(type: .lineBreak, range: localRange))
            case is Text:
                runs.append(InlineRun(type: .text, range: localRange))
            default:
                runs.append(contentsOf: extractInlineRuns(from: child, source: source, nsSource: nsSource, blockRange: blockRange))
            }
        }

        return runs
    }

    // MARK: - Source Range Mapping (produces NSRange with UTF-16 offsets)

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
    /// swift-markdown columns count Unicode scalars (not UTF-16 code units),
    /// so we walk through Swift String indices and then convert to UTF-16.
    private func utf16Offset(line: Int, column: Int, in source: String, nsSource: NSString) -> Int {
        var currentLine = 1
        var idx = source.startIndex

        // Advance to the target line
        while currentLine < line && idx < source.endIndex {
            if source[idx] == "\n" {
                currentLine += 1
            }
            idx = source.index(after: idx)
        }

        // Advance by (column - 1) Unicode scalars
        var col = 1
        while col < column && idx < source.endIndex && source[idx] != "\n" {
            idx = source.index(after: idx)
            col += 1
        }

        // Convert String.Index to UTF-16 offset
        return source[source.startIndex..<idx].utf16.count
    }
}
