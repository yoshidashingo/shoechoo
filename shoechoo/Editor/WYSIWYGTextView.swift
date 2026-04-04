import SwiftUI
import AppKit

struct WYSIWYGTextView: NSViewRepresentable {
    @Bindable var viewModel: EditorViewModel
    var settings: EditorSettings

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        let textView = ShoechooTextView(frame: .zero, textContainer: textContainer)
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.textContainerInset = NSSize(width: 40, height: 20)
        textView.delegate = context.coordinator

        let font = NSFont(name: settings.fontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        textView.font = font
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]

        if !viewModel.sourceText.isEmpty {
            textView.string = viewModel.sourceText
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true

        context.coordinator.textView = textView
        context.coordinator.registerNotifications()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ShoechooTextView else { return }

        let font = NSFont(name: settings.fontFamily, size: settings.fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
        if textView.font != font {
            textView.font = font
        }

        if viewModel.needsFullRerender || !viewModel.changedBlockIDs.isEmpty {
            let appearance = textView.effectiveAppearance
            let attributed = viewModel.attributedStringForDisplay(appearance: appearance)

            let selectedRange = textView.selectedRange()
            context.coordinator.isUpdating = true
            textView.textStorage?.setAttributedString(attributed)

            let safeLocation = min(selectedRange.location, textView.string.count)
            textView.setSelectedRange(NSRange(location: safeLocation, length: 0))
            context.coordinator.isUpdating = false
        }

        if viewModel.isFocusModeEnabled {
            if let activeID = viewModel.nodeModel.activeBlockID,
               let activeBlock = viewModel.nodeModel.block(withID: activeID) {
                let nsRange = NSRange(activeBlock.sourceRange, in: viewModel.sourceText)
                textView.applyFocusModeDimming(activeBlockRange: nsRange)
            }
        } else {
            textView.removeFocusModeDimming()
        }

        if viewModel.isTypewriterScrollEnabled {
            let cursorRange = NSRange(location: viewModel.cursorPosition, length: 0)
            textView.scrollToCenterLine(cursorRange)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: WYSIWYGTextView
        weak var textView: ShoechooTextView?
        var isUpdating = false
        nonisolated(unsafe) private var notificationObservers: [any NSObjectProtocol] = []

        init(_ parent: WYSIWYGTextView) {
            self.parent = parent
        }

        deinit {
            for observer in notificationObservers {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating,
                  let textView = notification.object as? NSTextView else { return }
            let newText = textView.string
            let editedRange = textView.textStorage?.editedRange ?? NSRange(location: 0, length: 0)
            parent.viewModel.textDidChange(newText, editedRange: editedRange)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isUpdating,
                  let textView = notification.object as? NSTextView else { return }
            let position = textView.selectedRange().location
            let composing = textView.hasMarkedText()
            parent.viewModel.isIMEComposing = composing
            if !composing {
                parent.viewModel.cursorDidMove(to: position)
            }
        }

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

            notificationObservers = [toggleObs, insertObs, prefixObs]
        }

        private func handleToggleFormatting(prefix: String?, suffix: String?) {
            guard let textView,
                  let prefix = prefix,
                  let suffix = suffix else { return }

            let selectedRange = textView.selectedRange()
            guard selectedRange.length > 0 else { return }

            let text = textView.string as NSString
            let selectedText = text.substring(with: selectedRange)

            if selectedText.hasPrefix(prefix) && selectedText.hasSuffix(suffix) {
                let stripped = String(selectedText.dropFirst(prefix.count).dropLast(suffix.count))
                textView.insertText(stripped, replacementRange: selectedRange)
            } else {
                let formatted = prefix + selectedText + suffix
                textView.insertText(formatted, replacementRange: selectedRange)
            }
        }

        private func handleInsertText(text: String?, cursorOffset: Int?) {
            guard let textView,
                  let text = text,
                  let cursorOffset = cursorOffset else { return }

            let selectedRange = textView.selectedRange()
            textView.insertText(text, replacementRange: selectedRange)

            let newPos = selectedRange.location + cursorOffset
            textView.setSelectedRange(NSRange(location: newPos, length: 0))
        }

        private func handleSetLinePrefix(prefix: String?) {
            guard let textView,
                  let prefix = prefix else { return }

            let text = textView.string as NSString
            let selectedRange = textView.selectedRange()
            let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
            let lineText = text.substring(with: lineRange)

            let stripped = lineText.replacingOccurrences(
                of: "^#{1,6}\\s*",
                with: "",
                options: .regularExpression
            )
            let newLine = prefix + stripped
            textView.insertText(newLine, replacementRange: lineRange)
        }
    }
}
