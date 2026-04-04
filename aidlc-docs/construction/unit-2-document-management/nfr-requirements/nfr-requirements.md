# NFR Requirements: Unit 2 — Document Management

## Performance

### PERF-01: Document Open Time
- **Target**: < 200ms for files up to 1MB
- **Measurement**: Wall-clock time from `NSDocument.read(from:ofType:)` entry to EditorViewModel receiving parsed content
- **Applicable to**: File > Open, recent documents, double-click from Finder
- **Mitigation**: Streaming read for large files; defer full parse to background actor; show placeholder immediately

### PERF-02: Save Latency
- **Target**: < 100ms for typical documents (< 100KB)
- **Measurement**: Wall-clock time from `NSDocument.data(ofType:)` entry to file write completion
- **Applicable to**: Cmd+S, auto-save trigger, window close save prompt
- **Mitigation**: Write to temporary file then atomic rename; avoid re-encoding unless content changed

### PERF-03: Auto-Save Impact
- **Target**: No perceptible UI stutter during auto-save (zero dropped frames at 60fps)
- **Measurement**: Frame drops measured via CADisplayLink / Instruments during auto-save on a 500KB document
- **Rationale**: NSDocument auto-save runs on a background thread by default; ensure no main-thread blocking
- **Mitigation**: `NSDocument.autosavesInPlace = true` leverages system-managed background saves; avoid synchronous I/O on main thread

### PERF-04: EditorSettings Load Time
- **Target**: < 50ms from UserDefaults read to EditorViewModel configuration applied
- **Measurement**: Wall-clock time from `EditorSettings.init()` to all @Published properties set
- **Rationale**: UserDefaults reads are synchronous but fast for small key-value sets (< 20 keys)
- **Mitigation**: Load once at app launch; observe changes via @AppStorage or `NotificationCenter`

---

## Reliability

### REL-01: Data Integrity
- **Requirement**: No data loss on app crash, force quit, or power failure
- **Implementation**: `NSDocument.autosavesInPlace = true` provides system-managed auto-save and Versions; crash recovery via macOS Resume
- **Verification**: Kill process during edit; relaunch must recover last auto-saved state
- **Additional safeguard**: FileService writes use atomic `Data.write(to:options: .atomic)` for explicit saves

### REL-02: Concurrent Document Access
- **Requirement**: Multiple windows/tabs editing different documents MUST NOT interfere with each other
- **Implementation**: Each DocumentGroup window gets its own MarkdownDocument instance and EditorViewModel; no shared mutable state between documents
- **Edge case**: Same file opened twice — NSDocument framework prevents this by default (brings existing window forward)

### REL-03: Large File Handling
- **Requirement**: Files > 5MB MUST open without crash; graceful degradation permitted
- **Degradation**: Files > 5MB may show a warning and disable live preview; files > 20MB may be rejected with a clear error message
- **Implementation**: Check file size in `NSDocument.read(from:ofType:)` before loading; display alert for oversized files
- **Hard limit**: Reject files > 50MB with "File too large for editing" message

---

## Usability / Accessibility

### USA-01: VoiceOver for Toolbar and Preferences
- **Requirement**: All toolbar buttons and preference controls MUST be accessible via VoiceOver
- **Implementation**: Set `accessibilityLabel` and `accessibilityHint` on all toolbar items; SwiftUI controls provide built-in VoiceOver support
- **Verification**: Navigate entire toolbar and preferences pane using VoiceOver without losing context

### USA-02: Keyboard Navigation for All Toolbar Actions
- **Requirement**: Every toolbar action MUST have a keyboard shortcut or be reachable via Tab navigation
- **Implementation**: Assign `keyboardShortcut` modifiers to all toolbar buttons; ensure focus ring visible on active control
- **Applicable to**: New, Open, Save, Preferences, toolbar toggle actions

---

## Security (Baseline Extension — Applicable Rules)

### SEC-01: SECURITY-05 — File Path Validation
- **Requirement**: All file paths for open/save MUST be validated before I/O operations
- **Validation**: Reject paths with `../` traversal; validate within App Sandbox container or user-granted directories (Security-Scoped Bookmarks); reject symbolic links pointing outside sandbox
- **Applicability**: NSDocument open, save, save-as, recent documents, drag-and-drop file open

### SEC-02: SECURITY-09 — Error Messages for File I/O Failures
- **Requirement**: File I/O errors MUST show user-friendly messages without exposing internal paths or system details
- **Implementation**: Log detailed errors (path, errno, stack) to unified logging (`os_log`); show generic "Unable to open document" / "Unable to save document" to user with recovery suggestions
- **Error categories**: Permission denied, file not found, disk full, encoding error, file locked

### SEC-03: Sandbox Compliance
- **Requirement**: App MUST run within App Sandbox for Mac App Store distribution
- **Implementation**: Enable App Sandbox entitlement; use `com.apple.security.files.user-selected.read-write` for user-opened files; persist access via Security-Scoped Bookmarks for recent documents
- **Verification**: Test all file operations with sandbox enabled; verify no sandbox violation logs in Console.app

---

## Testability

### TEST-01: MarkdownDocument Testable Without UI
- **Requirement**: MarkdownDocument read/write logic MUST be testable without instantiating any view
- **Test approach**: Create MarkdownDocument, call `read(from: Data, ofType:)` with sample Markdown data, assert content string matches; call `data(ofType:)` and assert output data matches expected bytes

### TEST-02: EditorSettings Persistence Testable with Mock UserDefaults
- **Requirement**: EditorSettings read/write MUST be testable with injected UserDefaults (not polluting production defaults)
- **Test approach**: Create `UserDefaults(suiteName:)` with unique test suite name; inject into EditorSettings; write values, re-read, assert round-trip correctness; remove suite after test

### TEST-03: EditorView Snapshot Tests
- **Requirement**: EditorView layout MUST be verifiable via snapshot tests for key states
- **Test approach**: Render EditorView with known EditorSettings and document content into NSHostingView; capture snapshot; compare against reference image with tolerance for font rendering differences
- **States to capture**: Empty document, short document, long document (scrolled), preferences panel open
