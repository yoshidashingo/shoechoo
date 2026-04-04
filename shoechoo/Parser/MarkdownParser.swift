import Foundation
import Markdown

struct MarkdownParser: Sendable {

    func parse(_ source: String, revision: UInt64) -> ParseResult {
        let document = Document(parsing: source, options: [.parseBlockDirectives, .parseSymbolLinks])
        var blocks: [EditorNode] = []

        for child in document.children {
            if let node = convertBlock(child, source: source) {
                blocks.append(node)
            }
        }

        return ParseResult(revision: revision, blocks: blocks)
    }

    // MARK: - Block Conversion

    private func convertBlock(_ markup: any Markup, source: String) -> EditorNode? {
        let range = sourceRange(for: markup, in: source)
        let text = String(source[range])

        switch markup {
        case let heading as Heading:
            let inlines = extractInlineRuns(from: heading, source: source)
            return EditorNode(
                kind: .heading(level: heading.level),
                sourceRange: range,
                sourceText: text,
                inlineRuns: inlines
            )

        case let paragraph as Paragraph:
            let inlines = extractInlineRuns(from: paragraph, source: source)
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
                let itemRange = sourceRange(for: item, in: source)
                let itemText = String(source[itemRange])
                let inlines = item.children.flatMap { child in
                    extractInlineRuns(from: child, source: source)
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
                let itemRange = sourceRange(for: item, in: source)
                let itemText = String(source[itemRange])
                let inlines = item.children.flatMap { child in
                    extractInlineRuns(from: child, source: source)
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
            let children = quote.children.compactMap { convertBlock($0, source: source) }
            return EditorNode(
                kind: .blockquote,
                sourceRange: range,
                sourceText: text,
                children: children
            )

        case let table as Markdown.Table:
            var children: [EditorNode] = []
            let headRange = sourceRange(for: table.head, in: source)
            let headText = String(source[headRange])
            children.append(EditorNode(
                kind: .tableRow,
                sourceRange: headRange,
                sourceText: headText
            ))
            for row in table.body.rows {
                let rowRange = sourceRange(for: row, in: source)
                let rowText = String(source[rowRange])
                children.append(EditorNode(
                    kind: .tableRow,
                    sourceRange: rowRange,
                    sourceText: rowText
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

    private func extractInlineRuns(from markup: any Markup, source: String) -> [InlineRun] {
        var runs: [InlineRun] = []

        for child in markup.children {
            let range = sourceRange(for: child, in: source)

            switch child {
            case is Strong:
                runs.append(InlineRun(type: .bold, range: range))
            case is Emphasis:
                runs.append(InlineRun(type: .italic, range: range))
            case is Strikethrough:
                runs.append(InlineRun(type: .strikethrough, range: range))
            case is InlineCode:
                runs.append(InlineRun(type: .inlineCode, range: range))
            case let link as Markdown.Link:
                runs.append(InlineRun(type: .link(url: link.destination ?? ""), range: range))
            case let image as Markdown.Image:
                runs.append(InlineRun(type: .image(src: image.source ?? "", alt: image.plainText), range: range))
            case is SoftBreak, is LineBreak:
                runs.append(InlineRun(type: .lineBreak, range: range))
            case is Text:
                runs.append(InlineRun(type: .text, range: range))
            default:
                runs.append(contentsOf: extractInlineRuns(from: child, source: source))
            }
        }

        return runs
    }

    // MARK: - Source Range Mapping

    private func sourceRange(for markup: any Markup, in source: String) -> Range<String.Index> {
        guard let markupRange = markup.range else {
            return source.startIndex..<source.startIndex
        }

        let startIndex = index(
            line: markupRange.lowerBound.line,
            column: markupRange.lowerBound.column,
            in: source
        )
        let endIndex = index(
            line: markupRange.upperBound.line,
            column: markupRange.upperBound.column,
            in: source
        )

        return startIndex..<endIndex
    }

    private func index(line: Int, column: Int, in source: String) -> String.Index {
        var currentLine = 1
        var currentIndex = source.startIndex

        // Advance to the target line
        while currentLine < line && currentIndex < source.endIndex {
            if source[currentIndex] == "\n" {
                currentLine += 1
            }
            currentIndex = source.index(after: currentIndex)
        }

        // Advance to the target column (1-based)
        var col = 1
        while col < column && currentIndex < source.endIndex && source[currentIndex] != "\n" {
            currentIndex = source.index(after: currentIndex)
            col += 1
        }

        return currentIndex
    }
}
