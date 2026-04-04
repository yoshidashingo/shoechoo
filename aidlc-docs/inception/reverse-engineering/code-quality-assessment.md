# Code Quality Assessment

## Test Coverage

### Test File Inventory

| Test File | Tests | Lines | Covers |
|-----------|-------|-------|--------|
| `HTMLConverterTests.swift` | 18 | 218 | `HTMLConverter` (ExportService.swift) -- headings, paragraphs, emphasis, strong, strikethrough, inline code, code blocks, lists, task lists, blockquotes, tables, links, images, thematic breaks, HTML escaping |
| `MarkdownParserTests.swift` | 15 | 247 | `MarkdownParser` -- empty input, paragraphs, headings 1-6, code blocks (with/without language), unordered/ordered/task lists, blockquotes, tables, horizontal rules, inline runs (bold, italic, link, code), mixed documents, revision propagation |
| `EditorNodeTests.swift` | 16 | 191 | `EditorNode` -- activation scope for all 12 BlockKind values, equality semantics, contentHash consistency, default state (isActive, children, inlineRuns) |
| `EditorNodeModelTests.swift` | 14 | 264 | `EditorNodeModel` -- parse result application, revision gating, position-based diff/ID preservation, active block resolution (first/second block, empty model, gap, past-end), setActiveBlock flag updates, block lookup (top-level and child) |
| `SyntaxHighlighterTests.swift` | 26 | 535 | `SyntaxHighlighter` -- paragraph/heading/code/bold/link/Japanese styling, WYSIWYG delimiter hiding for all block types, active vs inactive states, heading font sizes H1-H5, strikethrough/boldItalic, edge cases (emoji, malformed) |
| `ThemeTests.swift` | 9 | 109 | `ThemeColor` (NSColor conversion, hex parsing, Codable), `ThemePresets` (count, heading colors, unique IDs, default), `ThemeRegistry` (default/change/fallback/listing) |

**Total: 98 tests across 6 test files (1,564 lines)**

### Coverage Analysis

| Component | Tested | Coverage Estimate | Notes |
|-----------|--------|-------------------|-------|
| MarkdownParser | Yes | ~90% | All block types and inline runs tested. Unicode edge cases partially covered |
| EditorNode / EditorNodeModel | Yes | ~85% | All activation scopes, diff logic, and active block resolution tested |
| SyntaxHighlighter | Yes | ~80% | All block types tested for active/inactive states. WYSIWYG hiding verified |
| HTMLConverter | Yes | ~90% | All HTML element types tested with escaping verification |
| EditorTheme / ThemePresets / ThemeRegistry | Yes | ~85% | Codable, color conversion, preset validation, registry resolution |
| EditorViewModel | Partial | ~30% | Only tested indirectly through parser/highlighter tests. No direct tests for toggleBold, toggleItalic, setHeading, headings computation, statistics, export |
| WYSIWYGTextView / Coordinator | No | ~0% | Requires NSTextView runtime. Not unit-testable without AppKit integration |
| ShoechooTextView | No | ~0% | Auto-pair, drag-and-drop, focus dimming, typewriter scroll untested |
| EditorView / SidebarView / OutlineView / PreferencesView | No | ~0% | SwiftUI views -- require UI testing or snapshot tests |
| MarkdownDocument | No | ~0% | ReferenceFileDocument lifecycle untested |
| ExportService (PDF) | No | ~0% | Requires WKWebView runtime |
| FileService / ImageService | No | ~0% | I/O actors untested (would need temp directory fixtures) |
| EditorSettings | Partial | ~20% | Only tested as dependency in ThemeRegistry tests |

**Estimated overall coverage: ~45-50%** (below the 80% target stated in CLAUDE.md)

### Untested Critical Paths
1. **Document save/load cycle** -- `MarkdownDocument.snapshot()`, `fileWrapper()`, init from file
2. **ViewModel formatting commands** -- `toggleBold()`, `toggleItalic()`, `insertLink()`, `setHeading()`
3. **Auto-save mechanism** -- `Coordinator.scheduleAutoSave()`, `performAutoSave()`
4. **Image import pipeline** -- `ImageService.importDroppedImage()`, path validation, size limit
5. **Coordinator notification handling** -- `handleToggleFormatting()`, `handleSetLinePrefix()`

