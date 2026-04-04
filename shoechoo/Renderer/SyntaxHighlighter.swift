import AppKit

/// WYSIWYG syntax highlighter: inactive blocks hide delimiters, active block shows raw markdown.
/// Text content is never modified — only attributes (font, color, size) are changed.
@MainActor
struct SyntaxHighlighter {

    /// The tiny font used to visually hide delimiter characters in inactive blocks.
    private static let hiddenFont = NSFont.systemFont(ofSize: 0.01)

    func apply(
        to textStorage: NSTextStorage,
        blocks: [EditorNode],
        activeBlockID: EditorNode.ID?,
        settings: EditorSettings,
        theme: EditorTheme
    ) {
        let totalLength = textStorage.length
        guard totalLength > 0 else { return }

        let baseFont = self.baseFont(settings: settings)
        let baseColor = theme.textColor.nsColor
        let paraStyle = baseParagraphStyle(settings: settings)

        textStorage.beginEditing()

        let fullRange = NSRange(location: 0, length: totalLength)
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: baseColor,
            .paragraphStyle: paraStyle,
        ], range: fullRange)

        var activeCount = 0
        var inactiveCount = 0
        for block in blocks {
            let isActive = block.id == activeBlockID
            if isActive { activeCount += 1 } else { inactiveCount += 1 }
            applyBlock(block, isActive: isActive, activeBlockID: activeBlockID,
                       to: textStorage, totalLength: totalLength,
                       baseFont: baseFont, settings: settings, theme: theme)
        }
        // Logging removed

        textStorage.endEditing()
    }

    // MARK: - Block Dispatch

    private func applyBlock(
        _ block: EditorNode,
        isActive: Bool,
        activeBlockID: EditorNode.ID?,
        to ts: NSTextStorage,
        totalLength: Int,
        baseFont: NSFont,
        settings: EditorSettings,
        theme: EditorTheme
    ) {
        let r = block.sourceRange
        guard r.location >= 0, r.location + r.length <= totalLength else { return }

        switch block.kind {
        case .heading(let level):
            applyHeading(block, level: level, isActive: isActive, to: ts,
                         baseFont: baseFont, settings: settings, theme: theme)
        case .codeBlock:
            applyCodeBlock(block, isActive: isActive, to: ts, settings: settings, theme: theme)
        case .blockquote:
            applyBlockquote(block, isActive: isActive, activeBlockID: activeBlockID, to: ts,
                            totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        case .unorderedList, .orderedList:
            for child in block.children {
                let childActive = child.id == activeBlockID
                applyBlock(child, isActive: childActive, activeBlockID: activeBlockID,
                           to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
            }
        case .listItem, .taskListItem:
            applyListItem(block, isActive: isActive, to: ts, totalLength: totalLength,
                          baseFont: baseFont, settings: settings, theme: theme)
        case .horizontalRule:
            applyHorizontalRule(block, isActive: isActive, to: ts, theme: theme)
        case .paragraph:
            applyInlines(block, isActive: isActive, to: ts, totalLength: totalLength,
                         baseFont: baseFont, settings: settings, theme: theme)
        case .image:
            applyImage(block, isActive: isActive, to: ts, theme: theme)
        case .table:
            applyTable(block, isActive: isActive, activeBlockID: activeBlockID, to: ts,
                       totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        case .tableRow:
            break
        }
    }

    // MARK: - Heading

    private func applyHeading(
        _ block: EditorNode, level: Int, isActive: Bool,
        to ts: NSTextStorage, baseFont: NSFont, settings: EditorSettings, theme: EditorTheme
    ) {
        let r = block.sourceRange
        let fontSize: CGFloat = switch level {
        case 1: 28; case 2: 24; case 3: 20; case 4: 18; case 5: 16
        default: settings.fontSize
        }
        let headingFont = NSFont.boldSystemFont(ofSize: fontSize)
        ts.addAttribute(.font, value: headingFont, range: r)
        ts.addAttribute(.foregroundColor, value: theme.headingColor(for: level).nsColor, range: r)
        ts.addAttribute(.paragraphStyle, value: headingParagraphStyle(settings: settings), range: r)

        // # prefix
        let nsText = block.sourceText as NSString
        var prefixLen = 0
        while prefixLen < nsText.length && nsText.character(at: prefixLen) == 0x23 { prefixLen += 1 }
        if prefixLen < nsText.length && nsText.character(at: prefixLen) == 0x20 { prefixLen += 1 }

        if prefixLen > 0 {
            let prefixRange = NSRange(location: r.location, length: prefixLen)
            if isActive {
                // Show # in delimiter color
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: prefixRange)
            } else {
                // Hide # by making it invisible
                hideRange(prefixRange, in: ts, bgColor: theme.backgroundColor.nsColor)
            }
        }

        applyInlines(block, isActive: isActive, to: ts, totalLength: ts.length,
                     baseFont: headingFont, settings: settings, theme: theme)
    }

    // MARK: - Code Block

    private func applyCodeBlock(
        _ block: EditorNode, isActive: Bool,
        to ts: NSTextStorage, settings: EditorSettings, theme: EditorTheme
    ) {
        let r = block.sourceRange
        let mono = NSFont(name: theme.codeFontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        ts.addAttribute(.font, value: mono, range: r)
        ts.addAttribute(.backgroundColor, value: theme.codeBackgroundColor.nsColor, range: r)

        // Fence lines
        let blockText = (ts.string as NSString).substring(with: r) as NSString
        var offset = 0
        for line in (blockText as String).components(separatedBy: "\n") {
            let lineLen = (line as NSString).length
            if line.hasPrefix("```") {
                let fenceRange = NSRange(location: r.location + offset, length: lineLen)
                if isActive {
                    ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: fenceRange)
                } else {
                    hideRange(fenceRange, in: ts, bgColor: theme.codeBackgroundColor.nsColor)
                }
            }
            offset += lineLen + 1
        }
    }

    // MARK: - Blockquote

    private func applyBlockquote(
        _ block: EditorNode, isActive: Bool, activeBlockID: EditorNode.ID?,
        to ts: NSTextStorage, totalLength: Int, baseFont: NSFont,
        settings: EditorSettings, theme: EditorTheme
    ) {
        let r = block.sourceRange
        ts.addAttribute(.foregroundColor, value: theme.blockquoteColor.nsColor, range: r)
        // Indent blockquote text
        let quoteStyle = NSMutableParagraphStyle()
        quoteStyle.lineSpacing = settings.lineSpacing
        quoteStyle.headIndent = 20
        quoteStyle.firstLineHeadIndent = isActive ? 0 : 20
        quoteStyle.paragraphSpacing = settings.fontSize * 0.3
        ts.addAttribute(.paragraphStyle, value: quoteStyle, range: r)
        // Italic for blockquote content
        if !isActive {
            let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
            ts.addAttribute(.font, value: italicFont, range: r)
        }

        let blockText = block.sourceText as NSString
        var offset = 0
        for line in (blockText as String).components(separatedBy: "\n") {
            let lineLen = (line as NSString).length
            var markerEnd = 0
            while markerEnd < lineLen && (line as NSString).character(at: markerEnd) == 0x3E { markerEnd += 1 }
            if markerEnd < lineLen && (line as NSString).character(at: markerEnd) == 0x20 { markerEnd += 1 }
            if markerEnd > 0 {
                let markerRange = NSRange(location: r.location + offset, length: markerEnd)
                if isActive {
                    ts.addAttribute(.foregroundColor, value: theme.blockquoteMarkerColor.nsColor, range: markerRange)
                } else {
                    hideRange(markerRange, in: ts, bgColor: theme.backgroundColor.nsColor)
                }
            }
            offset += lineLen + 1
        }

        for child in block.children {
            let childActive = child.id == activeBlockID
            applyBlock(child, isActive: childActive, activeBlockID: activeBlockID,
                       to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        }
    }

    // MARK: - List Item

    private func applyListItem(
        _ block: EditorNode, isActive: Bool,
        to ts: NSTextStorage, totalLength: Int, baseFont: NSFont,
        settings: EditorSettings, theme: EditorTheme
    ) {
        let nsText = block.sourceText as NSString
        var i = 0
        while i < nsText.length && (nsText.character(at: i) == 0x20 || nsText.character(at: i) == 0x09) { i += 1 }
        let afterWS = i
        let ch = i < nsText.length ? nsText.character(at: i) : 0
        if ch == 0x2D || ch == 0x2A || ch == 0x2B {
            i += 1
            let blockStr = nsText as String
            if i + 2 < nsText.length && nsText.character(at: i) == 0x20 && nsText.character(at: i+1) == 0x5B {
                let searchRange = NSRange(location: i, length: min(5, nsText.length - i))
                if let swiftRange = Range(searchRange, in: blockStr),
                   let closeBracket = blockStr.range(of: "] ", range: swiftRange) {
                    i = blockStr[blockStr.startIndex..<closeBracket.upperBound].utf16.count
                }
            }
        } else if ch >= 0x30 && ch <= 0x39 {
            while i < nsText.length && nsText.character(at: i) >= 0x30 && nsText.character(at: i) <= 0x39 { i += 1 }
            if i < nsText.length && nsText.character(at: i) == 0x2E { i += 1 }
        }
        if i < nsText.length && nsText.character(at: i) == 0x20 { i += 1 }

        if i > afterWS && i <= nsText.length {
            let markerRange = NSRange(location: block.sourceRange.location, length: i)
            guard markerRange.location + markerRange.length <= ts.length else { return }
            if isActive {
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: markerRange)
            } else {
                // Hide the marker when inactive (#45)
                hideRange(markerRange, in: ts, bgColor: theme.backgroundColor.nsColor)
            }
        }

        applyInlines(block, isActive: isActive, to: ts, totalLength: totalLength,
                     baseFont: baseFont, settings: settings, theme: theme)
    }

    // MARK: - Inlines

    private func applyInlines(
        _ block: EditorNode, isActive: Bool,
        to ts: NSTextStorage, totalLength: Int, baseFont: NSFont,
        settings: EditorSettings, theme: EditorTheme
    ) {
        for run in block.inlineRuns {
            let absRange = NSRange(location: block.sourceRange.location + run.range.location,
                                   length: run.range.length)
            guard absRange.location >= 0, absRange.location + absRange.length <= totalLength else { continue }

            switch run.type {
            case .bold:
                ts.addAttribute(.font, value: NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask), range: absRange)
                handleDelimiters("**", range: absRange, isActive: isActive, in: ts, theme: theme)
            case .italic:
                ts.addAttribute(.font, value: NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask), range: absRange)
                handleDelimiters("*", range: absRange, isActive: isActive, in: ts, theme: theme)
            case .boldItalic:
                let bold = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                ts.addAttribute(.font, value: NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask), range: absRange)
                handleDelimiters("***", range: absRange, isActive: isActive, in: ts, theme: theme)
            case .strikethrough:
                ts.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: absRange)
                handleDelimiters("~~", range: absRange, isActive: isActive, in: ts, theme: theme)
            case .inlineCode:
                let mono = NSFont(name: theme.codeFontFamily, size: baseFont.pointSize)
                    ?? NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
                ts.addAttribute(.font, value: mono, range: absRange)
                ts.addAttribute(.backgroundColor, value: theme.codeBackgroundColor.nsColor, range: absRange)
                handleDelimiters("`", range: absRange, isActive: isActive, in: ts, theme: theme)
            case .link:
                applyLinkStyle(range: absRange, isActive: isActive, in: ts, theme: theme)
            case .image:
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: absRange)
            case .text, .lineBreak:
                break
            }
        }
    }

    // MARK: - Delimiter Handling

    /// Active: show delimiters in dim color. Inactive: hide delimiters (tiny font + bg color).
    private func handleDelimiters(
        _ delimiter: String, range: NSRange, isActive: Bool,
        in ts: NSTextStorage, theme: EditorTheme
    ) {
        let dLen = (delimiter as NSString).length
        guard range.length >= dLen * 2 else { return }
        let text = (ts.string as NSString).substring(with: range)
        guard text.hasPrefix(delimiter), text.hasSuffix(delimiter) else { return }

        let leadRange = NSRange(location: range.location, length: dLen)
        let trailRange = NSRange(location: range.location + range.length - dLen, length: dLen)

        if isActive {
            let dimColor = theme.delimiterColor.nsColor
            ts.addAttribute(.foregroundColor, value: dimColor, range: leadRange)
            ts.addAttribute(.foregroundColor, value: dimColor, range: trailRange)
        } else {
            hideRange(leadRange, in: ts, bgColor: theme.backgroundColor.nsColor)
            hideRange(trailRange, in: ts, bgColor: theme.backgroundColor.nsColor)
        }
    }

    /// Link: active shows full [text](url), inactive shows underlined text only.
    private func applyLinkStyle(range: NSRange, isActive: Bool, in ts: NSTextStorage, theme: EditorTheme) {
        let text = (ts.string as NSString).substring(with: range)
        let nsText = text as NSString

        let bracketClose = nsText.range(of: "](")
        if bracketClose.location != NSNotFound && nsText.hasSuffix(")") {
            let textStart = range.location + 1
            let textLen = bracketClose.location - 1
            if textLen > 0 {
                let textRange = NSRange(location: textStart, length: textLen)
                ts.addAttribute(.foregroundColor, value: theme.linkColor.nsColor, range: textRange)
                if !isActive {
                    ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
                }
            }

            let openBracket = NSRange(location: range.location, length: 1)
            let urlPart = NSRange(location: range.location + bracketClose.location,
                                  length: range.length - bracketClose.location)

            if isActive {
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: openBracket)
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: urlPart)
            } else {
                hideRange(openBracket, in: ts, bgColor: theme.backgroundColor.nsColor)
                hideRange(urlPart, in: ts, bgColor: theme.backgroundColor.nsColor)
            }
        } else {
            ts.addAttribute(.foregroundColor, value: theme.linkColor.nsColor, range: range)
            ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    // MARK: - Horizontal Rule

    private func applyHorizontalRule(
        _ block: EditorNode, isActive: Bool,
        to ts: NSTextStorage, theme: EditorTheme
    ) {
        let r = block.sourceRange
        if isActive {
            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: r)
        } else {
            // Hide the --- text and show a strikethrough line (#48)
            hideRange(r, in: ts, bgColor: theme.backgroundColor.nsColor)
            ts.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.thick.rawValue, range: r)
            ts.addAttribute(.strikethroughColor, value: theme.delimiterColor.nsColor, range: r)
        }
    }

    // MARK: - Image

    private func applyImage(
        _ block: EditorNode, isActive: Bool,
        to ts: NSTextStorage, theme: EditorTheme
    ) {
        let r = block.sourceRange
        if isActive {
            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: r)
        } else {
            // Hide ![]() syntax, show alt text only
            let nsText = block.sourceText as NSString
            // Find ![alt](url) structure
            let altClose = nsText.range(of: "](")
            if altClose.location != NSNotFound && nsText.length >= 4 {
                // Hide "!["
                hideRange(NSRange(location: r.location, length: 2), in: ts, bgColor: theme.backgroundColor.nsColor)
                // Alt text visible (between ![ and ])
                let altStart = r.location + 2
                let altLen = altClose.location - 2
                if altLen > 0 {
                    ts.addAttribute(.foregroundColor, value: theme.textColor.nsColor,
                                    range: NSRange(location: altStart, length: altLen))
                }
                // Hide "](url)"
                let urlPartStart = r.location + altClose.location
                let urlPartLen = r.length - altClose.location
                hideRange(NSRange(location: urlPartStart, length: urlPartLen), in: ts, bgColor: theme.backgroundColor.nsColor)
            } else {
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: r)
            }
        }
    }

    // MARK: - Table

    private func applyTable(
        _ block: EditorNode, isActive: Bool, activeBlockID: EditorNode.ID?,
        to ts: NSTextStorage, totalLength: Int, baseFont: NSFont,
        settings: EditorSettings, theme: EditorTheme
    ) {
        let r = block.sourceRange
        let blockText = block.sourceText as NSString

        // Apply monospace font for alignment
        let mono = NSFont(name: theme.codeFontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        ts.addAttribute(.font, value: mono, range: r)

        if isActive || block.id == activeBlockID {
            // Active: show raw table with pipe delimiters in dim color
            var offset = 0
            for line in (blockText as String).components(separatedBy: "\n") {
                let lineLen = (line as NSString).length
                let lineRange = NSRange(location: r.location + offset, length: lineLen)
                guard lineRange.location + lineRange.length <= totalLength else { break }

                // Color | delimiters
                let nsLine = line as NSString
                for ci in 0..<nsLine.length {
                    if nsLine.character(at: ci) == 0x7C { // |
                        ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor,
                                        range: NSRange(location: lineRange.location + ci, length: 1))
                    }
                }
                offset += lineLen + 1
            }
        } else {
            // Inactive: hide separator rows, dim pipe delimiters
            var offset = 0
            for line in (blockText as String).components(separatedBy: "\n") {
                let lineLen = (line as NSString).length
                let lineRange = NSRange(location: r.location + offset, length: lineLen)
                guard lineRange.location + lineRange.length <= totalLength else { break }

                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let isSeparator = trimmed.allSatisfy({ $0 == "|" || $0 == "-" || $0 == ":" || $0 == " " })
                    && trimmed.contains("-")

                if isSeparator {
                    // Hide separator row completely
                    hideRange(lineRange, in: ts, bgColor: theme.backgroundColor.nsColor)
                } else {
                    // Dim pipe characters
                    let nsLine = line as NSString
                    for ci in 0..<nsLine.length {
                        if nsLine.character(at: ci) == 0x7C { // |
                            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor.withAlphaComponent(0.2),
                                            range: NSRange(location: lineRange.location + ci, length: 1))
                        }
                    }
                }
                offset += lineLen + 1
            }

            // Bold the header row (first child)
            if let header = block.children.first {
                let hr = header.sourceRange
                if hr.location >= 0 && hr.location + hr.length <= totalLength {
                    let boldMono = NSFontManager.shared.convert(mono, toHaveTrait: .boldFontMask)
                    ts.addAttribute(.font, value: boldMono, range: hr)
                }
            }
        }
    }

    // MARK: - Hide Range

    /// Makes characters at the given range visually invisible by setting font to 0.01pt
    /// and color to match the background.
    private func hideRange(_ range: NSRange, in ts: NSTextStorage, bgColor: NSColor) {
        ts.addAttribute(.font, value: Self.hiddenFont, range: range)
        ts.addAttribute(.foregroundColor, value: bgColor, range: range)
        ts.removeAttribute(.backgroundColor, range: range)
    }

    // MARK: - Font/Style Helpers

    private func baseFont(settings: EditorSettings) -> NSFont {
        NSFont(name: settings.fontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
    }

    private func baseParagraphStyle(settings: EditorSettings) -> NSMutableParagraphStyle {
        let s = NSMutableParagraphStyle()
        s.lineSpacing = settings.lineSpacing
        s.paragraphSpacing = settings.fontSize * 0.5
        return s
    }

    private func headingParagraphStyle(settings: EditorSettings) -> NSMutableParagraphStyle {
        let s = baseParagraphStyle(settings: settings)
        s.paragraphSpacingBefore = settings.fontSize * 0.75
        s.paragraphSpacing = settings.fontSize * 0.4
        return s
    }
}
