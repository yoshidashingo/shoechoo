import AppKit

/// Applies syntax-highlighting attributes to an `NSTextStorage` WITHOUT changing text content.
/// All ranges are NSRange (UTF-16 offsets) — no String.Index involved.
@MainActor
struct SyntaxHighlighter {

    func apply(
        to textStorage: NSTextStorage,
        blocks: [EditorNode],
        settings: EditorSettings,
        theme: EditorTheme
    ) {
        let totalLength = textStorage.length
        guard totalLength > 0 else { return }

        let baseFont = self.baseFont(settings: settings)
        let baseColor: NSColor = theme.textColor.nsColor
        let paraStyle = baseParagraphStyle(settings: settings)

        textStorage.beginEditing()

        // Reset all attributes
        let fullRange = NSRange(location: 0, length: totalLength)
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: baseColor,
            .paragraphStyle: paraStyle,
        ], range: fullRange)

        for block in blocks {
            applyBlock(block, to: textStorage, totalLength: totalLength,
                       baseFont: baseFont, settings: settings, theme: theme)
        }

        textStorage.endEditing()
    }

    // MARK: - Block

    private func applyBlock(
        _ block: EditorNode,
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
            applyHeading(block, level: level, to: ts, baseFont: baseFont, settings: settings, theme: theme)
        case .codeBlock:
            applyCodeBlock(r, to: ts, settings: settings, theme: theme)
        case .blockquote:
            applyBlockquote(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        case .unorderedList, .orderedList:
            for child in block.children {
                applyBlock(child, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
            }
        case .listItem:
            applyListMarker(block, to: ts, theme: theme)
            applyInlines(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        case .taskListItem:
            applyListMarker(block, to: ts, theme: theme)
            applyInlines(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        case .horizontalRule:
            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: r)
            ts.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: r)
            ts.addAttribute(.strikethroughColor, value: theme.delimiterColor.nsColor, range: r)
        case .paragraph:
            applyInlines(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        case .image:
            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: r)
        case .table, .tableRow:
            break
        }
    }

    // MARK: - Heading

    private func applyHeading(_ block: EditorNode, level: Int, to ts: NSTextStorage, baseFont: NSFont, settings: EditorSettings, theme: EditorTheme) {
        let r = block.sourceRange
        let fontSize: CGFloat = switch level {
        case 1: 28; case 2: 24; case 3: 20; case 4: 18; case 5: 16
        default: settings.fontSize
        }
        let headingFont = NSFont.boldSystemFont(ofSize: fontSize)
        ts.addAttribute(.font, value: headingFont, range: r)
        let headingColor = theme.headingColor(for: level).nsColor
        ts.addAttribute(.foregroundColor, value: headingColor, range: r)
        ts.addAttribute(.paragraphStyle, value: headingParagraphStyle(settings: settings), range: r)

        // Color # prefix
        let nsText = block.sourceText as NSString
        var prefixLen = 0
        while prefixLen < nsText.length && nsText.character(at: prefixLen) == 0x23 /* # */ {
            prefixLen += 1
        }
        if prefixLen < nsText.length && nsText.character(at: prefixLen) == 0x20 /* space */ {
            prefixLen += 1
        }
        if prefixLen > 0 {
            let fadedDelim = theme.delimiterColor.nsColor.withAlphaComponent(0.35)
            ts.addAttribute(.foregroundColor, value: fadedDelim,
                            range: NSRange(location: r.location, length: prefixLen))
        }

        applyInlines(block, to: ts, totalLength: ts.length, baseFont: headingFont, settings: settings, theme: theme)
    }

    // MARK: - Code Block

    private func applyCodeBlock(_ r: NSRange, to ts: NSTextStorage, settings: EditorSettings, theme: EditorTheme) {
        let mono = NSFont(name: theme.codeFontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        ts.addAttribute(.font, value: mono, range: r)
        let bg = theme.codeBackgroundColor.nsColor
        ts.addAttribute(.backgroundColor, value: bg, range: r)

        // Color ``` fence lines
        let blockText = (ts.string as NSString).substring(with: r) as NSString
        var offset = 0
        for line in (blockText as String).components(separatedBy: "\n") {
            let lineLen = (line as NSString).length
            if line.hasPrefix("```") {
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor,
                                range: NSRange(location: r.location + offset, length: lineLen))
            }
            offset += lineLen + 1
        }
    }

    // MARK: - Blockquote

    private func applyBlockquote(_ block: EditorNode, to ts: NSTextStorage, totalLength: Int, baseFont: NSFont, settings: EditorSettings, theme: EditorTheme) {
        let r = block.sourceRange
        ts.addAttribute(.foregroundColor, value: theme.blockquoteColor.nsColor, range: r)

        // Color > markers with blockquoteMarkerColor
        let blockText = block.sourceText as NSString
        var offset = 0
        for line in (blockText as String).components(separatedBy: "\n") {
            let lineLen = (line as NSString).length
            var markerEnd = 0
            while markerEnd < lineLen && (line as NSString).character(at: markerEnd) == 0x3E /* > */ {
                markerEnd += 1
            }
            if markerEnd < lineLen && (line as NSString).character(at: markerEnd) == 0x20 {
                markerEnd += 1
            }
            if markerEnd > 0 {
                ts.addAttribute(.foregroundColor, value: theme.blockquoteMarkerColor.nsColor,
                                range: NSRange(location: r.location + offset, length: markerEnd))
            }
            offset += lineLen + 1
        }

        for child in block.children {
            applyBlock(child, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, theme: theme)
        }
    }

    // MARK: - List Marker

    private func applyListMarker(_ block: EditorNode, to ts: NSTextStorage, theme: EditorTheme) {
        let nsText = block.sourceText as NSString
        var i = 0
        // Skip leading whitespace
        while i < nsText.length && (nsText.character(at: i) == 0x20 || nsText.character(at: i) == 0x09) { i += 1 }
        // Find marker end
        let afterWS = i
        let ch = i < nsText.length ? nsText.character(at: i) : 0
        if ch == 0x2D || ch == 0x2A || ch == 0x2B { // - * +
            i += 1
            // task list: - [ ] or - [x]  — use NSString API only to avoid UTF-16/Swift index mismatch
            if i + 2 < nsText.length && nsText.character(at: i) == 0x20 && nsText.character(at: i+1) == 0x5B {
                let searchRange = NSRange(location: i, length: min(5, nsText.length - i))
                let found = nsText.range(of: "] ", range: searchRange)
                if found.location != NSNotFound {
                    i = found.location + found.length
                }
            }
        } else if ch >= 0x30 && ch <= 0x39 { // digit
            while i < nsText.length && nsText.character(at: i) >= 0x30 && nsText.character(at: i) <= 0x39 { i += 1 }
            if i < nsText.length && nsText.character(at: i) == 0x2E { i += 1 } // .
        }
        // trailing space
        if i < nsText.length && nsText.character(at: i) == 0x20 { i += 1 }
        if i > afterWS && i <= nsText.length {
            let markerRange = NSRange(location: block.sourceRange.location, length: i)
            guard markerRange.location + markerRange.length <= ts.length else { return }
            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: markerRange)
        }
    }

    // MARK: - Inlines

    private func applyInlines(
        _ block: EditorNode,
        to ts: NSTextStorage,
        totalLength: Int,
        baseFont: NSFont,
        settings: EditorSettings,
        theme: EditorTheme
    ) {
        for run in block.inlineRuns {
            // run.range is relative to block.sourceText; convert to absolute
            let absRange = NSRange(location: block.sourceRange.location + run.range.location,
                                   length: run.range.length)
            guard absRange.location >= 0, absRange.location + absRange.length <= totalLength else { continue }

            switch run.type {
            case .bold:
                ts.addAttribute(.font, value: NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask), range: absRange)
                colorDelimiters("**", range: absRange, in: ts, theme: theme)
            case .italic:
                ts.addAttribute(.font, value: NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask), range: absRange)
                colorDelimiters("*", range: absRange, in: ts, theme: theme)
            case .boldItalic:
                let bold = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                ts.addAttribute(.font, value: NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask), range: absRange)
                colorDelimiters("***", range: absRange, in: ts, theme: theme)
            case .strikethrough:
                ts.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: absRange)
                colorDelimiters("~~", range: absRange, in: ts, theme: theme)
            case .inlineCode:
                let mono = NSFont(name: theme.codeFontFamily, size: baseFont.pointSize)
                    ?? NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
                ts.addAttribute(.font, value: mono, range: absRange)
                let bg = theme.codeBackgroundColor.nsColor
                ts.addAttribute(.backgroundColor, value: bg, range: absRange)
                colorDelimiters("`", range: absRange, in: ts, theme: theme)
            case .link:
                applyLinkStyle(range: absRange, in: ts, theme: theme)
            case .image:
                ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor, range: absRange)
            case .text, .lineBreak:
                break
            }
        }
    }

    /// Style links: link text in link color with underline, brackets and URL in delimiter color.
    private func applyLinkStyle(range: NSRange, in ts: NSTextStorage, theme: EditorTheme) {
        let text = (ts.string as NSString).substring(with: range)
        let nsText = text as NSString

        // Find [text](url) structure
        let bracketClose = nsText.range(of: "](")
        if bracketClose.location != NSNotFound && nsText.hasSuffix(")") {
            // [text] part — color link text only (skip [ and ])
            let textStart = range.location + 1  // skip [
            let textLen = bracketClose.location - 1  // length of text
            if textLen > 0 {
                let textRange = NSRange(location: textStart, length: textLen)
                ts.addAttribute(.foregroundColor, value: theme.linkColor.nsColor, range: textRange)
                ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: textRange)
            }
            // [ bracket
            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor,
                            range: NSRange(location: range.location, length: 1))
            // ](url) part — all delimiter color
            let urlPartStart = range.location + bracketClose.location
            let urlPartLen = range.length - bracketClose.location
            ts.addAttribute(.foregroundColor, value: theme.delimiterColor.nsColor,
                            range: NSRange(location: urlPartStart, length: urlPartLen))
        } else {
            // Fallback: color entire range as link
            ts.addAttribute(.foregroundColor, value: theme.linkColor.nsColor, range: range)
            ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
    }

    private func colorDelimiters(_ delimiter: String, range: NSRange, in ts: NSTextStorage, theme: EditorTheme) {
        let dLen = (delimiter as NSString).length
        guard range.length >= dLen * 2 else { return }
        let text = (ts.string as NSString).substring(with: range)
        guard text.hasPrefix(delimiter), text.hasSuffix(delimiter) else { return }
        // Use delimiter color with reduced alpha to make markers fade into background (Bear-style)
        let fadedColor = theme.delimiterColor.nsColor.withAlphaComponent(0.4)
        ts.addAttribute(.foregroundColor, value: fadedColor,
                        range: NSRange(location: range.location, length: dLen))
        ts.addAttribute(.foregroundColor, value: fadedColor,
                        range: NSRange(location: range.location + range.length - dLen, length: dLen))
    }

    // MARK: - Helpers

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