## Code Quality Metrics

### File Size Compliance

All source files are under the 800-line maximum. The largest source file is `SyntaxHighlighter.swift` at 506 lines, which is within limits but approaching the 400-line guideline.

| Threshold | Files |
|-----------|-------|
| < 100 lines | 8 files (ParseResult, FileService, ThemeRegistry, OutlineView, EditorTheme, EditorSettings, MarkdownDocument, PreferencesView) |
| 100-200 lines | 5 files (EditorNode, EditorNodeModel, EditorViewModel, ShoechooApp, ThemePresets) |
| 200-400 lines | 5 files (ShoechooTextView, MarkdownParser, ExportService, ImageService, SidebarView) |
| 400-600 lines | 2 files (WYSIWYGTextView at 392, SyntaxHighlighter at 506) |

### Function Size Compliance

Most functions are under 50 lines. Notable larger functions:
- `SyntaxHighlighter.applyListItem()` (~35 lines) -- within limits
- `SyntaxHighlighter.applyTable()` (~68 lines) -- **exceeds 50-line guideline**
- `WYSIWYGTextView.Coordinator.applyHighlightNow()` (~35 lines) -- within limits
- `ShoechooTextView.insertText()` (~50 lines) -- borderline

### Code Style Consistency

- **Naming**: Follows Apple API Design Guidelines consistently
- **Access control**: Generally appropriate; some internal access could be tightened to `private`
- **MARK comments**: Used consistently for section organization
- **Documentation**: Sparse. Only `SyntaxHighlighter` and `ExportService.HTMLConverter` have doc comments. Most types and functions lack documentation
- **SwiftLint/SwiftFormat**: Not configured in the project (no `.swiftlint.yml` or `.swiftformat` file)

## Technical Debt -- Detailed List

### TD-01: NotificationCenter Dependency -- Type Safety Problem

**Location**: `EditorViewModel.swift:144-168`, `WYSIWYGTextView.swift:304-339`

**Problem**: Five notification names are used for ViewModel-to-NSTextView communication:
- `.toggleFormatting` -- userInfo: `["prefix": String, "suffix": String]`
- `.insertFormattedText` -- userInfo: `["text": String, "cursorOffset": Int]`
- `.setLinePrefix` -- userInfo: `["prefix": String]`
- `.insertImageMarkdown` -- userInfo: `["markdown": String, "position": Int]`
- `.scrollToPosition` -- userInfo: `["position": Int]`

All userInfo values are `[String: Any]` dictionaries requiring force-casting (`as? String`, `as? Int`) at the receiver. No compile-time type checking. Refactoring a key name (e.g., "prefix" to "formatting_prefix") would silently break at runtime.

**Impact**: HIGH. Silent failures when types or keys are mismatched. No compiler help during refactoring. Violates type-safety principles of Swift.

**Fix Direction**: Replace with a protocol/delegate pattern or closure-based callback. Define a `TextViewCommandHandler` protocol with methods like `toggleFormatting(prefix:suffix:)`, `insertText(_:cursorOffset:)`, `setLinePrefix(_:)`. The Coordinator implements the protocol and is set as a delegate on the ViewModel.

### TD-02: nonisolated(unsafe) Usage

**Location**: `MarkdownDocument.swift:12,17-18,77`, `WYSIWYGTextView.swift:101-102`

**Problem**: Five uses of `nonisolated(unsafe)`:
1. `MarkdownDocument.viewModel` (line 12) -- accessed from both main thread and background init
2. `MarkdownDocument.lock` (line 17) -- NSLock is not Sendable
3. `MarkdownDocument._snapshotText` (line 18) -- guarded by lock but compiler cannot verify
4. `MarkdownDocument.fileURL` (line 77) -- no synchronization
5. `WYSIWYGTextView.Coordinator.highlightTimer` (line 101) -- Timer accessed from main thread only
6. `WYSIWYGTextView.Coordinator.autoSaveTimer` (line 102) -- Timer accessed from main thread only
7. `WYSIWYGTextView.Coordinator.notificationObservers` (line 103) -- array of observers

