# Syntax Highlighting Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace WYSIWYG text replacement with syntax highlighting (attributes-only) to fix editing, dark mode, line breaks, and focus mode (Issues #9, #10, #11, #12).

**Architecture:** Keep raw Markdown source in NSTextView at all times. A new `SyntaxHighlighter` applies font/color attributes directly to `NSTextStorage` without changing text content. This preserves editability, cursor position, and undo history while providing visual styling.

**Tech Stack:** Swift, AppKit (NSTextView/NSTextStorage), SwiftUI, Swift Testing

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `shoechoo/Renderer/SyntaxHighlighter.swift` | Create | Apply font/color attributes to NSTextStorage based on parsed blocks |
| `shoechoo/Models/EditorViewModel.swift` | Modify | Remove `attributedStringForDisplay`, add `applySyntaxHighlighting(to:appearance:)` |
| `shoechoo/Editor/WYSIWYGTextView.swift` | Modify | Stop replacing textStorage content, use SyntaxHighlighter instead |
| `shoechoo/Views/EditorView.swift` | Modify | Apply `appearanceOverride` to view hierarchy |
| `shoechoo/Models/RenderCache.swift` | Delete | No longer needed (attributes applied in-place, no caching) |
| `shoechoo/Models/RenderResult.swift` | Delete | No longer needed |
| `shoechooTests/SyntaxHighlighterTests.swift` | Create | Tests for syntax highlighting |
| `shoechooTests/MarkdownRendererTests.swift` | Modify | Remove/update tests that depend on old WYSIWYG rendering |
| `shoechooTests/RenderCacheTests.swift` | Delete | Cache no longer exists |

---

### Task 1: Create SyntaxHighlighter with paragraph styling

**Files:**
- Create: `shoechooTests/SyntaxHighlighterTests.swift`
- Create: `shoechoo/Renderer/SyntaxHighlighter.swift`

- [ ] **Step 1: Write failing test for paragraph highlighting**

```swift
import Testing
import AppKit
@testable import shoechoo

@Suite("SyntaxHighlighter")
@MainActor
struct SyntaxHighlighterTests {

    private let parser = MarkdownParser()

    private func makeTextStorage(_ text: String) -> NSTextStorage {
        NSTextStorage(string: text)
    }

    @Test("Apply to paragraph sets base font and text color")
    func applyParagraph() {
        let source = "Hello, world!"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, appearance: .dark)

        let attrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        #expect(textStorage.string == "Hello, world!")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' test 2>&1 | grep -E '(FAIL|error:|✔|✗|BUILD)'`
Expected: FAIL — `SyntaxHighlighter` not defined

- [ ] **Step 3: Implement SyntaxHighlighter with base apply method**

