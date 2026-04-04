import AppKit
import UniformTypeIdentifiers

@MainActor
final class ShoechooTextView: NSTextView {

    weak var editorViewModel: EditorViewModel?
    var documentURL: URL?

    // MARK: - Paste as Plain Text

    override func paste(_ sender: Any?) {
        pasteAsPlainText(sender)
    }

    // MARK: - Setup

    func registerForImageDrag() {
        registerForDraggedTypes([.fileURL])
    }

    // MARK: - Focus Mode

    func applyFocusModeDimming(activeBlockRange: NSRange, theme: EditorTheme) {
        let fullLength = textStorage?.length ?? 0
        let fullRange = NSRange(location: 0, length: fullLength)

        textStorage?.removeAttribute(.foregroundColor, range: fullRange)

        let dimmingColor = theme.textColor.nsColor.withAlphaComponent(theme.focusDimOpacity)

        if activeBlockRange.location > 0 {
            let beforeRange = NSRange(location: 0, length: activeBlockRange.location)
            textStorage?.addAttribute(.foregroundColor, value: dimmingColor, range: beforeRange)
        }

        let afterStart = activeBlockRange.location + activeBlockRange.length
        if afterStart < fullLength {
            let afterRange = NSRange(location: afterStart, length: fullLength - afterStart)
            textStorage?.addAttribute(.foregroundColor, value: dimmingColor, range: afterRange)
        }
    }

    func removeFocusModeDimming() {
        let fullRange = NSRange(location: 0, length: textStorage?.length ?? 0)
        textStorage?.removeAttribute(.foregroundColor, range: fullRange)
    }

    // MARK: - Typewriter Scrolling

    func scrollToCenterLine(_ lineRange: NSRange) {
        guard let textLayoutManager,
              let textContentStorage = textLayoutManager.textContentManager as? NSTextContentStorage,
              let scrollView = enclosingScrollView else { return }

        guard let startLocation = textContentStorage.location(
            textContentStorage.documentRange.location,
            offsetBy: lineRange.location
        ) else { return }

        let endOffset = lineRange.location + lineRange.length
        guard let endLocation = textContentStorage.location(
            textContentStorage.documentRange.location,
            offsetBy: endOffset
        ) else { return }

        guard let textRange = NSTextRange(location: startLocation, end: endLocation) else { return }

        var lineRect: CGRect?
        textLayoutManager.enumerateTextSegments(
            in: textRange,
            type: .standard,
            options: []
        ) { _, rect, _, _ in
            if let existing = lineRect {
                lineRect = existing.union(rect)
            } else {
                lineRect = rect
            }
            return true
        }

        guard let rect = lineRect else { return }

        let visibleHeight = scrollView.contentView.bounds.height
        var scrollPoint = rect.origin
        scrollPoint.y -= (visibleHeight - rect.height) / 2
        scrollPoint.y = max(0, scrollPoint.y)

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            scroll(scrollPoint)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                scrollView.contentView.animator().setBoundsOrigin(scrollPoint)
            }
        }
    }

    // MARK: - Drag & Drop

    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "webp"]

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        if hasImageURLs(in: sender) {
            return .copy
        }
        return super.draggingEntered(sender)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let urls = imageURLs(from: sender), !urls.isEmpty else {
            return super.performDragOperation(sender)
        }

        guard let viewModel = editorViewModel else {
            return super.performDragOperation(sender)
        }

        Task {
            await viewModel.handleImageDrop(urls: urls, documentURL: documentURL)
        }
        return true
    }

    private func hasImageURLs(in info: any NSDraggingInfo) -> Bool {
        guard let items = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL] else { return false }

        return items.contains { url in
            Self.imageExtensions.contains(url.pathExtension.lowercased())
        }
    }

    private func imageURLs(from info: any NSDraggingInfo) -> [URL]? {
        guard let items = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL] else { return nil }

        return items.filter { url in
            Self.imageExtensions.contains(url.pathExtension.lowercased())
        }
    }

    // MARK: - Auto Pair

    private static let autoPairs: [(open: String, close: String)] = [
        ("(", ")"), ("[", "]"), ("{", "}"),
        ("\"", "\""), ("'", "'"),
        ("`", "`"),
    ]

    override func insertText(_ string: Any, replacementRange: NSRange) {
        guard let str = string as? String, str.count == 1 else {
            super.insertText(string, replacementRange: replacementRange)
            return
        }

        let sel = selectedRange()
        let nsString = self.string as NSString

        // Check if this is an opening character with text selected → wrap
        if sel.length > 0 {
            for pair in Self.autoPairs {
                if str == pair.open {
                    let selected = nsString.substring(with: sel)
                    let wrapped = pair.open + selected + pair.close
                    super.insertText(wrapped, replacementRange: sel)
                    // Place cursor after the wrapped text (before closing)
                    setSelectedRange(NSRange(location: sel.location + 1, length: sel.length))
                    return
                }
            }
        }

        // Check if typing a closing character that matches the next character → skip
        if sel.length == 0 && sel.location < nsString.length {
            let nextChar = nsString.substring(with: NSRange(location: sel.location, length: 1))
            for pair in Self.autoPairs {
                if str == pair.close && nextChar == pair.close {
                    // Check if there's a matching open before
                    setSelectedRange(NSRange(location: sel.location + 1, length: 0))
                    return
                }
            }
        }

        // Auto-pair: insert closing character
        if sel.length == 0 {
            for pair in Self.autoPairs {
                if str == pair.open {
                    // Don't auto-pair single quote inside a word
                    if pair.open == "'" && sel.location > 0 {
                        let prevChar = nsString.substring(with: NSRange(location: sel.location - 1, length: 1))
                        if prevChar.unicodeScalars.first?.properties.isAlphabetic == true {
                            break
                        }
                    }
                    super.insertText(pair.open + pair.close, replacementRange: sel)
                    setSelectedRange(NSRange(location: sel.location + 1, length: 0))
                    return
                }
            }
        }

        super.insertText(string, replacementRange: replacementRange)
    }

    override func deleteBackward(_ sender: Any?) {
        let sel = selectedRange()
        let nsString = self.string as NSString

        // If cursor is between a matched pair, delete both
        if sel.length == 0 && sel.location > 0 && sel.location < nsString.length {
            let prev = nsString.substring(with: NSRange(location: sel.location - 1, length: 1))
            let next = nsString.substring(with: NSRange(location: sel.location, length: 1))
            for pair in Self.autoPairs {
                if prev == pair.open && next == pair.close {
                    setSelectedRange(NSRange(location: sel.location - 1, length: 2))
                    super.insertText("", replacementRange: NSRange(location: sel.location - 1, length: 2))
                    return
                }
            }
        }

        super.deleteBackward(sender)
    }
}
