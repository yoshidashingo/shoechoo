import AppKit
import Highlightr

// MARK: - MarkdownRenderer

/// Converts `EditorNode` blocks into `NSAttributedString`.
///
/// Two rendering paths:
/// - **Inactive**: styled output (bold rendered, headings sized, syntax-highlighted code, etc.)
/// - **Active**: raw Markdown source with subtle syntax coloring for delimiters.
///
/// Non-Sendable because it holds `Highlightr?` and works with `NSAttributedString`.
@MainActor
struct MarkdownRenderer {

    // MARK: - Appearance

    enum Appearance: Sendable {
        case light, dark
    }

    // MARK: - Private State

    private let highlightr: Highlightr?

    // MARK: - Init

    init() {
        let hl = Highlightr()
        self.highlightr = hl
    }

    // MARK: - Public API

    func render(
        block: EditorNode,
        settings: EditorSettings,
        appearance: Appearance
    ) -> RenderResult {
        let attributed = renderInactive(block: block, settings: settings, appearance: appearance)
        return RenderResult(blockID: block.id, attributedString: attributed, isActive: false)
    }

    func renderActiveBlock(
        block: EditorNode,
        settings: EditorSettings,
        appearance: Appearance
    ) -> RenderResult {
        let attributed = renderActive(block: block, settings: settings, appearance: appearance)
        return RenderResult(blockID: block.id, attributedString: attributed, isActive: true)
    }

    // MARK: - Inactive (Styled) Rendering

    private func renderInactive(
        block: EditorNode,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        switch block.kind {
        case .heading(let level):
            return renderHeading(block: block, level: level, settings: settings, appearance: appearance)

        case .codeBlock(let language):
            return renderCodeBlock(block: block, language: language, settings: settings, appearance: appearance)

        case .unorderedList:
            return renderList(block: block, ordered: false, settings: settings, appearance: appearance)

        case .orderedList:
            return renderList(block: block, ordered: true, settings: settings, appearance: appearance)

        case .listItem:
            return renderInlineRuns(block: block, settings: settings, appearance: appearance)

        case .taskListItem(let isChecked):
            return renderTaskListItem(block: block, isChecked: isChecked, settings: settings, appearance: appearance)

        case .blockquote:
            return renderBlockquote(block: block, settings: settings, appearance: appearance)

        case .table:
            return renderTable(block: block, settings: settings, appearance: appearance)

        case .tableRow:
            return renderInlineRuns(block: block, settings: settings, appearance: appearance)

        case .horizontalRule:
            return renderHorizontalRule(settings: settings, appearance: appearance)

        case .image(_, let alt):
            return renderImagePlaceholder(alt: alt, settings: settings, appearance: appearance)

        case .paragraph:
            return renderInlineRuns(block: block, settings: settings, appearance: appearance)
        }
    }

    // MARK: Heading

    private func renderHeading(
        block: EditorNode,
        level: Int,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let fontSize = headingFontSize(level: level, base: settings.fontSize)
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let textColor = primaryTextColor(appearance: appearance)

        let result = NSMutableAttributedString()
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        if block.inlineRuns.isEmpty {
            // Strip leading # and space from sourceText
            let text = stripHeadingPrefix(block.sourceText)
            result.append(NSAttributedString(string: text, attributes: baseAttrs))
        } else {
            for run in block.inlineRuns {
                let runText = String(block.sourceText[run.range])
                var attrs = baseAttrs
                applyInlineStyle(run.type, attrs: &attrs, settings: settings, appearance: appearance, baseFont: font)
                result.append(NSAttributedString(string: strippedInlineText(runText, type: run.type), attributes: attrs))
            }
        }
        return result
    }

    private func headingFontSize(level: Int, base: CGFloat) -> CGFloat {
        switch level {
        case 1: return 28
        case 2: return 24
        case 3: return 20
        case 4: return 18
        case 5: return 16
        default: return base // h6 or fallback
        }
    }