```swift
import AppKit

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
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let baseFont = NSFont(name: settings.fontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        let textColor = NSColor.labelColor
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = settings.lineSpacing

        textStorage.beginEditing()

        // Apply base attributes to entire text
        textStorage.addAttribute(.font, value: baseFont, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        // Apply block-specific styling
        for block in blocks {
            applyBlockStyle(block, to: textStorage, baseFont: baseFont, settings: settings, appearance: appearance)
        }

        textStorage.endEditing()
    }

    private func applyBlockStyle(
        _ block: EditorNode,
        to textStorage: NSTextStorage,
        baseFont: NSFont,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let source = textStorage.string
        guard let nsRange = Range(block.sourceRange, in: source).flatMap({ NSRange($0, in: source) })
              ?? safeNSRange(for: block.sourceRange, in: source) else {
            return
        }

        switch block.kind {
        case .heading(let level):
            applyHeadingStyle(level: level, range: nsRange, block: block, to: textStorage, settings: settings)

        case .codeBlock:
            applyCodeBlockStyle(range: nsRange, to: textStorage, settings: settings, appearance: appearance)

        case .blockquote:
            applyBlockquoteStyle(range: nsRange, block: block, to: textStorage, baseFont: baseFont, settings: settings, appearance: appearance)

        case .unorderedList, .orderedList:
            for child in block.children {
                applyBlockStyle(child, to: textStorage, baseFont: baseFont, settings: settings, appearance: appearance)
            }

        case .listItem, .taskListItem:
            applyListItemStyle(range: nsRange, block: block, to: textStorage, baseFont: baseFont, settings: settings, appearance: appearance)

        case .horizontalRule:
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: nsRange)

        default:
            applyInlineStyles(block: block, to: textStorage, baseFont: baseFont, settings: settings, appearance: appearance)
        }
    }

    // MARK: - Block Styles

    private func applyHeadingStyle(
        level: Int,
        range: NSRange,
        block: EditorNode,
        to textStorage: NSTextStorage,
        settings: EditorSettings
    ) {
        let fontSize: CGFloat = switch level {
        case 1: 28
        case 2: 24
        case 3: 20
        case 4: 18
        case 5: 16
        default: settings.fontSize
        }
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        textStorage.addAttribute(.font, value: font, range: range)

        // Color the # prefix in secondary color
        let source = textStorage.string
        let blockText = (source as NSString).substring(with: range)
        var prefixLen = 0
        for ch in blockText {
            if ch == "#" { prefixLen += 1 }
            else if ch == " " { prefixLen += 1; break }
            else { break }
        }
        if prefixLen > 0 {
            let prefixRange = NSRange(location: range.location, length: prefixLen)
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: prefixRange)
        }
    }

    private func applyCodeBlockStyle(
        range: NSRange,
        to textStorage: NSTextStorage,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let monoFont = NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        textStorage.addAttribute(.font, value: monoFont, range: range)

        let bgColor = appearance == .dark
            ? NSColor.white.withAlphaComponent(0.05)
            : NSColor.black.withAlphaComponent(0.04)
        textStorage.addAttribute(.backgroundColor, value: bgColor, range: range)

        // Color fence lines in secondary color
        let source = textStorage.string
        let blockText = (source as NSString).substring(with: range)
        let lines = blockText.components(separatedBy: "\n")
        var offset = 0
        for line in lines {
            let lineNSLength = (line as NSString).length
            if line.hasPrefix("```") {
                let fenceRange = NSRange(location: range.location + offset, length: lineNSLength)
                textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: fenceRange)
            }
            offset += lineNSLength + 1 // +1 for \n
        }
    }

    private func applyBlockquoteStyle(
        range: NSRange,
        block: EditorNode,
        to textStorage: NSTextStorage,
        baseFont: NSFont,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: range)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = settings.lineSpacing
        paragraphStyle.headIndent = 16
        paragraphStyle.firstLineHeadIndent = 0
        textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)

        // Color > markers in green
        let source = textStorage.string
        let blockText = (source as NSString).substring(with: range)
        let lines = blockText.components(separatedBy: "\n")
        var offset = 0
        for line in lines {
            let lineNSLength = (line as NSString).length
            if line.hasPrefix(">") {
                let markerLen = line.hasPrefix("> ") ? 2 : 1
                let markerRange = NSRange(location: range.location + offset, length: markerLen)
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: markerRange)
            }
            offset += lineNSLength + 1
        }
    }

    private func applyListItemStyle(
        range: NSRange,
        block: EditorNode,
        to textStorage: NSTextStorage,
        baseFont: NSFont,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        // Color list marker in secondary color
        let source = textStorage.string
        let blockText = (source as NSString).substring(with: range)
        let trimmed = blockText.trimmingCharacters(in: .whitespaces)
        var markerLen = 0
        if trimmed.hasPrefix("- [") {
            markerLen = blockText.distance(from: blockText.startIndex, to: blockText.range(of: "] ")!.upperBound)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            if let dashRange = blockText.range(of: "- ") ?? blockText.range(of: "* ") {
                markerLen = blockText.distance(from: blockText.startIndex, to: dashRange.upperBound)
            }
        } else if let dotRange = blockText.range(of: ". ") {
            markerLen = blockText.distance(from: blockText.startIndex, to: dotRange.upperBound)
        }
        if markerLen > 0 {
            let markerNSLen = (String(blockText.prefix(markerLen)) as NSString).length
            let markerRange = NSRange(location: range.location, length: markerNSLen)
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: markerRange)
        }

        applyInlineStyles(block: block, to: textStorage, baseFont: baseFont, settings: settings, appearance: appearance)
    }

    // MARK: - Inline Styles

    private func applyInlineStyles(
        block: EditorNode,
        to textStorage: NSTextStorage,
        baseFont: NSFont,
        settings: EditorSettings,
        appearance: Appearance
    ) {
        let source = textStorage.string
        for run in block.inlineRuns {
            guard let nsRange = safeNSRange(for: run.range, in: block.sourceText, blockSourceRange: block.sourceRange, fullSource: source) else {
                continue
            }

            switch run.type {
            case .bold:
                let boldFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                textStorage.addAttribute(.font, value: boldFont, range: nsRange)
                applyDelimiterColor(delimiter: "**", runRange: nsRange, to: textStorage, source: source)

            case .italic:
                let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
                textStorage.addAttribute(.font, value: italicFont, range: nsRange)
                applyDelimiterColor(delimiter: "*", runRange: nsRange, to: textStorage, source: source)

            case .boldItalic:
                let bold = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                let boldItalic = NSFontManager.shared.convert(bold, toHaveTrait: .italicFontMask)
                textStorage.addAttribute(.font, value: boldItalic, range: nsRange)
                applyDelimiterColor(delimiter: "***", runRange: nsRange, to: textStorage, source: source)

            case .strikethrough:
                textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)
                applyDelimiterColor(delimiter: "~~", runRange: nsRange, to: textStorage, source: source)

            case .inlineCode:
                let monoFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
                textStorage.addAttribute(.font, value: monoFont, range: nsRange)
                let bgColor = appearance == .dark
                    ? NSColor.white.withAlphaComponent(0.08)
                    : NSColor.black.withAlphaComponent(0.06)
                textStorage.addAttribute(.backgroundColor, value: bgColor, range: nsRange)
                applyDelimiterColor(delimiter: "`", runRange: nsRange, to: textStorage, source: source)

            case .link:
                textStorage.addAttribute(.foregroundColor, value: NSColor.linkColor, range: nsRange)
                textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: nsRange)

            case .image:
                textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: nsRange)

            case .text, .lineBreak:
                break
            }
        }
    }

    private func applyDelimiterColor(
        delimiter: String,
        runRange: NSRange,
        to textStorage: NSTextStorage,
        source: String
    ) {
        let nsDelim = (delimiter as NSString).length
        guard runRange.length >= nsDelim * 2 else { return }

        let runText = (source as NSString).substring(with: runRange)
        guard runText.hasPrefix(delimiter), runText.hasSuffix(delimiter) else { return }

        let leadingRange = NSRange(location: runRange.location, length: nsDelim)
        let trailingRange = NSRange(location: runRange.location + runRange.length - nsDelim, length: nsDelim)
        textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: leadingRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: trailingRange)
    }

    // MARK: - Range Helpers

    private func safeNSRange(for range: Range<String.Index>, in source: String) -> NSRange? {
        guard range.lowerBound >= source.startIndex, range.upperBound <= source.endIndex else {
            return nil
        }
        return NSRange(range, in: source)
    }

    private func safeNSRange(
        for localRange: Range<String.Index>,
        in blockText: String,
        blockSourceRange: Range<String.Index>,
        fullSource: String
    ) -> NSRange? {
        // Convert block-local range to full source range
        let startOffset = blockText.distance(from: blockText.startIndex, to: localRange.lowerBound)
        let endOffset = blockText.distance(from: blockText.startIndex, to: localRange.upperBound)

        guard let blockNSRange = safeNSRange(for: blockSourceRange, in: fullSource) else {
            return nil
        }

        // Convert character offsets to UTF-16 offsets within the block
        let blockNSText = (fullSource as NSString).substring(with: blockNSRange)
        let nsBlockText = blockNSText as NSString

        // Use the block's source text to compute UTF-16 positions
        let blockSwiftText = String(blockNSText)
        guard startOffset >= 0,
              endOffset <= blockSwiftText.count else {
            return nil
        }

        let swiftStart = blockSwiftText.index(blockSwiftText.startIndex, offsetBy: startOffset)
        let swiftEnd = blockSwiftText.index(blockSwiftText.startIndex, offsetBy: endOffset)
        let utf16Start = blockSwiftText[blockSwiftText.startIndex..<swiftStart].utf16.count
        let utf16End = blockSwiftText[blockSwiftText.startIndex..<swiftEnd].utf16.count

        return NSRange(location: blockNSRange.location + utf16Start, length: utf16End - utf16Start)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' test 2>&1 | grep -E '(✔|✗|TEST|FAIL)'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add shoechoo/Renderer/SyntaxHighlighter.swift shoechooTests/SyntaxHighlighterTests.swift
git commit -m "feat: add SyntaxHighlighter with paragraph and block styling (fixes #9 #10 #11 #12)"
```

---

### Task 2: Add SyntaxHighlighter tests for headings, code blocks, and inline styles

**Files:**
- Modify: `shoechooTests/SyntaxHighlighterTests.swift`

- [ ] **Step 1: Write tests for heading, code, bold, and link styling**

```swift
    @Test("Heading gets bold font with larger size")
    func applyHeading() {
        let source = "# Title"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, appearance: .light)

        // Text content unchanged
        #expect(textStorage.string == "# Title")
        // Font at "T" position should be bold and large
        let attrs = textStorage.attributes(at: 2, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        #expect(font!.pointSize >= 28)
    }

    @Test("Heading # prefix colored as secondary")
    func headingPrefixColor() {
        let source = "## Sub"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, appearance: .light)

        let prefixAttrs = textStorage.attributes(at: 0, effectiveRange: nil)
        let prefixColor = prefixAttrs[.foregroundColor] as? NSColor
        #expect(prefixColor == NSColor.secondaryLabelColor)
    }

    @Test("Code block gets monospaced font")
    func applyCodeBlock() {
        let source = "```swift\nlet x = 1\n```"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, appearance: .dark)

        #expect(textStorage.string == source)
        // Check font at "let" position
        let fenceEnd = (source as NSString).range(of: "\n").location + 1
        let attrs = textStorage.attributes(at: fenceEnd, effectiveRange: nil)
        let font = attrs[.font] as? NSFont
        #expect(font != nil)
        #expect(font!.isFixedPitch)
    }

    @Test("Bold text gets bold font, delimiters get secondary color")
    func applyBold() {
        let source = "This is **bold** text"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, appearance: .light)

        #expect(textStorage.string == source)

        // "bold" should have bold font
        let boldStart = (source as NSString).range(of: "**bold**").location
        let bAttrs = textStorage.attributes(at: boldStart + 2, effectiveRange: nil)
        let bFont = bAttrs[.font] as? NSFont
        #expect(bFont != nil)
        let traits = NSFontManager.shared.traits(of: bFont!)
        #expect(traits.contains(.boldFontMask))
    }

    @Test("Text content is never modified by apply")
    func textContentPreserved() {
        let source = "# Hello\n\nA **bold** paragraph.\n\n- item 1\n- item 2\n\n```\ncode\n```"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, appearance: .dark)

        #expect(textStorage.string == source)
    }

    @Test("Japanese text content is preserved and styled")
    func japaneseTextPreserved() {
        let source = "# 日本語タイトル\n\nこれは**太字**テスト"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, appearance: .dark)

        #expect(textStorage.string == source)
    }
