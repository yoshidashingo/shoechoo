---
layout: default
---

# NFR Requirements: Unit 5 — Export & Polish

## Performance

### PERF-01: HTML Export Time
- **Target**: < 200ms for typical documents (up to 5,000 lines)
- **Measurement**: Wall-clock time from export action to HTML string fully generated
- **Rationale**: swift-markdown AST walk + HTML visitor is O(n) on node count; cmark-gfm parses ~1MB in < 5ms, HTML generation adds minimal overhead
- **Mitigation**: ExportService actor runs off main thread; UI remains responsive during export

### PERF-02: PDF Export Time
- **Target**: < 3s for typical documents including WKWebView rendering
- **Measurement**: Wall-clock time from export action to PDF data written to disk
- **Breakdown**: HTML generation (~200ms) + WKWebView load (~500ms) + PDF render (~1-2s)
- **Mitigation**: Progress indication shown to user; timeout at 10s with error message

### PERF-03: Sidebar Load Time
- **Target**: < 50ms for recent files list (up to 50 entries)
- **Measurement**: Time from sidebar appearance to all file entries rendered
- **Rationale**: NSDocumentController.recentDocumentURLs is an in-memory list; SwiftUI List rendering is O(n)
- **Mitigation**: Lazy loading for file metadata (size, date); only visible rows fetched

### PERF-04: Dark Mode Switch
- **Target**: < 100ms from system appearance change to editor fully re-themed, with no flash of incorrect colors
- **Measurement**: Time from `NSAppearance` change notification to final frame rendered
- **Mitigation**: Use semantic NSColor values that adapt automatically; editor re-renders only syntax highlighting colors

---

## Reliability

### REL-01: Export Output Integrity
- **Requirement**: HTML export MUST produce valid HTML5 documents with proper structure (doctype, head, body)
- **Implementation**: HTML visitor generates complete document structure; output validated against HTML5 spec in tests
- **Verification**: Export test suite asserts well-formed HTML for representative documents (headings, code blocks, tables, images)

### REL-02: PDF Generation Reliability
- **Requirement**: PDF generation via WKWebView MUST handle timeout and rendering failures gracefully
- **Implementation**: 10-second timeout on WKWebView load; `WKNavigationDelegate` error handling; retry once on transient failure
- **Error handling**: On timeout or failure, show user-friendly error "PDF export failed. Please try again." with option to export as HTML instead

### REL-03: Sidebar State Persistence
- **Requirement**: Sidebar collapsed/expanded state and selected file MUST survive app restart
- **Implementation**: Persist sidebar state via `@AppStorage` (UserDefaults); recent files managed by NSDocumentController (system-persisted)
- **Verification**: Quit and relaunch test; assert sidebar state restored

---

## Usability / Accessibility

### USA-01: Export Progress Indication
- **Requirement**: PDF export MUST show progress indication since it may take several seconds
- **Implementation**: Indeterminate progress indicator (spinning) shown in toolbar or sheet during PDF generation; dismiss on completion or error
- **Accessibility**: Progress state announced via VoiceOver (`NSAccessibilityNotificationName.valueChanged`)

### USA-02: Sidebar VoiceOver Support
- **Requirement**: Sidebar file list MUST be fully navigable and operable via VoiceOver
- **Implementation**: SwiftUI List provides built-in VoiceOver support; ensure each row has an accessible label (filename + date)
- **Verification**: Manual VoiceOver walkthrough; assert all interactive elements are reachable and labeled

### USA-03: Dark Mode Contrast Ratios
- **Requirement**: All text and interactive elements MUST meet WCAG AA contrast ratios (4.5:1 for normal text, 3:1 for large text) in both light and dark modes
- **Implementation**: Use semantic NSColor (labelColor, secondaryLabelColor, textBackgroundColor) which are pre-validated by Apple for accessibility compliance
- **Verification**: Contrast ratio spot-checks using Digital Color Meter on key UI elements in both modes

---

## Security (Baseline Extension — Applicable Rules)

### SEC-01: HTML Export Sanitization
- **Requirement**: HTML export output MUST NOT contain executable scripts or event handlers that could cause XSS when opened in a browser
- **Implementation**: HTML visitor generates only safe HTML elements; raw HTML blocks from Markdown are escaped (`<script>` becomes `&lt;script&gt;`)
- **Verification**: Export test with Markdown containing `<script>`, `onclick`, `javascript:` URI — assert all escaped in output

### SEC-02: SECURITY-09 — Export Error Messages
- **Requirement**: Export error messages shown to the user MUST be generic and not reveal internal paths, stack traces, or system details
- **Implementation**: Log detailed errors internally via `os.Logger`; show "Export failed. Please try again." to user
- **Verification**: Trigger export failures in tests; assert user-facing message contains no file paths or technical details

### SEC-03: WKWebView Security
- **Requirement**: WKWebView used for PDF rendering MUST NOT access external network resources
- **Implementation**: Configure `WKWebViewConfiguration` with no network access: set `WKPreferences` to disable JavaScript (not needed for static HTML), use `loadHTMLString` (not URL loading), and set `WKWebViewConfiguration.websiteDataStore` to non-persistent
- **Verification**: Monitor network traffic during PDF export; assert zero outbound connections

---

## Testability

### TEST-01: ExportService HTML Output Testability
- **Requirement**: HTML export MUST be testable as a pure function: input Markdown string, assert output HTML string
- **Test approach**: Call `ExportService.exportHTML(markdown:)` with representative Markdown inputs; assert output contains expected HTML elements, structure, and escaped content

### TEST-02: SidebarView Snapshot Tests
- **Requirement**: SidebarView appearance MUST be verifiable via snapshot tests for both light and dark modes
- **Test approach**: Render SidebarView with mock data in a fixed-size hosting window; capture snapshot; compare against reference images

### TEST-03: Dark Mode Color Assertions
- **Requirement**: Editor and sidebar colors MUST be testable for correct adaptation to light/dark appearance
- **Test approach**: Set `NSAppearance.current` to `.aqua` and `.darkAqua`; resolve semantic colors; assert resolved RGB values differ and meet minimum contrast ratios