    private func stripHeadingPrefix(_ text: String) -> String {
        var s = text
        while s.hasPrefix("#") { s.removeFirst() }
        if s.hasPrefix(" ") { s.removeFirst() }
        return s
    }

    // MARK: Code Block

    private func renderCodeBlock(
        block: EditorNode,
        language: String?,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Strip fences from source
        let code = stripCodeFences(block.sourceText)
        let monoFont = monospacedFont(size: settings.fontSize)
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let textColor = primaryTextColor(appearance: appearance)

        // Language label
        if let lang = language, !lang.isEmpty {
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: settings.fontSize * 0.85),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: paragraphStyle,
            ]
            result.append(NSAttributedString(string: lang + "\n", attributes: labelAttrs))
        }

        // Try syntax highlighting via Highlightr
        if let hl = highlightr,
           let lang = language, !lang.isEmpty {
            let theme = appearance == .dark ? "atom-one-dark" : "atom-one-light"
            hl.setTheme(to: theme)
            hl.theme.codeFont = monoFont

            if let highlighted = hl.highlight(code, as: lang) {
                // Apply paragraph style to entire range
                let mutable = NSMutableAttributedString(attributedString: highlighted)
                mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutable.length))
                result.append(mutable)
                return result
            }
        }

        // Fallback: plain monospace
        let fallbackAttrs: [NSAttributedString.Key: Any] = [
            .font: monoFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]
        result.append(NSAttributedString(string: code, attributes: fallbackAttrs))
        return result
    }

    private func stripCodeFences(_ text: String) -> String {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        // Remove opening fence
        if let first = lines.first, first.hasPrefix("```") {
            lines.removeFirst()
        }
        // Remove closing fence
        if let last = lines.last, last.trimmingCharacters(in: .whitespaces) == "```" {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Lists

    private func renderList(
        block: EditorNode,
        ordered: Bool,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        for (index, child) in block.children.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n"))
            }

            let prefix: String
            switch child.kind {
            case .taskListItem(let isChecked):
                prefix = isChecked ? "\u{2611} " : "\u{2610} "
            case .listItem(let marker):
                switch marker {
                case .bullet:
                    prefix = "\u{2022} "
                case .ordered(let start):
                    prefix = "\(start + index). "
                }
            default:
                prefix = ordered ? "\(index + 1). " : "\u{2022} "
            }

            let font = baseFont(settings: settings)
            let textColor = primaryTextColor(appearance: appearance)
            let paragraphStyle = listParagraphStyle(settings: settings)
            let prefixAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle,
            ]
            result.append(NSAttributedString(string: prefix, attributes: prefixAttrs))

            // Render child inline content
            let childContent = renderInlineRuns(block: child, settings: settings, appearance: appearance)
            result.append(childContent)
        }
        return result
    }

    // MARK: Task List Item

    private func renderTaskListItem(
        block: EditorNode,
        isChecked: Bool,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let prefix = isChecked ? "\u{2611} " : "\u{2610} "

        let font = baseFont(settings: settings)
        let textColor = primaryTextColor(appearance: appearance)
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]
        result.append(NSAttributedString(string: prefix, attributes: attrs))

        // Strip task marker from source and render remaining inline runs
        let content = renderInlineRuns(block: block, settings: settings, appearance: appearance)
        result.append(content)
        return result
    }

    // MARK: Blockquote

    private func renderBlockquote(
        block: EditorNode,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = settings.lineSpacing
        paragraphStyle.headIndent = 16
        paragraphStyle.firstLineHeadIndent = 16

        let font = baseFont(settings: settings)
        let textColor = NSColor.secondaryLabelColor

        if block.children.isEmpty {
            // Render source directly, stripping > prefix
            let text = stripBlockquotePrefix(block.sourceText)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle,
            ]
            result.append(NSAttributedString(string: text, attributes: attrs))
        } else {
            for (index, child) in block.children.enumerated() {
                if index > 0 {
                    result.append(NSAttributedString(string: "\n"))
                }
                let childResult = renderInactive(block: child, settings: settings, appearance: appearance)
                let mutable = NSMutableAttributedString(attributedString: childResult)
                mutable.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: mutable.length))
                mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: mutable.length))
                result.append(mutable)
            }
        }
        return result
    }

    private func stripBlockquotePrefix(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.map { line in
            var s = String(line)
            if s.hasPrefix("> ") { s = String(s.dropFirst(2)) }
            else if s.hasPrefix(">") { s = String(s.dropFirst(1)) }
            return s
        }.joined(separator: "\n")
    }

    // MARK: Table

    private func renderTable(
        block: EditorNode,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = baseFont(settings: settings)
        let textColor = primaryTextColor(appearance: appearance)
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        // Simplified MVP: clean up pipes, render rows separated by newlines
        let lines = block.sourceText.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            // Skip separator rows (e.g., |---|---|)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.allSatisfy({ $0 == "|" || $0 == "-" || $0 == ":" || $0 == " " }) && trimmed.contains("-") {
                continue
            }
            if index > 0 && result.length > 0 {
                result.append(NSAttributedString(string: "\n", attributes: attrs))
            }
            // Clean pipe syntax: trim leading/trailing pipes, replace inner pipes with tab
            var cleaned = trimmed
            if cleaned.hasPrefix("|") { cleaned = String(cleaned.dropFirst()) }
            if cleaned.hasSuffix("|") { cleaned = String(cleaned.dropLast()) }
            cleaned = cleaned.replacingOccurrences(of: "|", with: "\t")
            cleaned = cleaned.trimmingCharacters(in: CharacterSet.whitespaces)
            result.append(NSAttributedString(string: cleaned, attributes: attrs))
        }
        return result
    }

    // MARK: Horizontal Rule

    private func renderHorizontalRule(
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let ruleColor = appearance == .dark
            ? NSColor.separatorColor
            : NSColor.separatorColor
        // Render as a line of em dashes
        let attrs: [NSAttributedString.Key: Any] = [
            .font: baseFont(settings: settings),
            .foregroundColor: ruleColor,
            .paragraphStyle: paragraphStyle,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: ruleColor,
        ]
        return NSAttributedString(string: String(repeating: " ", count: 40), attributes: attrs)
    }

    // MARK: Image Placeholder

    private func renderImagePlaceholder(
        alt: String,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let font = baseFont(settings: settings)
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle,
        ]
        let label = alt.isEmpty ? "[Image]" : "[Image: \(alt)]"
        return NSAttributedString(string: label, attributes: attrs)
    }

    // MARK: Inline Runs

    private func renderInlineRuns(
        block: EditorNode,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = baseFont(settings: settings)
        let textColor = primaryTextColor(appearance: appearance)
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        guard !block.inlineRuns.isEmpty else {
            result.append(NSAttributedString(string: block.sourceText, attributes: baseAttrs))
            return result
        }

        for run in block.inlineRuns {
            let rawText = String(block.sourceText[run.range])
            let displayText = strippedInlineText(rawText, type: run.type)
            var attrs = baseAttrs
            applyInlineStyle(run.type, attrs: &attrs, settings: settings, appearance: appearance, baseFont: font)
            result.append(NSAttributedString(string: displayText, attributes: attrs))
        }
        return result
    }

    /// Strips Markdown delimiters for styled (inactive) display.
    private func strippedInlineText(_ text: String, type: InlineType) -> String {
        switch type {
        case .bold:
            return stripDelimiters(text, delimiter: "**")
        case .italic:
            return stripDelimiters(text, delimiter: "*")
        case .boldItalic:
            return stripDelimiters(stripDelimiters(text, delimiter: "***"), delimiter: "")
        case .strikethrough:
            return stripDelimiters(text, delimiter: "~~")
        case .inlineCode:
            return stripDelimiters(text, delimiter: "`")
        case .link(let url):
            // Extract link text from [text](url)
            return extractLinkText(text)
        case .image(_, let alt):
            return alt.isEmpty ? "[Image]" : "[Image: \(alt)]"
        case .text, .lineBreak:
            return text
        }
    }

    private func stripDelimiters(_ text: String, delimiter: String) -> String {
        guard !delimiter.isEmpty else { return text }
        var s = text
        if s.hasPrefix(delimiter) { s = String(s.dropFirst(delimiter.count)) }
        if s.hasSuffix(delimiter) { s = String(s.dropLast(delimiter.count)) }
        return s
    }

    private func extractLinkText(_ text: String) -> String {
        // [text](url) -> text
        guard text.hasPrefix("["),
              let closeBracket = text.firstIndex(of: "]") else {
            return text
        }
        let start = text.index(after: text.startIndex)
        return String(text[start..<closeBracket])
    }

    /// Applies inline styling attributes (bold, italic, etc.) to the attribute dictionary.
    private func applyInlineStyle(
        _ type: InlineType,
        attrs: inout [NSAttributedString.Key: Any],
        settings: EditorSettings,
        appearance: Appearance,
        baseFont: NSFont
    ) {
        switch type {
        case .bold:
            attrs[.font] = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)

        case .italic:
            attrs[.font] = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)

        case .boldItalic:
            let bold = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
            attrs[.font] = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)

        case .strikethrough:
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue

        case .inlineCode:
            let monoFont = monospacedFont(size: baseFont.pointSize)
            attrs[.font] = monoFont
            attrs[.backgroundColor] = appearance == .dark
                ? NSColor.white.withAlphaComponent(0.08)
                : NSColor.black.withAlphaComponent(0.06)

        case .link:
            attrs[.foregroundColor] = NSColor.linkColor
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue

        case .image:
            attrs[.foregroundColor] = NSColor.secondaryLabelColor

        case .text, .lineBreak:
            break
        }
    }

    // MARK: - Active (Raw Syntax) Rendering

    private func renderActive(
        block: EditorNode,
        settings: EditorSettings,
        appearance: Appearance
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let font = baseFont(settings: settings)
        let textColor = primaryTextColor(appearance: appearance)
        let paragraphStyle = baseParagraphStyle(settings: settings)
        let source = block.sourceText

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        // If no inline runs, apply block-level syntax coloring to the whole source
        guard !block.inlineRuns.isEmpty else {
            let colored = applySyntaxColor(to: source, kind: block.kind, baseAttrs: baseAttrs)
            result.append(colored)
            return result
        }

        // With inline runs, color delimiters subtly while showing full source
        for run in block.inlineRuns {
            let runText = String(source[run.range])
            let colored = colorActiveInlineRun(runText, type: run.type, baseAttrs: baseAttrs)
            result.append(colored)
        }

        return result
    }

    /// Applies block-level syntax coloring for active blocks without inline runs.
    private func applySyntaxColor(
        to text: String,
        kind: BlockKind,
        baseAttrs: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        var attrs = baseAttrs

        switch kind {
        case .heading:
            // Color the # prefix
            return colorPrefix(text, prefixPattern: "#", color: NSColor.secondaryLabelColor, baseAttrs: baseAttrs)

        case .blockquote:
            return colorPrefix(text, prefixPattern: ">", color: NSColor.systemGreen, baseAttrs: baseAttrs)

        case .codeBlock:
            attrs[.foregroundColor] = NSColor.systemOrange
            return NSAttributedString(string: text, attributes: attrs)

        case .unorderedList, .orderedList, .listItem:
            return colorPrefix(text, prefixPattern: "-", color: NSColor.secondaryLabelColor, baseAttrs: baseAttrs)

        case .horizontalRule:
            attrs[.foregroundColor] = NSColor.secondaryLabelColor
            return NSAttributedString(string: text, attributes: attrs)

        case .table, .tableRow:
            attrs[.foregroundColor] = NSColor.secondaryLabelColor
            return NSAttributedString(string: text, attributes: attrs)

        default:
            return NSAttributedString(string: text, attributes: attrs)
        }
    }

    /// Colors the leading prefix characters (e.g., #, >, -) in the given color.
    private func colorPrefix(
        _ text: String,
        prefixPattern: String,
        color: NSColor,
        baseAttrs: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttrs)

        // Find prefix length (consecutive prefix chars + trailing space)
        var prefixEnd = text.startIndex
        while prefixEnd < text.endIndex && String(text[prefixEnd...prefixEnd]) == prefixPattern {
            prefixEnd = text.index(after: prefixEnd)
        }
        // Include trailing space
        if prefixEnd < text.endIndex && text[prefixEnd] == " " {
            prefixEnd = text.index(after: prefixEnd)
        }

        let prefixLength = text.distance(from: text.startIndex, to: prefixEnd)
        if prefixLength > 0 {
            result.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: prefixLength))
        }
        return result
    }

    /// Colors delimiters in active inline runs.
    private func colorActiveInlineRun(
        _ text: String,
        type: InlineType,
        baseAttrs: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        switch type {
        case .bold:
            return colorDelimiters(text, delimiter: "**", color: NSColor.secondaryLabelColor, baseAttrs: baseAttrs)

        case .italic:
            return colorDelimiters(text, delimiter: "*", color: NSColor.secondaryLabelColor, baseAttrs: baseAttrs)

        case .boldItalic:
            return colorDelimiters(text, delimiter: "***", color: NSColor.secondaryLabelColor, baseAttrs: baseAttrs)

        case .strikethrough:
            return colorDelimiters(text, delimiter: "~~", color: NSColor.secondaryLabelColor, baseAttrs: baseAttrs)

        case .inlineCode:
            return colorDelimiters(text, delimiter: "`", color: NSColor.secondaryLabelColor, baseAttrs: baseAttrs)

        case .link:
            // Color the whole []() syntax with link color
            var attrs = baseAttrs
            attrs[.foregroundColor] = NSColor.linkColor
            return NSAttributedString(string: text, attributes: attrs)

        case .image:
            var attrs = baseAttrs
            attrs[.foregroundColor] = NSColor.linkColor
            return NSAttributedString(string: text, attributes: attrs)

        case .text, .lineBreak:
            return NSAttributedString(string: text, attributes: baseAttrs)
        }
    }

    /// Colors leading and trailing delimiters in secondary label color; inner text in base color.
    private func colorDelimiters(
        _ text: String,
        delimiter: String,
        color: NSColor,
        baseAttrs: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text, attributes: baseAttrs)
        let delimLen = delimiter.count
        let totalLen = text.count

        guard totalLen >= delimLen * 2,
              text.hasPrefix(delimiter),
              text.hasSuffix(delimiter) else {
            return result
        }

        // Color leading delimiter
        result.addAttribute(
            .foregroundColor,
            value: color,
            range: NSRange(location: 0, length: delimLen)
        )
        // Color trailing delimiter
        result.addAttribute(
            .foregroundColor,
            value: color,
            range: NSRange(location: totalLen - delimLen, length: delimLen)
        )
        return result
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

    private func listParagraphStyle(settings: EditorSettings) -> NSMutableParagraphStyle {
        let style = baseParagraphStyle(settings: settings)
        style.headIndent = 20
        style.firstLineHeadIndent = 0
        style.tabStops = [NSTextTab(textAlignment: .left, location: 20)]
        return style
    }

    private func primaryTextColor(appearance: Appearance) -> NSColor {
        switch appearance {
        case .light: return NSColor.labelColor
        case .dark: return NSColor.labelColor
        }
    }
}