```

- [ ] **Step 2: Run tests**

Run: `xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' test 2>&1 | grep -E '(✔|✗|TEST|FAIL)'`
Expected: All new tests PASS

- [ ] **Step 3: Commit**

```bash
git add shoechooTests/SyntaxHighlighterTests.swift
git commit -m "test: add SyntaxHighlighter tests for headings, code, bold, Japanese"
```

---

### Task 3: Wire SyntaxHighlighter into EditorViewModel

**Files:**
- Modify: `shoechoo/Models/EditorViewModel.swift`

- [ ] **Step 1: Replace `attributedStringForDisplay` with `applySyntaxHighlighting`**

Remove the `attributedStringForDisplay` method and add:

```swift
    func applySyntaxHighlighting(to textStorage: NSTextStorage, appearance: NSAppearance) {
        let highlighter = SyntaxHighlighter()
        let highlighterAppearance: SyntaxHighlighter.Appearance =
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil ? .dark : .light
        highlighter.apply(
            to: textStorage,
            blocks: nodeModel.blocks,
            settings: settings,
            appearance: highlighterAppearance
        )
        needsFullRerender = false
        changedBlockIDs.removeAll()
    }
```

Also remove the `renderCache` property and its import since it's no longer used.

- [ ] **Step 2: Verify build compiles**

