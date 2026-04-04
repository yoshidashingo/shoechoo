# Frontend Components: Unit 3 — Focus & Immersion

## ShoechooTextView Extensions for Focus Mode

### Focus Dimming Implementation

```swift
extension ShoechooTextView {

    /// Apply focus mode dimming: active block at full opacity, all others dimmed.
    /// Called when focus mode is enabled and active block changes.
    func applyFocusModeDimming(activeBlockRange: ActiveBlockRange) {
        guard let textLayoutManager = self.textLayoutManager else { return }

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let dimmingConfig = focusModeState.dimmingConfiguration

        let applyAlpha: (NSTextLayoutFragment, CGFloat) -> Void = { fragment, alpha in
            // Set alpha on the fragment's content layer
            fragment.textLineFragments.forEach { lineFragment in
                // Apply alpha via custom drawing or attributed string manipulation
            }
        }

        if reduceMotion {
            // Immediate application — no animation
            enumerateFragments(textLayoutManager: textLayoutManager) { fragment, range in
                let alpha = range.overlaps(activeBlockRange.textRange)
                    ? dimmingConfig.activeAlpha
                    : dimmingConfig.inactiveAlpha
                applyAlpha(fragment, alpha)
            }
            self.needsDisplay = true
        } else {
            // Animated transition
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.allowsImplicitAnimation = true
                enumerateFragments(textLayoutManager: textLayoutManager) { fragment, range in
                    let alpha = range.overlaps(activeBlockRange.textRange)
                        ? dimmingConfig.activeAlpha
                        : dimmingConfig.inactiveAlpha
                    applyAlpha(fragment, alpha)
                }
                self.needsDisplay = true
            }
        }
    }

    /// Remove all focus dimming — restore full opacity to all blocks.
    func removeFocusModeDimming() {
        guard let textLayoutManager = self.textLayoutManager else { return }

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if reduceMotion {
            enumerateFragments(textLayoutManager: textLayoutManager) { fragment, _ in
                // Restore full alpha
            }
            self.needsDisplay = true
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.allowsImplicitAnimation = true
                enumerateFragments(textLayoutManager: textLayoutManager) { fragment, _ in
                    // Restore full alpha
                }
                self.needsDisplay = true
            }
        }
    }

    /// Helper: enumerate all text layout fragments with their NSRange.
    private func enumerateFragments(
        textLayoutManager: NSTextLayoutManager,
        using block: (NSTextLayoutFragment, NSRange) -> Void
    ) {
        textLayoutManager.enumerateTextLayoutFragments(
            from: textLayoutManager.documentRange.location,
            options: [.ensuresLayout]
        ) { fragment in
            let range = NSRange(fragment.rangeInElement, in: textLayoutManager)
            block(fragment, range)
            return true
        }
    }
}
```

---

## ShoechooTextView Extensions for Typewriter Scroll

### Typewriter Scroll Implementation

```swift
extension ShoechooTextView {

    /// Scroll so that the given line rect is vertically centered in the visible area.
    /// No-op if the document is shorter than the visible area.
    func scrollToCenterLine(_ lineRect: CGRect) {
        guard let scrollView = self.enclosingScrollView else { return }

        let visibleHeight = scrollView.contentView.bounds.height
        let documentHeight = self.textLayoutManager?
            .usageBoundsForTextContainer.height ?? self.bounds.height

        // Short document guard: suppress scroll
        if documentHeight <= visibleHeight { return }

        let visibleCenter = visibleHeight / 2.0
        let activeLineCenter = lineRect.midY
        let targetScrollY = activeLineCenter - visibleCenter

        // Clamp to valid bounds
        let maxY = documentHeight - visibleHeight
        let clampedY = max(0, min(maxY, targetScrollY))
        let targetPoint = NSPoint(x: 0, y: clampedY)

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        if reduceMotion {
            scrollView.contentView.scroll(to: targetPoint)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.allowsImplicitAnimation = true
                scrollView.contentView.animator().setBoundsOrigin(targetPoint)
            }
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
}
```

---

## WYSIWYGTextView (NSViewRepresentable) Updates