**Impact**: MEDIUM. The `MarkdownDocument` cases (1-4) are necessary because `ReferenceFileDocument` requires `Sendable` conformance but the document initializer may be called off-main-thread. The `_snapshotText` is properly guarded by `NSLock`. The `fileURL` (4) has NO synchronization and is a potential data race. The Coordinator cases (5-7) are safe in practice (main-thread only) but the compiler cannot verify this.

**Fix Direction**:
- `MarkdownDocument.fileURL` should be guarded by the existing `NSLock` or converted to an actor-isolated property
- Coordinator timers: Use `@MainActor`-isolated properties once Timer gains Sendable conformance, or wrap in a MainActor-bound helper
- Consider wrapping `_snapshotText` and `lock` into a dedicated `Sendable` wrapper type

### TD-03: ARCHITECTURE.md and Implementation Divergences

**Location**: `ARCHITECTURE.md` vs actual source code

**Divergences found**:

1. **Directory naming**: ARCHITECTURE.md lists `Highlighter/SyntaxHighlighter.swift` (line 79) but actual directory is `Renderer/SyntaxHighlighter.swift`
2. **SidebarView description**: ARCHITECTURE.md describes it as "Recent files list" (line 87) but actual implementation has three modes: Outline, File Tree, and File List (sorted by modification date, not "recent")
3. **ThemePresets/ThemeRegistry not listed**: ARCHITECTURE.md lists only `EditorTheme.swift` in the Theme directory but `ThemePresets.swift` (148 lines) and `ThemeRegistry.swift` (17 lines) are missing from the directory listing
4. **EditorNodeModel isolation**: ARCHITECTURE.md states `EditorNodeModel` is `@unchecked Sendable` (line 164) but actual code uses `@Observable @MainActor` with no Sendable conformance (EditorNodeModel.swift:4)
5. **Debounce mechanism**: ARCHITECTURE.md states "Parse scheduling uses `Task` with a 150ms sleep" (line 171) but actual implementation uses `Timer.scheduledTimer(withTimeInterval: 0.15)` (WYSIWYGTextView.swift:150)
6. **Highlightr integration**: ARCHITECTURE.md lists Highlightr for "code blocks" in tech stack (line 14), and `EditorTheme` has a `highlightrTheme` property, but no file actually `import Highlightr`. The dependency is declared in `project.yml` but unused in code.
7. **Data flow diagram**: States `EditorViewModel.textDidChange()` is called, but actually `Coordinator.textDidChange()` directly updates `parent.viewModel.sourceText` and calls `scheduleHighlight()` -- the ViewModel has no `textDidChange()` method

**Impact**: MEDIUM. Outdated documentation misleads new contributors. The EditorNodeModel isolation discrepancy (4) is particularly confusing for concurrency reasoning.

**Fix Direction**: Update ARCHITECTURE.md to match actual implementation. Either remove Highlightr from dependencies or complete its integration for code block syntax highlighting.

### TD-04: isRichText=false with Rich Attribute Manipulation

**Location**: `WYSIWYGTextView.swift:22`, `SyntaxHighlighter.swift` (entire file)

**Problem**: `textView.isRichText = false` is set during NSTextView creation, but `SyntaxHighlighter` extensively manipulates rich text attributes (fonts, colors, paragraph styles, strikethrough, underline, background colors) on the text storage. This works because `NSTextStorage` attribute APIs are independent of `isRichText`, but it creates a semantic contradiction:
- `isRichText = false` tells AppKit the view holds plain text, affecting paste behavior, typing attributes, and undo grouping
- The highlighting code treats the text storage as a richly attributed string

Additionally, `typingAttributes` are set with font and foreground color (WYSIWYGTextView.swift:143), which is a rich-text concept.

**Impact**: LOW-MEDIUM. Currently functional because the highlighter re-applies all attributes after each edit. However:
- Pasting rich text from external apps may strip formatting unexpectedly
- Undo may not group attribute changes correctly
- Future features (e.g., cursor-position-aware typing attributes) may behave unexpectedly

**Fix Direction**: This is an intentional design tradeoff documented in CLAUDE.md -- plain text editing with visual overlay. If issues arise, consider switching to `isRichText = true` with careful paste filtering, or implementing a custom `NSTextStorage` subclass that intercepts attribute-modifying methods.

