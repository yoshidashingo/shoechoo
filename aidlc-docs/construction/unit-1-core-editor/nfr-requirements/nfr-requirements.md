# NFR Requirements: Unit 1 — Core Editor Engine

## Performance

### PERF-01: Keystroke-to-Render Latency
- **Target**: < 16ms (60fps) from keystroke to visual update on typical documents (< 5,000 lines)
- **Measurement**: Time from `NSTextStorageDelegate` callback to `NSTextLayoutManager` completing layout for changed ranges
- **Applicable to**: Text insertion, deletion, cursor movement, active block switch
- **Mitigation**: 50ms parse debounce, selective block re-rendering, render cache

### PERF-02: Parse Performance
- **Target**: Full document parse < 10ms for documents up to 10,000 lines
- **Measurement**: Wall-clock time of `MarkdownParser.parse()` call
- **Rationale**: swift-markdown uses cmark-gfm (C implementation), which parses ~1MB in < 5ms
- **Mitigation**: Background actor for parsing, stale result discarding via documentRevision

### PERF-03: Memory — Editor Model
- **Target**: EditorNodeModel + RenderCache < 20MB for documents up to 10,000 lines
- **Measurement**: Instruments Allocations trace on a 10K-line GFM document
- **Breakdown estimate**: ~2KB per EditorNode × 10,000 = ~20MB (nodes + inline runs + cached attributed strings)

### PERF-04: Diff Performance
- **Target**: Diff & merge < 5ms for typical edits (position-based comparison)
- **Measurement**: Time from parse result arrival to EditorNodeModel update completion
- **Rationale**: Position-based diff with contentHash is O(n) where n = block count

### PERF-05: Rendering Performance
- **Target**: Single block re-render < 2ms
- **Measurement**: Time for `MarkdownRenderer.render()` or `renderActiveBlock()` per block
- **Mitigation**: Only re-render changed blocks; cache unchanged results

---

## Reliability

### REL-01: Malformed Markdown Handling
- **Requirement**: The editor MUST NOT crash on any Markdown input, including malformed or adversarial content
- **Implementation**: swift-markdown/cmark-gfm produces best-effort AST for any input; EditorNodeModel handles empty/unexpected node types gracefully

### REL-02: IME Robustness
- **Requirement**: IME composition MUST NOT corrupt document state or trigger incorrect rendering
- **Implementation**: Parse pipeline pauses during marked text; active block state frozen; resume on composition commit

### REL-03: Large Document Handling
- **Requirement**: Editor MUST remain usable (no hang, no crash) for documents up to 50,000 lines
- **Degradation**: Acceptable to increase parse debounce (100-200ms) and reduce re-render frequency for very large documents
- **Hard limit**: Display warning for documents > 100,000 lines

---

## Usability / Accessibility

### USA-01: VoiceOver
- **Requirement**: Editor text MUST be accessible via macOS VoiceOver
- **Implementation**: NSTextView provides built-in VoiceOver support; ensure custom rendering does not break accessibility attributes

### USA-02: Dynamic Type
- **Requirement**: Editor MUST respect user-configured font size from EditorSettings
- **Implementation**: All rendered NSAttributedStrings use EditorSettings.fontSize as base

### USA-03: Reduced Motion
- **Requirement**: If macOS "Reduce motion" is enabled, typewriter scrolling and focus mode transitions MUST use instant transitions instead of animations
- **Implementation**: Check `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`

---

## Security (Baseline Extension — Applicable Rules)

### SEC-01: SECURITY-05 — Input Validation (File Paths)
- **Requirement**: Image `src` paths in Markdown MUST be validated before file access
- **Validation**: Reject absolute paths outside sandbox scope, reject `../` traversal, validate URL scheme (only `file://` or relative)
- **Applicability**: Inline image display (Story 1.9), rendered link Cmd+click (Story 1.3)

### SEC-02: SECURITY-09 — Error Handling (User-Facing)
- **Requirement**: Parse errors, rendering errors, and file I/O errors MUST show generic messages to the user
- **Implementation**: Log detailed errors internally; show "Unable to render element" or "Image not found" to user

### SEC-03: SECURITY-10 — Supply Chain (Dependencies)
- **Requirement**: swift-markdown and Highlightr MUST be pinned to exact versions in Package.resolved
- **Verification**: Package.resolved committed to git; `swift package resolve` produces deterministic output

### SEC-04: SECURITY-15 — Exception Handling
- **Requirement**: All file I/O in image display (loading image from path) MUST have explicit error handling with resource cleanup
- **Implementation**: `try`/`catch` around image loading; return placeholder on failure; no unhandled exceptions

---

## Testability

### TEST-01: Parser Testability
- **Requirement**: MarkdownParser MUST be testable independently with no UI dependencies
- **Test approach**: Input Markdown string → assert EditorNode array matches expected structure

### TEST-02: Renderer Testability
- **Requirement**: MarkdownRenderer MUST be testable with mock EditorNodes, no live NSTextView required
- **Test approach**: Input EditorNode → assert NSAttributedString attributes (font, color, style)

### TEST-03: EditorNodeModel Testability
- **Requirement**: Diff, merge, and active block resolution MUST be testable independently
- **Test approach**: Create model, apply parse result, assert block IDs preserved/changed correctly

### TEST-04: Integration Test
- **Requirement**: Full pipeline (type text → parse → model → render → attributed string) MUST be testable as integration
- **Test approach**: Input source text + cursor position → assert final NSAttributedString has correct styled/raw blocks