### updateNSView Extensions

The existing `updateNSView` from Unit 1 is extended with focus and typewriter logic.

```swift
func updateNSView(_ nsView: ShoechooTextView, context: Context) {
    // ... existing Unit 1 logic (re-render changed blocks) ...

    // Unit 3: Focus Mode Dimming
    if viewModel.isFocusModeEnabled {
        if let activeRange = viewModel.currentActiveBlockRange {
            nsView.applyFocusModeDimming(activeBlockRange: activeRange)
        }
    } else {
        nsView.removeFocusModeDimming()
    }

    // Unit 3: Typewriter Scroll
    if viewModel.isTypewriterScrollEnabled {
        if let activeRange = viewModel.currentActiveBlockRange {
            nsView.scrollToCenterLine(activeRange.layoutRect)
        }
    }
}
```

### Coordinator Extensions

```swift
class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {

    // ... existing Unit 1 delegate methods ...

    // Extended cursor move handler
    func textViewDidChangeSelection(_ notification: Notification) {
        let pos = textView.selectedRange().location
        parent.viewModel.cursorDidMove(to: pos)

        // Focus mode and typewriter scroll react via ViewModel state change
        // which triggers updateNSView on the next SwiftUI render cycle
    }
}
```

---

## EditorViewModel Extensions

### Focus & Typewriter State

```swift
extension EditorViewModel {

    // MARK: - Focus Mode

    var isFocusModeEnabled: Bool  // Published property, drives UI updates

    func toggleFocusMode() {
        isFocusModeEnabled.toggle()
        settings.defaultFocusMode = isFocusModeEnabled
        // Active block range is already tracked — dimming applied in updateNSView
    }

    // MARK: - Typewriter Scroll

    var isTypewriterScrollEnabled: Bool  // Published property, drives UI updates

    func toggleTypewriterScroll() {
        isTypewriterScrollEnabled.toggle()
        settings.defaultTypewriterScroll = isTypewriterScrollEnabled
        // Scroll applied in updateNSView
    }

    // MARK: - Active Block Range (computed from EditorNodeModel)

    var currentActiveBlockRange: ActiveBlockRange? {
        guard let activeBlock = nodeModel.blocks.first(where: { $0.isActive }) else {
            return nil
        }
        // textRange and layoutRect are computed during the render pipeline
        return ActiveBlockRange(
            blockID: activeBlock.id,
            textRange: computeNSRange(for: activeBlock),
            layoutRect: computeLayoutRect(for: activeBlock)
        )
    }
}
```

---

## Full-Screen Integration

### EditorView Commands

```swift
struct EditorView: View {
    @State var viewModel: EditorViewModel
    @State var settings: EditorSettings

    var body: some View {
        WYSIWYGTextView(viewModel: viewModel, settings: settings)
    }
}
```

### Keyboard Shortcut Registration

```swift
// In ShoechooApp or EditorView .commands modifier
.commands {
    // Unit 3: Focus & Immersion
    CommandGroup(after: .textFormatting) {
        Divider()
        Button(viewModel.isFocusModeEnabled ? "Disable Focus Mode" : "Enable Focus Mode") {
            viewModel.toggleFocusMode()
        }
        .keyboardShortcut("f", modifiers: [.command, .shift])

        Button(viewModel.isTypewriterScrollEnabled ? "Disable Typewriter Scroll" : "Enable Typewriter Scroll") {
            viewModel.toggleTypewriterScroll()
        }
        .keyboardShortcut("t", modifiers: [.command, .control])
    }
}
```

**Note**: Full-screen toggle (Ctrl+Cmd+F) is handled automatically by macOS via `NSWindow.toggleFullScreen(_:)` and the green title bar button. No custom command registration is needed unless the app overrides the default behavior.

### Full-Screen Window Delegate

