import AppKit
import UniformTypeIdentifiers

@MainActor
final class ShoechooTextView: NSTextView {

    weak var editorViewModel: EditorViewModel?
    var documentURL: URL?

    // MARK: - Setup

    func registerForImageDrag() {
        registerForDraggedTypes([.fileURL])
    }

    // MARK: - Focus Mode

    func applyFocusModeDimming(activeBlockRange: NSRange) {
        let fullLength = textStorage?.length ?? 0
        let fullRange = NSRange(location: 0, length: fullLength)

        textStorage?.removeAttribute(.foregroundColor, range: fullRange)

        let dimmingColor = NSColor.labelColor.withAlphaComponent(0.3)

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
}