### TD-05: Multiple Window / Document Isolation Issues

**Location**: `EditorViewModel.swift:114-118,144-168`, `WYSIWYGTextView.swift:304-339`, `OutlineView.swift:38-44`

**Problem**: `NotificationCenter.default` posts notifications without specifying an `object` (sender) that identifies which document window the notification belongs to. All coordinators observe with `object: nil`, meaning **every open document's Coordinator receives every notification**.

For example, when the user presses Cmd+B in Window A:
1. `EditorViewModel` in Window A posts `.toggleFormatting` with `object: nil`
2. **Both** Window A's Coordinator AND Window B's Coordinator receive the notification
3. Both text views toggle bold formatting

Similarly, `EditorSettings.shared` is a singleton shared across all windows -- changing a setting affects all documents simultaneously (which is expected for preferences, but conflates per-document and global state).

**Impact**: HIGH for multi-document use. The app will malfunction when multiple documents are open simultaneously. Format commands, heading commands, scroll-to-position, and image insertion will affect ALL open documents.

**Fix Direction**:
1. Post notifications with `object: viewModel` (or a document identifier) and observe with the same object filter
2. Alternatively, replace NotificationCenter with the delegate/closure pattern from TD-01, which inherently scopes to a single Coordinator instance
3. Consider making `isFocusModeEnabled` and `isTypewriterScrollEnabled` per-document (they are already on EditorViewModel) but ensure menu commands target the correct window's ViewModel

### TD-06: EditorViewModel Owns Too Many Responsibilities

**Location**: `EditorViewModel.swift` (169 lines, 14+ public methods)

**Problem**: The ViewModel handles:
- Source text storage
- Cursor position tracking
- Formatting commands (bold, italic, code, link, heading)
- Outline/heading extraction
- Document statistics (word count, character count, line count)
- Export (HTML, PDF)
- Image handling
- Focus mode / typewriter scroll state
- Error state

This violates single responsibility. The headings computation (lines 60-81) re-parses the document on every access using basic string splitting, duplicating the work already done by `MarkdownParser`.

**Impact**: MEDIUM. Makes the ViewModel harder to test, extend, and reason about. The duplicate heading parsing is wasteful and may diverge from the parser's heading detection.

**Fix Direction**: Extract into focused types:
- `FormattingCommandHandler` for bold/italic/code/link/heading
- Use `EditorNodeModel.blocks` to derive headings instead of re-parsing
- Move export methods to a dedicated coordinator
- Move statistics to a computed-property helper or derive from parse results

### TD-07: Heading Extraction Duplicates Parser Logic

**Location**: `EditorViewModel.swift:60-81`

**Problem**: `EditorViewModel.headings` uses manual string splitting and `#` prefix detection to extract headings. This duplicates the logic in `MarkdownParser` which already correctly parses headings from the swift-markdown AST. The manual implementation:
- Does not handle edge cases that swift-markdown handles (e.g., ATX headings with trailing `#`, setext headings)
- Uses `NSString.length + 1` for offset calculation which may diverge from the parser's UTF-16 offset calculation
- Re-runs on every access (computed property with no caching)

**Impact**: LOW-MEDIUM. May show different headings in the outline than what the parser/highlighter considers headings. Performance impact is minimal for typical document sizes.

**Fix Direction**: Derive headings from `EditorNodeModel.blocks` by filtering for `.heading` kind blocks, which are already parsed by `MarkdownParser`.

### TD-08: Timer-Based Debounce Instead of Task-Based

**Location**: `WYSIWYGTextView.swift:148-155, 199-218, 254-261`

**Problem**: Three separate `Timer.scheduledTimer` instances are used for debouncing:
1. `highlightTimer` (0.15s) -- triggers `applyHighlightNow()`
2. `autoSaveTimer` (configurable) -- triggers `performAutoSave()`
3. Cursor-move highlight timer (0.02s) -- triggers `applyHighlightFromCache()`

All use `MainActor.assumeIsolated` inside the timer callback, which is technically correct but fragile. The timers are `nonisolated(unsafe)` to satisfy Sendable requirements.

**Impact**: LOW. Functionally correct but uses older patterns. Swift's structured concurrency (`Task.sleep`) would be more idiomatic for Swift 6.