```swift
class WindowDelegate: NSObject, NSWindowDelegate {

    var fullScreenState: FullScreenState

    func windowDidEnterFullScreen(_ notification: Notification) {
        fullScreenState.isFullScreen = true
        fullScreenState.toolbarPolicy = .autoHide
        fullScreenState.sidebarPolicy = .hidden

        // Configure toolbar auto-hide
        if let window = notification.object as? NSWindow {
            window.toolbar?.isVisible = false
            // Toolbar will show when mouse moves to top of screen (macOS native behavior)
        }
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        fullScreenState.isFullScreen = false
        fullScreenState.toolbarPolicy = .alwaysVisible
        fullScreenState.sidebarPolicy = .visible

        // Restore toolbar
        if let window = notification.object as? NSWindow {
            window.toolbar?.isVisible = true
        }
    }
}
```

---

## Accessibility Observer

```swift
// Set up in ShoechooTextView.init or viewDidMoveToWindow
NotificationCenter.default.addObserver(
    self,
    selector: #selector(accessibilityDisplayOptionsDidChange),
    name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
    object: nil
)

@objc func accessibilityDisplayOptionsDidChange(_ notification: Notification) {
    // Re-evaluate transition style
    // If focus mode active: re-apply dimming with new transition style
    // If typewriter scroll active: next scroll will use new behavior automatically
}
```

---

## User Interaction Flows

### Flow 1: Enable Focus Mode (Cmd+Shift+F)
```
1. User presses Cmd+Shift+F
2. SwiftUI command handler calls viewModel.toggleFocusMode()
3. isFocusModeEnabled flips to true
4. EditorSettings.defaultFocusMode persisted
5. SwiftUI triggers updateNSView()
6. updateNSView() calls nsView.applyFocusModeDimming(activeBlockRange:)
7. Inactive blocks fade to 0.3 alpha (animated or immediate per accessibility)
8. Active block remains at 1.0 alpha
```

### Flow 2: Cursor Move with Focus Mode Active
```
1. User clicks or arrow-keys to new position
2. Coordinator calls viewModel.cursorDidMove(to:)
3. ViewModel resolves new active block (Unit 1 logic)
4. If active block changed:
   a. Unit 1: re-render old block (styled) + new block (raw syntax)
   b. Unit 3: updateNSView() re-applies dimming with new ActiveBlockRange
   c. Old block fades to 0.3, new block brightens to 1.0
5. If typewriter scroll enabled: scrollToCenterLine() centers new active line
```

### Flow 3: Enable Typewriter Scroll (Cmd+Ctrl+T)
```
1. User presses Cmd+Ctrl+T
2. SwiftUI command handler calls viewModel.toggleTypewriterScroll()
3. isTypewriterScrollEnabled flips to true
4. EditorSettings.defaultTypewriterScroll persisted
5. SwiftUI triggers updateNSView()
6. updateNSView() calls nsView.scrollToCenterLine(activeRange.layoutRect)
7. View scrolls so active line is at vertical center (animated or immediate)
```

### Flow 4: Enter Full-Screen (Ctrl+Cmd+F or Green Button)
```
1. User presses Ctrl+Cmd+F or clicks green title bar button
2. macOS calls NSWindow.toggleFullScreen(_:)
3. Window animates to full-screen (macOS native animation)
4. windowDidEnterFullScreen delegate fires
5. Toolbar set to auto-hide, sidebar collapsed
6. Focus mode and typewriter scroll continue operating as before
```

### Flow 5: Type in Typewriter Mode with Focus Mode Active
```
1. User types a character in the active block
2. NSTextStorageDelegate fires → viewModel.textDidChange()
3. Parse pipeline runs (Unit 1 steps 1-6)
4. Active block re-rendered with new content
5. Focus dimming re-applied (active block stays at 1.0)
6. Typewriter scroll re-centers on the active line
   (line position may have shifted due to new text)
```

### Flow 6: App Launch with Persisted Settings
```
1. EditorViewModel.init() reads EditorSettings
2. isFocusModeEnabled = settings.defaultFocusMode (e.g., true)
3. isTypewriterScrollEnabled = settings.defaultTypewriterScroll (e.g., true)
4. First layout pass completes
5. updateNSView() applies focus dimming and typewriter scroll
6. User sees the editor in the same focus/typewriter state as last session
```
