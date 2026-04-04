# Business Logic Model: Unit 3 — Focus & Immersion

## Pipeline Overview

```
User toggles focus mode / typewriter scroll / full-screen
    |
    v
[1] State Toggle (EditorViewModel)
    | Update isFocusModeEnabled / isTypewriterScrollEnabled
    | Persist to EditorSettings
    v
[2] Active Block Tracking (from Unit 1 pipeline)
    | Cursor move → resolve active block
    | Emit ActiveBlockRange
    v
[3] Focus Mode Dimming (if enabled)
    | Compute dimming for all NSTextLayoutFragments
    | Apply alpha to inactive blocks
    | Full alpha on active block
    v
[4] Typewriter Scroll (if enabled)
    | Compute center offset of visible rect
    | Scroll active line to center
    | Guard: suppress for short documents
    v
[5] Full-Screen Integration
    | Enter/exit native full-screen
    | Auto-hide toolbar and sidebar
    | Restore on exit
```

---

## [1] State Toggle

**Trigger**: User keyboard shortcut or menu item

### Focus Mode Toggle

**Input**: Current `isFocusModeEnabled` state

**Logic**:
1. Flip `isFocusModeEnabled` boolean
2. If enabling:
   - Resolve current `ActiveBlockRange` from `EditorNodeModel`
   - Call `applyFocusModeDimming(activeBlockRange:)` on `ShoechooTextView`
3. If disabling:
   - Call `removeFocusModeDimming()` on `ShoechooTextView`
   - Restore all blocks to full alpha
4. Persist new value to `EditorSettings.defaultFocusMode`

### Typewriter Scroll Toggle

**Input**: Current `isTypewriterScrollEnabled` state

**Logic**:
1. Flip `isTypewriterScrollEnabled` boolean
2. If enabling:
   - Compute active line position
   - Call `scrollToCenterLine(_:)` on `ShoechooTextView`
3. If disabling:
   - No immediate scroll action (scroll position stays where it is)
4. Persist new value to `EditorSettings.defaultTypewriterScroll`

---

## [2] Active Block Tracking

This step reuses the Active Block Resolution logic from Unit 1 (business-logic-model.md, step [4]). The output is extended to include layout geometry for dimming and scrolling.

**Input**: `cursorPosition: Int`, `EditorNodeModel`, `NSTextLayoutManager`

**Logic**:
1. Resolve active block via Unit 1 logic (cursor → innermost block → ActivationScope)
2. Query `NSTextLayoutManager` for the `NSTextLayoutFragment` of the active block:
   - `textLayoutManager.textLayoutFragment(for: textPosition)`
3. Compute `ActiveBlockRange`:
   - `blockID`: from the resolved `EditorNode`
   - `textRange`: `NSRange` of the block in `NSTextStorage`
   - `layoutRect`: `layoutFragmentFrame` from the layout fragment
4. If `activeBlockID` changed from previous:
   - Emit the new `ActiveBlockRange` to both dimming and scroll pipelines
   - Re-run dimming pass (step [3])
   - Re-run typewriter scroll (step [4])

---

## [3] Focus Mode Dimming

**Input**: `ActiveBlockRange`, `NSTextLayoutManager`, `DimmingConfiguration`

**Precondition**: `isFocusModeEnabled == true`

**Logic**:
1. Enumerate all `NSTextLayoutFragment` instances via `NSTextLayoutManager.enumerateTextLayoutFragments(from:options:using:)`
2. For each fragment:
   - If fragment's range overlaps `ActiveBlockRange.textRange`:
     - Set `fragment.alphaValue = dimmingConfiguration.activeAlpha` (1.0)
   - Else:
     - Set `fragment.alphaValue = dimmingConfiguration.inactiveAlpha` (0.3)
3. Determine transition style:
   - Query `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`
   - If reduce motion: apply alpha changes immediately (no animation)
   - Else: animate alpha changes with `NSAnimationContext` (duration: 0.2s)
4. Request display update on the text view

### Dimming Removal

**Trigger**: Focus mode disabled

**Logic**:
1. Enumerate all `NSTextLayoutFragment` instances
2. Set `fragment.alphaValue = 1.0` for all fragments
3. Apply transition (animated or immediate per accessibility setting)