Run: `xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (with warnings about unused MarkdownRenderer — that's fine)

- [ ] **Step 3: Commit**

```bash
git add shoechoo/Models/EditorViewModel.swift
git commit -m "refactor: replace attributedStringForDisplay with applySyntaxHighlighting"
```

---

### Task 4: Update WYSIWYGTextView to use attribute-only updates

**Files:**
- Modify: `shoechoo/Editor/WYSIWYGTextView.swift`

- [ ] **Step 1: Rewrite `updateNSView` to apply attributes instead of replacing text**

Replace the `updateNSView` method body:

```swift
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ShoechooTextView else { return }

        // Apply appearance override
        switch settings.appearanceOverride {
        case .light:
            scrollView.appearance = NSAppearance(named: .aqua)
        case .dark:
            scrollView.appearance = NSAppearance(named: .darkAqua)
        case .system:
            scrollView.appearance = nil
        }

        // Update font in typing attributes
        let font = NSFont(name: settings.fontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]

        // Apply syntax highlighting (attributes only, never change text content)
        if viewModel.needsFullRerender || !viewModel.changedBlockIDs.isEmpty {
            if let textStorage = textView.textStorage {
                let appearance = textView.effectiveAppearance
                viewModel.applySyntaxHighlighting(to: textStorage, appearance: appearance)
            }
        }

        // Focus mode dimming
        if viewModel.isFocusModeEnabled {
            if let activeID = viewModel.nodeModel.activeBlockID,
               let activeBlock = viewModel.nodeModel.block(withID: activeID) {
                let nsRange = NSRange(activeBlock.sourceRange, in: viewModel.sourceText)
                textView.applyFocusModeDimming(activeBlockRange: nsRange)
            }
        } else {
            textView.removeFocusModeDimming()
        }

        // Typewriter scroll
        if viewModel.isTypewriterScrollEnabled {
            let cursorRange = NSRange(location: viewModel.cursorPosition, length: 0)
            textView.scrollToCenterLine(cursorRange)
        }
    }