**Fix Direction**: Replace with `Task`-based debouncing using cancellation tokens, or a dedicated `Debouncer` utility actor.

### TD-09: Unused Highlightr Dependency

**Location**: `project.yml:21-23`, `EditorTheme.swift:47`

**Problem**: Highlightr 2.2.1 is declared as a dependency in `project.yml` and each `EditorTheme` has a `highlightrTheme: String` property, but no Swift file imports `Highlightr`. The dependency is compiled and linked but never used.

**Impact**: LOW. Increases build time and binary size unnecessarily. The `highlightrTheme` property on `EditorTheme` suggests planned integration for code block syntax highlighting that was never completed.

**Fix Direction**: Either integrate Highlightr into `SyntaxHighlighter.applyCodeBlock()` to provide language-aware syntax coloring, or remove the dependency from `project.yml` and the `highlightrTheme` property from `EditorTheme`.

### TD-10: MarkdownDocument Background Thread Initialization

**Location**: `MarkdownDocument.swift:21-32, 41-56`

**Problem**: Both `init()` and `init(configuration:)` handle background-thread initialization by setting `viewModel = nil` and deferring creation via `DispatchQueue.main.async`. During the window between init and the async callback, `viewModel` is `nil`. `EditorView.swift:13` accesses `document.viewModel` (force-unwrap via `!`) which would crash if accessed before the async block runs.

**Impact**: MEDIUM. Potential crash on slow systems where the view renders before `DispatchQueue.main.async` fires. The `viewModel!` force-unwrap is a crash waiting to happen.

**Fix Direction**: Make `viewModel` optional (`EditorViewModel?`) and handle the nil case in `EditorView` with a loading placeholder. Or use `@MainActor` initialization with `MainActor.run` to ensure viewModel is always initialized before the view accesses it.

## Patterns and Anti-Patterns

### Good Patterns

1. **Value types for AST** -- `EditorNode`, `InlineRun`, `ParseResult` are all `Sendable` structs, enabling safe cross-isolation transfer
2. **Actor-based services** -- `ExportService`, `FileService`, `ImageService` use Swift actors for thread-safe I/O without manual locking
3. **Attribute-only highlighting** -- `SyntaxHighlighter` never modifies text content, only attributes, preventing undo history corruption
4. **IME composition protection** -- `hasMarkedText()` check before textStorage modification (WYSIWYGTextView.swift:162-165)
5. **Position-based diff** -- `EditorNodeModel.applyParseResult()` preserves stable block IDs, enabling efficient cache invalidation
6. **Comprehensive theme system** -- Full color/font token system with 7 presets, proper Codable conformance, and centralized registry
7. **Consistent use of @Observable** -- Modern Observation framework used throughout instead of Combine/ObservableObject
8. **Accessibility consideration** -- `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` check for typewriter scroll animation (ShoechooTextView.swift:84)
9. **Auto-pair bracket handling** -- Smart bracket/quote pairing with word-boundary detection for single quotes (ShoechooTextView.swift:143-203)
10. **Path traversal validation** -- `ImageService.validateImagePath()` rejects `../` and absolute paths (ImageService.swift:89-101)

### Anti-Patterns

1. **NotificationCenter for typed commands** -- Untyped dictionary-based communication between ViewModel and NSTextView (TD-01, TD-05)
2. **Singleton overuse** -- `EditorSettings.shared` prevents per-document settings and complicates testing (no dependency injection for settings)
3. **Force-unwrap on deferred init** -- `document.viewModel!` in EditorView assumes async init has completed (TD-10)
4. **Duplicate parsing logic** -- Heading extraction in ViewModel duplicates MarkdownParser work (TD-07)
5. **God ViewModel** -- EditorViewModel handles formatting, statistics, export, image handling, and UI state (TD-06)
6. **Unused dependency** -- Highlightr linked but never imported (TD-09)
7. **Missing documentation** -- Most types and public APIs lack doc comments
8. **No linting configuration** -- No SwiftLint or SwiftFormat configured
9. **`@unchecked Sendable` on MarkdownDocument** -- Bypasses compiler safety checks; `fileURL` has no synchronization (TD-02)
10. **Global notification broadcasting** -- All notifications go to all windows, breaking multi-document support (TD-05)
