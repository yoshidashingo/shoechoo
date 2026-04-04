import AppKit

// MARK: - SyntaxHighlighter

/// Applies syntax-highlighting attributes to an `NSTextStorage` WITHOUT changing the text content.
/// The raw Markdown source stays in the text view; only font, color, and other visual attributes are modified.
@MainActor
struct SyntaxHighlighter {

    // MARK: - Appearance

    enum Appearance: Sendable {
        case light, dark
    }

    // MARK: - Public API

    /// Applies block-level and inline syntax-highlighting attributes to `textStorage`.
    /// The string content of `textStorage` is never modified.
    func apply(
        to textStorage: NSTextStorage,
        blocks: [EditorNode],
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let fullSource = textStorage.string
        let nsSource = fullSource as NSString
        let fullRange = NSRange(location: 0, length: nsSource.length)

        // 1. Apply base attributes across the whole document
        let baseFont = self.baseFont(settings: settings)
        let baseColor = primaryTextColor(appearance: appearance)
        let baseParaStyle = baseParagraphStyle(settings: settings)

        textStorage.beginEditing()
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: baseColor,
            .paragraphStyle: baseParaStyle,
        ], range: fullRange)

        // 2. Apply per-block attributes
        for block in blocks {
            applyBlock(block, to: textStorage, fullSource: fullSource, settings: settings, appearance: appearance)
        }

        textStorage.endEditing()
    }

    // MARK: - Block Application

    private func applyBlock(
        _ block: EditorNode,
        to textStorage: NSTextStorage,
        fullSource: String,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let blockRange = NSRange(block.sourceRange, in: fullSource)
        guard blockRange.location != NSNotFound else { return }

        switch block.kind {

        case .heading(let level):
            applyHeading(block, level: level, range: blockRange, to: textStorage,
                         fullSource: fullSource, settings: settings, appearance: appearance)

        case .codeBlock:
            applyCodeBlock(block, range: blockRange, to: textStorage,
                           settings: settings, appearance: appearance)

        case .blockquote:
            applyBlockquote(block, range: blockRange, to: textStorage,
                            fullSource: fullSource, settings: settings, appearance: appearance)

        case .unorderedList, .orderedList:
            for child in block.children {
                applyBlock(child, to: textStorage, fullSource: fullSource,
                           settings: settings, appearance: appearance)
            }

        case .listItem(let marker):
            applyListItem(block, marker: marker, range: blockRange, to: textStorage,
                          fullSource: fullSource, settings: settings, appearance: appearance)

        case .taskListItem:
            applyInlineRuns(block, range: blockRange, to: textStorage,
                            fullSource: fullSource, settings: settings, appearance: appearance)

        case .horizontalRule:
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: blockRange)

        case .paragraph:
            applyInlineRuns(block, range: blockRange, to: textStorage,
                            fullSource: fullSource, settings: settings, appearance: appearance)

        case .table, .tableRow:
            // Keep base attributes for tables
            break

        case .image:
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: blockRange)
        }
    }

    // MARK: - Heading

    private func applyHeading(
        _ block: EditorNode,
        level: Int,
        range: NSRange,
        to textStorage: NSTextStorage,
        fullSource: String,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let fontSize = headingFontSize(level: level, base: settings.fontSize)
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        textStorage.addAttribute(.font, value: font, range: range)

        // Color the leading `#` prefix characters in secondaryLabelColor
        let blockText = block.sourceText
        var prefixEnd = blockText.startIndex
        while prefixEnd < blockText.endIndex && blockText[prefixEnd] == "#" {
            prefixEnd = blockText.index(after: prefixEnd)
        }
        // Include the space after the hashes
        if prefixEnd < blockText.endIndex && blockText[prefixEnd] == " " {
            prefixEnd = blockText.index(after: prefixEnd)
        }

        if prefixEnd > blockText.startIndex {
            let prefixNSRange = NSRange(
                blockText.startIndex..<prefixEnd,
                in: blockText
            ).shifted(by: range.location)
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: prefixNSRange)
        }

        // Apply inline runs for the content portion
        applyInlineRuns(block, range: range, to: textStorage,
                        fullSource: fullSource, settings: settings, appearance: appearance,
                        baseFont: font)
    }

    private func headingFontSize(level: Int, base: CGFloat) -> CGFloat {
        switch level {
        case 1: return 28
        case 2: return 24
        case 3: return 20
        case 4: return 18
        case 5: return 16
        default: return base
        }
    }

    // MARK: - Code Block

    private func applyCodeBlock(
        _ block: EditorNode,
        range: NSRange,
        to textStorage: NSTextStorage,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let monoFont = monospacedFont(size: settings.fontSize)
        let bgColor = appearance == .dark
            ? NSColor.white.withAlphaComponent(0.06)
            : NSColor.black.withAlphaComponent(0.04)

        textStorage.addAttribute(.font, value: monoFont, range: range)
        textStorage.addAttribute(.backgroundColor, value: bgColor, range: range)

        // Color fence lines (``` lines) in secondaryLabelColor
        let blockText = block.sourceText
        let nsBlockText = blockText as NSString
        let lines = blockText.components(separatedBy: "\n")
        var lineStart = 0

        for line in lines {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: range.location + lineStart, length: lineLength)

            if line.hasPrefix("```") {
                textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: lineRange)
            }

            // +1 for the newline character
            lineStart += lineLength + 1
            if lineStart > nsBlockText.length { break }
        }
    }

    // MARK: - Blockquote

    private func applyBlockquote(
        _ block: EditorNode,
        range: NSRange,
        to textStorage: NSTextStorage,
        fullSource: String,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        // Apply secondaryLabelColor to the whole blockquote
        textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)

        // Color `>` markers in systemGreen
        let blockText = block.sourceText
        let lines = blockText.components(separatedBy: "\n")
        var lineOffset = 0

        for line in lines {
            let nsLine = line as NSString
            var markerEnd = 0
            while markerEnd < nsLine.length && nsLine.character(at: markerEnd) == (">").utf16.first! {
                markerEnd += 1
            }
            // Include optional space after >
            if markerEnd < nsLine.length && nsLine.character(at: markerEnd) == (" ").utf16.first! {
                markerEnd += 1
            }
            if markerEnd > 0 {
                let markerRange = NSRange(location: range.location + lineOffset, length: markerEnd)
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: markerRange)
            }
            lineOffset += nsLine.length + 1 // +1 for newline
        }

        // Apply children recursively
        for child in block.children {
            applyBlock(child, to: textStorage, fullSource: fullSource,
                       settings: settings, appearance: appearance)
        }
    }

    // MARK: - List Item

    private func applyListItem(
        _ block: EditorNode,
        marker: ListMarker,
        range: NSRange,
        to textStorage: NSTextStorage,
        fullSource: String,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        // Find the marker prefix (-, *, or "1.") in secondaryLabelColor
        let blockText = block.sourceText
        let nsBlockText = blockText as NSString
        var markerLength = 0

        // Skip leading whitespace
        while markerLength < nsBlockText.length &&
              (blockText.unicodeScalars[blockText.index(blockText.startIndex, offsetBy: markerLength)] == " " ||
               blockText.unicodeScalars[blockText.index(blockText.startIndex, offsetBy: markerLength)] == "\t") {
            markerLength += 1
        }

        // Find the marker itself
        let afterSpace = markerLength
        switch marker {
        case .bullet:
            // -, *, or +
            if afterSpace < nsBlockText.length {
                let c = nsBlockText.character(at: afterSpace)
                if c == ("-" as NSString).character(at: 0) ||
                   c == ("*" as NSString).character(at: 0) ||
                   c == ("+" as NSString).character(at: 0) {
                    markerLength += 1
                }
            }
        case .ordered:
            // Digits followed by "."
            while markerLength < nsBlockText.length {
                let c = nsBlockText.character(at: markerLength)
                if c >= ("0" as NSString).character(at: 0) && c <= ("9" as NSString).character(at: 0) {
                    markerLength += 1
                } else {
                    break
                }
            }
            if markerLength < nsBlockText.length && nsBlockText.character(at: markerLength) == (".").utf16.first! {
                markerLength += 1
            }
        }
        // Include trailing space after marker
        if markerLength < nsBlockText.length && nsBlockText.character(at: markerLength) == (" ").utf16.first! {
            markerLength += 1
        }

        if markerLength > 0 {
            let markerRange = NSRange(location: range.location, length: markerLength)
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: markerRange)
        }

        applyInlineRuns(block, range: range, to: textStorage,
                        fullSource: fullSource, settings: settings, appearance: appearance)
    }

    // MARK: - Inline Runs

    private func applyInlineRuns(
        _ block: EditorNode,
        range: NSRange,
        to textStorage: NSTextStorage,
        fullSource: String,
        settings: EditorSettings,
        appearance: Appearance,
        baseFont: NSFont? = nil
    ) {
        let font = baseFont ?? self.baseFont(settings: settings)

        for run in block.inlineRuns {
            // run.range is relative to block.sourceText
            let blockText = block.sourceText
            guard run.range.lowerBound >= blockText.startIndex,
                  run.range.upperBound <= blockText.endIndex else { continue }

            // Convert to fullSource-relative range
            let runInBlockNS = NSRange(run.range, in: blockText)
            guard runInBlockNS.location != NSNotFound else { continue }

            let runRange = NSRange(location: range.location + runInBlockNS.location,
                                   length: runInBlockNS.length)
            guard runRange.location + runRange.length <= (textStorage.string as NSString).length else { continue }

            applyInlineStyle(run.type, range: runRange, to: textStorage,
                             settings: settings, appearance: appearance, baseFont: font)
        }
    }

    private func applyInlineStyle(
        _ type: InlineType,
        range: NSRange,
        to textStorage: NSTextStorage,
        settings: EditorSettings,
        appearance: Appearance,
        baseFont: NSFont
    ) {
        switch type {
        case .bold:
            let boldFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
            textStorage.addAttribute(.font, value: boldFont, range: range)
            colorOuterDelimiters(in: textStorage, range: range, delimiter: "**",
                                 color: NSColor.secondaryLabelColor)

        case .italic:
            let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
            textStorage.addAttribute(.font, value: italicFont, range: range)
            colorOuterDelimiters(in: textStorage, range: range, delimiter: "*",
                                 color: NSColor.secondaryLabelColor)

        case .boldItalic:
            var boldItalicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
            boldItalicFont = NSFontManager.shared.convert(boldItalicFont, toHaveTrait: .italicFontMask)
            textStorage.addAttribute(.font, value: boldItalicFont, range: range)
            colorOuterDelimiters(in: textStorage, range: range, delimiter: "***",
                                 color: NSColor.secondaryLabelColor)

        case .strikethrough:
            textStorage.addAttribute(.strikethroughStyle,
                                     value: NSUnderlineStyle.single.rawValue, range: range)
            colorOuterDelimiters(in: textStorage, range: range, delimiter: "~~",
                                 color: NSColor.secondaryLabelColor)

        case .inlineCode:
            let monoFont = monospacedFont(size: baseFont.pointSize)
            let bgColor = appearance == .dark
                ? NSColor.white.withAlphaComponent(0.08)
                : NSColor.black.withAlphaComponent(0.06)
            textStorage.addAttribute(.font, value: monoFont, range: range)
            textStorage.addAttribute(.backgroundColor, value: bgColor, range: range)
            colorOuterDelimiters(in: textStorage, range: range, delimiter: "`",
                                 color: NSColor.secondaryLabelColor)

        case .link:
            textStorage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: range)
            textStorage.addAttribute(.underlineStyle,
                                     value: NSUnderlineStyle.single.rawValue, range: range)

        case .image:
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)

        case .text, .lineBreak:
            break
        }
    }

    // MARK: - Delimiter Coloring

    /// Colors the leading and trailing delimiter characters of a run in the given color.
    private func colorOuterDelimiters(
        in textStorage: NSTextStorage,
        range: NSRange,
        delimiter: String,
        color: NSColor
    ) {
        let nsStorage = textStorage.string as NSString
        let delimLen = (delimiter as NSString).length
        guard range.length >= delimLen * 2 else { return }

        let runText = nsStorage.substring(with: range)
        guard runText.hasPrefix(delimiter) && runText.hasSuffix(delimiter) else { return }

        let leadingRange = NSRange(location: range.location, length: delimLen)
        let trailingRange = NSRange(location: range.location + range.length - delimLen, length: delimLen)

        textStorage.addAttribute(.foregroundColor, value: color, range: leadingRange)
        textStorage.addAttribute(.foregroundColor, value: color, range: trailingRange)
    }

    // MARK: - Font & Style Helpers

    private func baseFont(settings: EditorSettings) -> NSFont {
        if let font = NSFont(name: settings.fontFamily, size: settings.fontSize) {
            return font
        }
        return NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
    }

    private func monospacedFont(size: CGFloat) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    private func baseParagraphStyle(settings: EditorSettings) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = settings.lineSpacing
        return style
    }

    private func primaryTextColor(appearance: Appearance) -> NSColor {
        NSColor.labelColor
    }
}

// MARK: - NSRange Helpers

private extension NSRange {
    /// Shifts the location of an `NSRange` by `offset`.
    func shifted(by offset: Int) -> NSRange {
        NSRange(location: location + offset, length: length)
    }
}
