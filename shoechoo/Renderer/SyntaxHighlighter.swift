import AppKit

/// Applies syntax-highlighting attributes to an `NSTextStorage` WITHOUT changing text content.
/// All ranges are NSRange (UTF-16 offsets) — no String.Index involved.
@MainActor
struct SyntaxHighlighter {

    enum Appearance: Sendable {
        case light, dark
    }

    func apply(
        to textStorage: NSTextStorage,
        blocks: [EditorNode],
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let totalLength = textStorage.length
        guard totalLength > 0 else { return }

        let baseFont = self.baseFont(settings: settings)
        let baseColor: NSColor = appearance == .dark ? .white : .black
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
                       baseFont: baseFont, settings: settings, appearance: appearance)
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
        appearance: Appearance
    ) {
        let r = block.sourceRange
        guard r.location >= 0, r.location + r.length <= totalLength else { return }

        switch block.kind {
        case .heading(let level):
            applyHeading(block, level: level, to: ts, baseFont: baseFont, settings: settings, appearance: appearance)
        case .codeBlock:
            applyCodeBlock(r, to: ts, settings: settings, appearance: appearance)
        case .blockquote:
            applyBlockquote(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, appearance: appearance)
        case .unorderedList, .orderedList:
            for child in block.children {
                applyBlock(child, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, appearance: appearance)
            }
        case .listItem:
            applyListMarker(block, to: ts)
            applyInlines(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, appearance: appearance)
        case .taskListItem:
            applyListMarker(block, to: ts)
            applyInlines(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, appearance: appearance)
        case .horizontalRule:
            ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: r)
        case .paragraph:
            applyInlines(block, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, appearance: appearance)
        case .image:
            ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: r)
        case .table, .tableRow:
            break
        }
    }

    // MARK: - Heading

    private func applyHeading(_ block: EditorNode, level: Int, to ts: NSTextStorage, baseFont: NSFont, settings: EditorSettings, appearance: Appearance) {
        let r = block.sourceRange
        let fontSize: CGFloat = switch level {
        case 1: 28; case 2: 24; case 3: 20; case 4: 18; case 5: 16
        default: settings.fontSize
        }
        let headingFont = NSFont.boldSystemFont(ofSize: fontSize)
        let headingColor: NSColor = appearance == .dark ? .white : .black
        ts.addAttribute(.font, value: headingFont, range: r)
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
            ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor,
                            range: NSRange(location: r.location, length: prefixLen))
        }

        applyInlines(block, to: ts, totalLength: ts.length, baseFont: headingFont, settings: settings, appearance: appearance)
    }

    // MARK: - Code Block

    private func applyCodeBlock(_ r: NSRange, to ts: NSTextStorage, settings: EditorSettings, appearance: Appearance) {
        let mono = NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        ts.addAttribute(.font, value: mono, range: r)
        let bg = appearance == .dark
            ? NSColor.white.withAlphaComponent(0.06)
            : NSColor.black.withAlphaComponent(0.04)
        ts.addAttribute(.backgroundColor, value: bg, range: r)

        // Color ``` fence lines
        let blockText = (ts.string as NSString).substring(with: r) as NSString
        var offset = 0
        for line in (blockText as String).components(separatedBy: "\n") {
            let lineLen = (line as NSString).length
            if line.hasPrefix("```") {
                ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor,
                                range: NSRange(location: r.location + offset, length: lineLen))
            }
            offset += lineLen + 1
        }
    }

    // MARK: - Blockquote

    private func applyBlockquote(_ block: EditorNode, to ts: NSTextStorage, totalLength: Int, baseFont: NSFont, settings: EditorSettings, appearance: Appearance) {
        let r = block.sourceRange
        ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: r)

        // Color > markers green
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
                ts.addAttribute(.foregroundColor, value: NSColor.systemGreen,
                                range: NSRange(location: r.location + offset, length: markerEnd))
            }
            offset += lineLen + 1
        }

        for child in block.children {
            applyBlock(child, to: ts, totalLength: totalLength, baseFont: baseFont, settings: settings, appearance: appearance)
        }
    }

    // MARK: - List Marker

    private func applyListMarker(_ block: EditorNode, to ts: NSTextStorage) {
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
            ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: markerRange)
        }
    }

    // MARK: - Inlines

    private func applyInlines(
        _ block: EditorNode,
        to ts: NSTextStorage,
        totalLength: Int,
        baseFont: NSFont,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        for run in block.inlineRuns {
            // run.range is relative to block.sourceText; convert to absolute
            let absRange = NSRange(location: block.sourceRange.location + run.range.location,
                                   length: run.range.length)
            guard absRange.location >= 0, absRange.location + absRange.length <= totalLength else { continue }

            switch run.type {
            case .bold:
                ts.addAttribute(.font, value: NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask), range: absRange)
                colorDelimiters("**", range: absRange, in: ts)
            case .italic:
                ts.addAttribute(.font, value: NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask), range: absRange)
                colorDelimiters("*", range: absRange, in: ts)
            case .boldItalic:
                let bold = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                ts.addAttribute(.font, value: NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask), range: absRange)
                colorDelimiters("***", range: absRange, in: ts)
            case .strikethrough:
                ts.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: absRange)
                colorDelimiters("~~", range: absRange, in: ts)
            case .inlineCode:
                let mono = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
                ts.addAttribute(.font, value: mono, range: absRange)
                let bg = appearance == .dark ? NSColor.white.withAlphaComponent(0.08) : NSColor.black.withAlphaComponent(0.06)
                ts.addAttribute(.backgroundColor, value: bg, range: absRange)
                colorDelimiters("`", range: absRange, in: ts)
            case .link:
                ts.addAttribute(.foregroundColor, value: NSColor.linkColor, range: absRange)
                ts.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: absRange)
            case .image:
                ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: absRange)
            case .text, .lineBreak:
                break
            }
        }
    }

    private func colorDelimiters(_ delimiter: String, range: NSRange, in ts: NSTextStorage) {
        let dLen = (delimiter as NSString).length
        guard range.length >= dLen * 2 else { return }
        let text = (ts.string as NSString).substring(with: range)
        guard text.hasPrefix(delimiter), text.hasSuffix(delimiter) else { return }
        ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor,
                        range: NSRange(location: range.location, length: dLen))
        ts.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor,
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
