# NFR Requirements: Unit 3 — Focus & Immersion

## Performance

### PERF-01: Focus Mode Toggle Latency
- **Target**: < 16ms (60fps) from toggle action to visual update; no frame drop
- **Measurement**: Time from `EditorViewModel.toggleFocusMode()` call to NSTextLayoutFragment alpha values applied on screen
- **Applicable to**: Keyboard shortcut toggle, menu item toggle, toolbar button
- **Mitigation**: Pre-calculate dimming values; apply alpha changes in a single layout pass via `NSTextLayoutManager`

### PERF-02: Dimming Recalculation on Cursor Move
- **Target**: < 8ms per cursor move event (well within 16ms frame budget)
- **Measurement**: Wall-clock time from `NSTextView.didChangeSelection` to all NSTextLayoutFragment alpha values updated
- **Rationale**: Only the previous and current active paragraph need alpha changes; not a full-document operation
- **Mitigation**: Track previous active paragraph; only update two fragments (dim previous, undim current); skip if cursor remains in same paragraph

### PERF-03: Typewriter Scroll Animation
- **Target**: Smooth 60fps scrolling with no jank during typewriter scroll repositioning
- **Measurement**: Frame drops measured via CADisplayLink / Instruments during continuous typing with typewriter mode enabled
- **Mitigation**: Use `NSView.scrollRangeToVisible` with calculated offset; leverage Core Animation for smooth interpolation; batch scroll updates with typing events

---

## Reliability

### REL-01: Focus Mode State Consistency
- **Requirement**: Focus mode visual state MUST always match EditorViewModel.isFocusModeEnabled; no desync between model and view
- **Implementation**: Single source of truth in EditorViewModel; ShoechooTextView observes @Observable property; state restored on view re-creation (e.g., window restore)
- **Edge cases**: Toggle during IME composition (defer until composition commits); toggle during text selection (apply immediately); app backgrounded with focus mode active (preserve state)

### REL-02: Full-Screen Enter/Exit Stability
- **Requirement**: Entering and exiting native full-screen MUST NOT corrupt editor layout, lose scroll position, or desync focus mode state
- **Implementation**: Use `NSWindow` native full-screen via `toggleFullScreen(_:)`; listen to `NSWindow.willEnterFullScreenNotification` / `didExitFullScreenNotification` to re-validate layout
- **Verification**: Toggle full-screen rapidly 10 times; verify no layout artifacts, correct scroll position, focus mode state preserved

---

## Usability / Accessibility

### USA-01: Reduce Motion Compliance
- **Requirement**: When macOS "Reduce motion" is enabled, all focus mode and typewriter scroll transitions MUST use instant (zero-duration) transitions instead of animations
- **Implementation**: Check `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`; if true, set `NSAnimationContext.current.duration = 0` for all focus/scroll animations
- **Observation**: Watch for runtime changes via `NSWorkspace.accessibilityDisplayOptionsDidChangeNotification`

### USA-02: VoiceOver with Focus Mode
- **Requirement**: Dimmed text MUST remain fully accessible to VoiceOver; visual dimming MUST NOT affect accessibility tree content
- **Implementation**: Dimming is purely visual (alpha on NSTextLayoutFragment); `NSTextContentStorage` accessibility text remains unchanged; VoiceOver reads all paragraphs regardless of dimming state
- **Verification**: Enable VoiceOver + focus mode; navigate all paragraphs with VO+arrow keys; confirm all content is read

### USA-03: Focus Mode Visual Contrast
- **Requirement**: Dimmed paragraph alpha MUST be readable, not invisible; active paragraph MUST have clear visual distinction
- **Implementation**: Dimmed alpha value range: 0.3-0.5 (configurable in EditorSettings); active paragraph alpha: 1.0; respect "Increase contrast" accessibility setting by raising dimmed alpha floor to 0.5
- **Verification**: Test with macOS "Increase contrast" enabled; verify WCAG 2.1 AA minimum contrast ratio for dimmed text against background

---

## Security

No additional security requirements beyond Unit 1 baseline. Focus and immersion features operate entirely within the existing editor surface with no additional file I/O, network access, or external data processing.

---

## Testability

### TEST-01: Focus Mode Toggle Testable via ViewModel
- **Requirement**: Focus mode toggle logic MUST be testable by calling EditorViewModel methods without instantiating any view
- **Test approach**: Create EditorViewModel; call `toggleFocusMode()`; assert `isFocusModeEnabled` flipped; assert `activeParagraphRange` and `dimmedParagraphRanges` computed correctly for known document content

### TEST-02: Typewriter Scroll Offset Calculation Testable Independently
- **Requirement**: Typewriter scroll offset calculation MUST be a pure function testable without NSTextView
- **Test approach**: Input: visible rect height, cursor rect origin, desired center offset; output: scroll point; assert correct Y offset for various cursor positions (top, middle, bottom, near document start/end)

### TEST-03: Dimming Alpha Values Testable
- **Requirement**: Dimming alpha assignment logic MUST be testable with mock paragraph ranges
- **Test approach**: Input: array of paragraph ranges, active paragraph index, EditorSettings (dimmedAlpha value); output: array of (range, alpha) pairs; assert active paragraph gets 1.0, all others get configured dimmed alpha