```

- [ ] **Step 2: Update `makeNSView` to set background colors properly**

In the `makeNSView` method, after creating the textView, add:

```swift
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
```

And update scrollView setup:

```swift
        scrollView.backgroundColor = .textBackgroundColor
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add shoechoo/Editor/WYSIWYGTextView.swift
git commit -m "fix: use attribute-only syntax highlighting, apply appearance override (#9 #10 #11 #12)"
```

---

### Task 5: Clean up unused renderer and cache code

**Files:**
- Delete: `shoechoo/Models/RenderCache.swift`
- Delete: `shoechoo/Models/RenderResult.swift`
- Delete: `shoechooTests/RenderCacheTests.swift`
- Modify: `shoechooTests/MarkdownRendererTests.swift`

- [ ] **Step 1: Remove RenderCache.swift, RenderResult.swift, and RenderCacheTests.swift from project**

Remove the files and update the Xcode project:

```bash
rm shoechoo/Models/RenderCache.swift shoechoo/Models/RenderResult.swift shoechooTests/RenderCacheTests.swift
```

Also update `project.yml` or Xcode project references if needed.

- [ ] **Step 2: Update MarkdownRendererTests to remove tests that depend on deleted types**

The `MarkdownRendererTests` reference `MarkdownRenderer` which still exists (it's used by `ExportService` for HTML export). Keep tests that validate the renderer's output but remove any that depend on `RenderResult` or `RenderCache`. The renderer tests should still work since `MarkdownRenderer.render()` returns `RenderResult` — if `RenderResult` is deleted, update the renderer to return `NSAttributedString` directly, or keep `RenderResult` if the renderer still uses it.

**Decision:** Keep `MarkdownRenderer` and `RenderResult` since `ExportService` may use them. Only delete `RenderCache` and its tests.

```bash
rm shoechoo/Models/RenderCache.swift shoechooTests/RenderCacheTests.swift
```

Remove `renderCache` references from `EditorViewModel` if any remain.

- [ ] **Step 3: Build and test**

Run: `xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' test 2>&1 | grep -E '(✔|✗|TEST|FAIL|BUILD)'`
Expected: BUILD SUCCEEDED, TEST SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove unused RenderCache"
```

---

### Task 6: Final integration test and build verification

**Files:**
- Modify: `shoechooTests/SyntaxHighlighterTests.swift` (add integration test)

- [ ] **Step 1: Add integration test with mixed markdown document**

```swift
    @Test("Mixed document: all block types styled without changing text")
    func mixedDocument() {
        let source = """
        # Title

        A paragraph with **bold** and *italic*.

        - Item 1
        - Item 2

        ```swift
        let x = 1
        ```

        > A quote

        ---
        """
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: EditorSettings.shared, appearance: .dark)

        // Text MUST be unchanged
        #expect(textStorage.string == source)

        // Heading should have large font
        let titleAttrs = textStorage.attributes(at: 2, effectiveRange: nil)
        let titleFont = titleAttrs[.font] as? NSFont
        #expect(titleFont!.pointSize >= 28)
    }
```

- [ ] **Step 2: Run full test suite**

Run: `xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' test 2>&1 | grep -E '(✔|✗|TEST|FAIL|BUILD|passed|failed)'`
Expected: ALL PASS

- [ ] **Step 3: Build and launch app for manual verification**

```bash
xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -destination 'platform=macOS' build
open ~/Library/Developer/Xcode/DerivedData/shoechoo-*/Build/Products/Debug/shoechoo.app
```

- [ ] **Step 4: Commit**

```bash
git add shoechooTests/SyntaxHighlighterTests.swift
git commit -m "test: add mixed document integration test for SyntaxHighlighter"
```