### Implementation Note

`NSTextLayoutFragment` does not natively expose an `alphaValue` property. The actual implementation uses one of these approaches:
- **Approach A (preferred)**: Override `NSTextLayoutFragment.draw(at:in:)` to apply `CGContext.setAlpha()` before drawing
- **Approach B**: Use a custom `NSTextLayoutFragmentProvider` layer with alpha manipulation
- **Approach C**: Apply alpha via `NSAttributedString` foreground color with reduced alpha on inactive block ranges

The chosen approach must not interfere with Unit 1 rendering (active block raw syntax vs. styled output).

---

## [4] Typewriter Scroll

**Input**: `ActiveBlockRange`, `NSScrollView` (enclosing `ShoechooTextView`), `TypewriterScrollState`

**Precondition**: `isTypewriterScrollEnabled == true`

**Logic**:
1. **Short document guard**:
   - Get `documentHeight` from `NSTextLayoutManager.usageBoundsForTextContainer.height`
   - Get `visibleHeight` from `NSScrollView.contentView.bounds.height`
   - If `documentHeight <= visibleHeight`: set `scrollBehavior = .suppressed`, return (no scroll)
2. **Compute center target**:
   - `visibleCenter = visibleHeight / 2.0`
   - `activeLineCenter = ActiveBlockRange.layoutRect.midY`
   - `targetScrollY = activeLineCenter - visibleCenter`
3. **Clamp scroll position**:
   - `minY = 0`
   - `maxY = documentHeight - visibleHeight`
   - `clampedY = max(minY, min(maxY, targetScrollY))`
4. **Apply scroll**:
   - Query `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`
   - If reduce motion: `scrollView.contentView.scroll(to: NSPoint(x: 0, y: clampedY))` immediately
   - Else: `NSAnimationContext.runAnimationGroup` with duration 0.15s, `scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: clampedY))`
5. Call `scrollView.reflectScrolledClipView(scrollView.contentView)`

### Typewriter Scroll Triggering

| Event | Action |
|-------|--------|
| Cursor move (arrow keys, click) | Scroll to center active line |
| Text insertion (typing) | Scroll to center active line |
| Window resize | Recalculate center offset, scroll if needed |
| Active block change | Scroll to center new active line |
| Document load | Scroll to center initial cursor position |

---

## [5] Full-Screen Integration

**Input**: User action (Ctrl+Cmd+F or green title bar button)

**Logic**:

### Entering Full-Screen

1. Call `NSWindow.toggleFullScreen(_:)` (standard macOS API)
2. In `windowDidEnterFullScreen(_:)` delegate callback:
   - Set `fullScreenState.isFullScreen = true`
   - Set `toolbarPolicy = .autoHide`
   - Set `sidebarPolicy = .hidden`
   - Configure `NSWindow.toolbar?.isVisible` with auto-hide behavior
   - Collapse sidebar via `NSSplitViewController` or SwiftUI `NavigationSplitView` visibility

### Exiting Full-Screen

1. Call `NSWindow.toggleFullScreen(_:)` or user presses Esc / Ctrl+Cmd+F
2. In `windowDidExitFullScreen(_:)` delegate callback:
   - Set `fullScreenState.isFullScreen = false`
   - Set `toolbarPolicy = .alwaysVisible`
   - Set `sidebarPolicy = .visible`
   - Restore toolbar visibility
   - Restore sidebar state to pre-full-screen value

### Auto-Hide Behavior (Full-Screen)

| Element | Trigger to Show | Trigger to Hide |
|---------|----------------|----------------|
| Toolbar | Move mouse to top edge of screen | Mouse moves away from top edge (after 1.5s delay) |
| Sidebar | Move mouse to left edge of screen | Mouse moves away from sidebar area (after 1.5s delay) |

---

## Initialization & Restore on App Launch

**Trigger**: Document opens, `EditorViewModel.init()`

**Logic**:
1. Read `EditorSettings.defaultFocusMode` → set `isFocusModeEnabled`
2. Read `EditorSettings.defaultTypewriterScroll` → set `isTypewriterScrollEnabled`
3. After first layout pass completes:
   - If focus mode enabled: apply dimming on initial active block
   - If typewriter scroll enabled: scroll to center initial cursor position
