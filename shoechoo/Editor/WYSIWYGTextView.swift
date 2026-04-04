import SwiftUI
import AppKit

struct WYSIWYGTextView: NSViewRepresentable {
    @Bindable var viewModel: EditorViewModel
    var settings: EditorSettings
    var themeRegistry: ThemeRegistry
    weak var document: MarkdownDocument?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = ShoechooScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true

        let textView = ShoechooTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 40, height: 20)
        textView.textContainer?.widthTracksTextView = true

        let font = NSFont(name: settings.fontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        textView.font = font

        scrollView.documentView = textView

        // Set coordinator and appearance BEFORE setting content
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.applyAppearance(settings: settings)

        // Set content BEFORE delegate to avoid double-fire
        if !viewModel.sourceText.isEmpty {
            textView.string = viewModel.sourceText
        }

        textView.delegate = context.coordinator
        context.coordinator.registerNotifications()

        // Initial highlight — apply synchronously so text is visible immediately
        context.coordinator.applyHighlightNow()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // Only update appearance — never touch text or attributes
        context.coordinator.applyAppearance(settings: settings)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: WYSIWYGTextView
        weak var textView: ShoechooTextView?
        weak var scrollView: NSScrollView?
        private let nodeModel = EditorNodeModel()
        private var isApplyingHighlight = false
        nonisolated(unsafe) private var highlightTimer: Timer?
        nonisolated(unsafe) private var autoSaveTimer: Timer?
        nonisolated(unsafe) private var notificationObservers: [any NSObjectProtocol] = []

        init(_ parent: WYSIWYGTextView) {
            self.parent = parent
        }

        deinit {
            highlightTimer?.invalidate()
            autoSaveTimer?.invalidate()
            for observer in notificationObservers {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func applyAppearance(settings: EditorSettings) {
            guard let textView, let scrollView else { return }

            let theme = parent.themeRegistry.activeTheme

            // Set appearance based on theme darkness
            if theme.isDark {
                scrollView.appearance = NSAppearance(named: .darkAqua)
            } else {
                switch settings.appearanceOverride {
                case .light: scrollView.appearance = NSAppearance(named: .aqua)
                case .dark: scrollView.appearance = NSAppearance(named: .darkAqua)
                case .system: scrollView.appearance = nil
                }
            }

            let bgColor = theme.backgroundColor.nsColor
            let fgColor = theme.textColor.nsColor

            textView.drawsBackground = true
            textView.backgroundColor = bgColor
            scrollView.backgroundColor = bgColor
            textView.insertionPointColor = theme.cursorColor.nsColor

            let font = NSFont(name: settings.fontFamily, size: settings.fontSize)
                ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
            textView.typingAttributes = [.font: font, .foregroundColor: fgColor]
        }

        // MARK: - Highlight

        func scheduleHighlight() {
            highlightTimer?.invalidate()
            highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.applyHighlightNow()
                }
            }
        }

        func applyHighlightNow() {
            guard let textView, let ts = textView.textStorage else { return }
            guard ts.length > 0 else { return }
            // Skip highlight during IME composition — modifying textStorage
            // destroys markedText and breaks input methods (Japanese, Chinese, etc.)
            guard !textView.hasMarkedText() else {
                scheduleHighlight() // retry after composition ends
                return
            }
            guard !isApplyingHighlight else { return } // prevent re-entrancy
            isApplyingHighlight = true
            defer { isApplyingHighlight = false }

            let text = textView.string
            let parser = MarkdownParser()
            let result = parser.parse(text, revision: 0)

            nodeModel.applyParseResult(result)

            let savedSelection = textView.selectedRange()
            let highlighter = SyntaxHighlighter()
            let theme = parent.themeRegistry.activeTheme
            highlighter.apply(to: ts, blocks: nodeModel.blocks, settings: parent.settings, theme: theme)

            // Apply focus mode dimming after highlight so it overlays correctly
            updateFocusModeDimming(cursorPosition: savedSelection.location)

            // Restore selection on next RunLoop tick — endEditing() triggers internal
            // NSTextView processing that can reset selection after this method returns.
            let length = ts.length
            DispatchQueue.main.async { [weak textView] in
                guard let textView else { return }
                let safeLoc = min(savedSelection.location, length)
                let safeLen = min(savedSelection.length, length - safeLoc)
                textView.setSelectedRange(NSRange(location: safeLoc, length: safeLen))
            }
        }

        // MARK: - Auto-Save

        func scheduleAutoSave() {
            guard parent.settings.autoSaveEnabled else {
                autoSaveTimer?.invalidate()
                autoSaveTimer = nil
                return
            }
            autoSaveTimer?.invalidate()
            let interval = TimeInterval(parent.settings.autoSaveIntervalSeconds)
            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.performAutoSave()
                }
            }
        }

        private func performAutoSave() {
            guard let textView else { return }
            guard let doc = textView.window?.windowController?.document as? NSDocument else { return }
            doc.autosave(withImplicitCancellability: false) { _ in }
        }

        // MARK: - Delegate

        func textDidChange(_ notification: Notification) {
            guard !isApplyingHighlight else { return } // ignore re-entrant calls from attribute changes
            guard let textView = notification.object as? NSTextView else { return }
            let newText = textView.string
            parent.viewModel.sourceText = newText
            // Update document snapshot for save — use direct reference, not windowController chain
            parent.document?.updateSnapshotText(newText)
            scheduleHighlight()
            scheduleAutoSave()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let pos = textView.selectedRange().location
            if !textView.hasMarkedText() {
                parent.viewModel.cursorPosition = pos
            }
            parent.viewModel.isIMEComposing = textView.hasMarkedText()
            updateFocusModeDimming(cursorPosition: pos)
        }

        private func updateFocusModeDimming(cursorPosition: Int) {
            guard let textView = textView as? ShoechooTextView else { return }
            guard parent.viewModel.isFocusModeEnabled else {
                textView.removeFocusModeDimming()
                return
            }
            if let activeID = nodeModel.resolveActiveBlock(cursorOffset: cursorPosition),
               let activeBlock = nodeModel.block(withID: activeID) {
                nodeModel.setActiveBlock(activeID)
                textView.applyFocusModeDimming(activeBlockRange: activeBlock.sourceRange, theme: parent.themeRegistry.activeTheme)
            }
        }

        // MARK: - Notifications

        func registerNotifications() {
            let toggleObs = NotificationCenter.default.addObserver(
                forName: .toggleFormatting, object: nil, queue: .main
            ) { [weak self] notification in
                let prefix = notification.userInfo?["prefix"] as? String
                let suffix = notification.userInfo?["suffix"] as? String
                MainActor.assumeIsolated {
                    self?.handleToggleFormatting(prefix: prefix, suffix: suffix)
                }
            }
            let insertObs = NotificationCenter.default.addObserver(
                forName: .insertFormattedText, object: nil, queue: .main
            ) { [weak self] notification in
                let text = notification.userInfo?["text"] as? String
                let cursorOffset = notification.userInfo?["cursorOffset"] as? Int
                MainActor.assumeIsolated {
                    self?.handleInsertText(text: text, cursorOffset: cursorOffset)
                }
            }
            let prefixObs = NotificationCenter.default.addObserver(
                forName: .setLinePrefix, object: nil, queue: .main
            ) { [weak self] notification in
                let prefix = notification.userInfo?["prefix"] as? String
                MainActor.assumeIsolated {
                    self?.handleSetLinePrefix(prefix: prefix)
                }
            }
            let scrollObs = NotificationCenter.default.addObserver(
                forName: .scrollToPosition, object: nil, queue: .main
            ) { [weak self] notification in
                let position = notification.userInfo?["position"] as? Int
                MainActor.assumeIsolated {
                    self?.handleScrollToPosition(position: position)
                }
            }
            notificationObservers = [toggleObs, insertObs, prefixObs, scrollObs]
        }

        private func handleToggleFormatting(prefix: String?, suffix: String?) {
            guard let textView, let prefix, let suffix else { return }
            let sel = textView.selectedRange()
            guard sel.length > 0 else { return }
            let text = (textView.string as NSString).substring(with: sel)
            if text.hasPrefix(prefix) && text.hasSuffix(suffix) {
                textView.insertText(String(text.dropFirst(prefix.count).dropLast(suffix.count)), replacementRange: sel)
            } else {
                textView.insertText(prefix + text + suffix, replacementRange: sel)
            }
        }

        private func handleInsertText(text: String?, cursorOffset: Int?) {
            guard let textView, let text, let cursorOffset else { return }
            let sel = textView.selectedRange()
            textView.insertText(text, replacementRange: sel)
            textView.setSelectedRange(NSRange(location: sel.location + cursorOffset, length: 0))
        }

        private func handleSetLinePrefix(prefix: String?) {
            guard let textView, let prefix else { return }
            let ns = textView.string as NSString
            let sel = textView.selectedRange()
            let lineRange = ns.lineRange(for: NSRange(location: sel.location, length: 0))
            let lineText = ns.substring(with: lineRange)
            let stripped = lineText.replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
            textView.insertText(prefix + stripped, replacementRange: lineRange)
        }

        private func handleScrollToPosition(position: Int?) {
            guard let textView, let position else { return }
            let length = (textView.string as NSString).length
            let safePosition = min(max(0, position), length)
            let range = NSRange(location: safePosition, length: 0)
            textView.setSelectedRange(range)
            textView.scrollRangeToVisible(range)
        }
    }
}

/// NSScrollView subclass so SwiftUI properly handles first responder.
final class ShoechooScrollView: NSScrollView {
    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        if let textView = documentView as? NSTextView {
            return window?.makeFirstResponder(textView) ?? false
        }
        return super.becomeFirstResponder()
    }
}
