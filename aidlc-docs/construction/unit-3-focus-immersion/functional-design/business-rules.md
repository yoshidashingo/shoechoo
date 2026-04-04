# Business Rules: Unit 3 — Focus & Immersion

## BR-01: Focus Mode Dimming

| Rule | Description |
|------|-------------|
| BR-01.1 | When focus mode is enabled, all blocks except the active block MUST have their visual opacity reduced to the configured `inactiveAlpha` (default: 0.3) |
| BR-01.2 | The active block (block containing the cursor) MUST always display at full opacity (`activeAlpha`: 1.0) when focus mode is enabled |
| BR-01.3 | Dimming MUST update immediately when the cursor moves to a different block — the previously active block dims, the newly active block brightens |
| BR-01.4 | Dimming MUST NOT interfere with Unit 1 delayed rendering — active blocks still show raw syntax, inactive blocks still show styled output, regardless of focus mode state |
| BR-01.5 | Dimming MUST apply to all block types uniformly (headings, paragraphs, code blocks, lists, tables, blockquotes, horizontal rules, images) |
| BR-01.6 | Dimming alpha MUST apply to both text content and any decorative elements (bullet markers, checkbox widgets, table borders, blockquote bars) |

---

## BR-02: Active Paragraph Highlight

| Rule | Description |
|------|-------------|
| BR-02.1 | The "active paragraph" for focus mode purposes is the same block resolved by Unit 1 Active Block Resolution (business-logic-model.md step [4]) |
| BR-02.2 | ActivationScope rules from Unit 1 apply: for `wholeBlock` scope (code blocks, tables), all sibling blocks in the container are treated as active for dimming purposes |
| BR-02.3 | For `currentItem` scope (list items), only the current list item is treated as active — other items in the same list are dimmed |
| BR-02.4 | For `innerChild` scope (blockquotes), only the child block containing the cursor is treated as active — the blockquote container and other children are dimmed |
| BR-02.5 | During IME composition, the active block MUST NOT change (consistent with BR-03 from Unit 1) — dimming remains on the block where composition started |

---

## BR-03: Typewriter Scroll

| Rule | Description |
|------|-------------|
| BR-03.1 | When typewriter scrolling is enabled, the line containing the cursor MUST be scrolled to the vertical center of the visible text area |
| BR-03.2 | Typewriter scroll MUST trigger on: cursor movement (click, arrow keys), text insertion (typing), and active block change |
| BR-03.3 | Typewriter scroll MUST NOT add excessive empty space or padding for short documents — if the total document height is less than or equal to the visible area height, scrolling MUST be suppressed entirely |
| BR-03.4 | Scroll position MUST be clamped to valid bounds: no scrolling past the top of the document and no scrolling past the bottom |
| BR-03.5 | When the cursor is near the top of the document, the scroll position clamps to `minY = 0` — the line will appear above center, which is acceptable |
| BR-03.6 | When the cursor is near the bottom of the document, the scroll position clamps to `maxY = documentHeight - visibleHeight` — the line will appear below center, which is acceptable |
| BR-03.7 | Typewriter scroll MUST recalculate on window resize to maintain correct centering with the new visible area dimensions |
| BR-03.8 | Typewriter scroll and focus mode are independent features — they can be enabled/disabled separately or together |

---

## BR-04: Full-Screen Mode

| Rule | Description |
|------|-------------|
| BR-04.1 | Full-screen mode MUST use the native macOS full-screen mechanism (`NSWindow.toggleFullScreen`) — no custom full-screen implementation |
| BR-04.2 | Entering full-screen MUST auto-hide the toolbar (shown on mouse-to-top-edge hover) |
| BR-04.3 | Entering full-screen MUST collapse the sidebar (shown on mouse-to-left-edge hover) |
| BR-04.4 | Exiting full-screen MUST restore toolbar and sidebar to their pre-full-screen visibility state |
| BR-04.5 | The green title bar button MUST trigger `toggleFullScreen` (standard macOS behavior, no override needed) |
| BR-04.6 | Ctrl+Cmd+F MUST toggle full-screen mode (standard macOS shortcut) |
| BR-04.7 | Focus mode and typewriter scroll state MUST be preserved across full-screen enter/exit — they are independent of window mode |
| BR-04.8 | Auto-hide delay for toolbar and sidebar MUST be 1.5 seconds after the mouse moves away from the trigger edge |

---

## BR-05: Persistence

| Rule | Description |
|------|-------------|
| BR-05.1 | Focus mode on/off state MUST persist to `EditorSettings.defaultFocusMode` and restore on next app launch |
| BR-05.2 | Typewriter scroll on/off state MUST persist to `EditorSettings.defaultTypewriterScroll` and restore on next app launch |
| BR-05.3 | Persistence MUST use the existing `EditorSettings` mechanism from Unit 2 (UserDefaults or equivalent) |
| BR-05.4 | On first launch (no persisted value), focus mode MUST default to OFF |
| BR-05.5 | On first launch (no persisted value), typewriter scroll MUST default to OFF |
| BR-05.6 | Persisted state is global (applies to all documents) — per-document focus/typewriter state is not supported in this unit |
| BR-05.7 | Settings changes MUST be written immediately (no deferred save) to survive unexpected app termination |

---

## BR-06: Accessibility

| Rule | Description |
|------|-------------|
| BR-06.1 | When `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` is `true`, ALL transitions (dimming fade, typewriter scroll animation) MUST be applied immediately with no animation |
| BR-06.2 | When Reduce Motion is enabled, dimming alpha changes apply instantly (no fade) |
| BR-06.3 | When Reduce Motion is enabled, typewriter scroll jumps to target position instantly (no smooth scroll) |
| BR-06.4 | The app MUST observe `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification` and update transition behavior dynamically if the user changes the Reduce Motion setting while the app is running |
| BR-06.5 | Focus mode dimming MUST NOT reduce contrast below WCAG AA requirements for the active block — the active block always renders at full opacity |
| BR-06.6 | VoiceOver: focus mode dimming is purely visual — it MUST NOT affect VoiceOver navigation or text reading order |

---

## BR-07: Keyboard Shortcuts

| Shortcut | Action | Implementation |
|----------|--------|---------------|
| Cmd+Shift+F | Toggle focus mode | `EditorViewModel.toggleFocusMode()` |
| Cmd+Ctrl+T | Toggle typewriter scroll | `EditorViewModel.toggleTypewriterScroll()` |
| Ctrl+Cmd+F | Toggle full-screen | `NSWindow.toggleFullScreen(_:)` (standard macOS) |

| Rule | Description |
|------|-------------|
| BR-07.1 | Cmd+Shift+F MUST toggle focus mode regardless of whether typewriter scroll or full-screen is active |
| BR-07.2 | Ctrl+Cmd+F uses the standard macOS full-screen shortcut — no custom key handling needed if the app does not override this shortcut |
| BR-07.3 | Shortcuts MUST be registered in the SwiftUI `.commands` modifier to appear in the application menu |
| BR-07.4 | Menu items for focus mode and typewriter scroll MUST show a checkmark when the respective mode is active |
