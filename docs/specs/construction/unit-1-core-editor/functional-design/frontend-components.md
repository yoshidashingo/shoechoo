---
layout: default
---

# Frontend Components: Unit 1 — Core Editor Engine

## WYSIWYGTextView (NSViewRepresentable)

### Interaction Model

```
SwiftUI Layer                    AppKit Layer
+------------------+            +------------------------+
| EditorView       |            | ShoechooTextView       |
|   (SwiftUI)      |  wraps     |   (NSTextView subclass)|
|                  | ---------> |                        |
| @State viewModel |            | TextKit 2 stack:       |
| settings         |            |  NSTextContentStorage  |
+------------------+            |  NSTextLayoutManager   |
        |                       |  NSTextContainer       |
        v                       +------------------------+
WYSIWYGTextView                          |
  (NSViewRepresentable)                  v
  makeNSView() ----> ShoechooTextView
  updateNSView() --> sync state
  Coordinator <----- delegate callbacks
```

### ShoechooTextView Responsibilities

| Responsibility | Mechanism |
|---------------|-----------|
| Text editing | NSTextView built-in (TextKit 2) |
| IME input | NSTextInputClient (built-in) |
| Undo/Redo | NSUndoManager (built-in via NSTextView) |
| Spell check | NSSpellChecker (built-in) |
| Selection | NSTextView built-in |
| Cursor tracking | `NSTextViewDelegate.textViewDidChangeSelection()` |
| Text changes | `NSTextStorageDelegate.textStorage(_:didProcessEditing:...)` |
| Drag & drop images | `performDragOperation(_:)` override |
| Focus mode dimming | Custom drawing via `NSTextLayoutFragment` alpha |
| Typewriter scrolling | `scrollRangeToVisible()` with center offset |

### NSViewRepresentable Lifecycle

```swift
struct WYSIWYGTextView: NSViewRepresentable {
    @Bindable var viewModel: EditorViewModel
    var settings: EditorSettings

    func makeNSView(context: Context) -> ShoechooTextView {
        // 1. Create NSTextContentStorage + NSTextLayoutManager + NSTextContainer
        // 2. Create ShoechooTextView with TextKit 2 stack
        // 3. Configure: editable, richText=false, allowsUndo
        // 4. Set delegate to Coordinator
        // 5. Apply initial attributed string from viewModel
        return textView
    }

    func updateNSView(_ nsView: ShoechooTextView, context: Context) {
        // Called when SwiftUI state changes
        // 1. If viewModel.needsFullRerender: replace entire attributed string
        // 2. If viewModel.changedBlockIDs: update only those ranges
        // 3. Apply focus mode dimming if enabled
        // 4. Apply typewriter scroll if enabled
        // 5. Sync font/spacing from settings
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
}
```

### Coordinator (Delegate Bridge)

```swift
class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
    var parent: WYSIWYGTextView

    // Text change → ViewModel
    func textStorage(_ ts: NSTextStorage, didProcessEditing ...) {
        parent.viewModel.textDidChange(ts.string, editedRange: editedRange)
    }

    // Cursor move → ViewModel
    func textViewDidChangeSelection(_ notification: Notification) {
        let pos = textView.selectedRange().location
        parent.viewModel.cursorDidMove(to: pos)
    }

    // IME composition tracking
    // Detected via textView.hasMarkedText()
}
```

---

## User Interaction Flows

### Flow 1: Typing Text
```
1. User types character
2. NSTextView inserts character (TextKit 2)
3. NSTextStorageDelegate fires
4. Coordinator calls viewModel.textDidChange()
5. ViewModel increments revision, schedules parse (50ms debounce)
6. Parse completes → diff → selective re-render
7. updateNSView() applies changed block attributed strings
```

### Flow 2: Moving Cursor (Arrow Keys / Click)
```
1. User clicks or arrow-keys to new position
2. NSTextViewDelegate.textViewDidChangeSelection fires
3. Coordinator calls viewModel.cursorDidMove(to:)
4. ViewModel resolves new active block
5. If changed: re-render old block (styled) + new block (raw syntax)
6. updateNSView() applies changes
```

### Flow 3: Keyboard Shortcut (Cmd+B)
```
1. User selects text, presses Cmd+B
2. Menu/key handler in ShoechooTextView or EditorView
3. ViewModel toggles bold: wraps/unwraps selection with **
4. Source text modified → normal text change flow
```

### Flow 4: Task List Checkbox Click
```
1. User clicks checkbox in inactive (rendered) task list
2. ShoechooTextView detects click on checkbox region
3. Toggle: find source range of [ ] or [x], swap
4. Source text modified → normal text change flow
```

### Flow 5: IME Composition (Japanese Input)
```
1. User starts IME input (marked text appears)
2. ShoechooTextView.hasMarkedText() == true
3. ViewModel pauses parse pipeline (BR-03.1)
4. User continues composing (underlined preview text)
5. User commits composition (Enter/select candidate)
6. hasMarkedText() == false
7. ViewModel resumes parse pipeline immediately
```

---

## Keyboard Shortcut Registration

```swift
// In EditorView or ShoechooApp commands
.commands {
    CommandGroup(replacing: .textFormatting) {
        Button("Bold") { viewModel.toggleBold() }
            .keyboardShortcut("b", modifiers: .command)
        Button("Italic") { viewModel.toggleItalic() }
            .keyboardShortcut("i", modifiers: .command)
        Button("Link") { viewModel.insertLink() }
            .keyboardShortcut("k", modifiers: .command)
        Button("Inline Code") { viewModel.toggleInlineCode() }
            .keyboardShortcut("k", modifiers: [.command, .shift])
    }
    CommandGroup(after: .textFormatting) {
        ForEach(1...6, id: \.self) { level in
            Button("Heading \(level)") { viewModel.setHeading(level: level) }
                .keyboardShortcut(KeyEquivalent(Character("\(level)")), modifiers: .command)
        }
    }
}
```
