# Technology Stack

## Programming Language

| Item | Detail |
|------|--------|
| Language | Swift 6.0 |
| Concurrency model | Strict concurrency checking (`SWIFT_STRICT_CONCURRENCY: complete`) |
| Key features used | `@Observable` (Observation framework), `actor`, `async/await`, `Sendable`, `@MainActor`, `nonisolated(unsafe)`, structured concurrency |

## Frameworks

### UI Frameworks

| Framework | Version | Usage |
|-----------|---------|-------|
| **SwiftUI** | macOS 14+ | App lifecycle (`@main`, `DocumentGroup`, `Settings`), scene management, menu commands (`CommandGroup`), toolbar, preferences UI, sidebar/outline views, `@Environment`, `@FocusedValue` |
| **AppKit** | macOS 14+ | Text editing (`NSTextView` subclass), text storage manipulation (`NSTextStorage`), font management (`NSFontManager`), drag-and-drop (`NSDraggingInfo`), scroll view (`NSScrollView`), save/open panels (`NSSavePanel`), document controller (`NSDocumentController`), appearance management (`NSAppearance`) |
| **WebKit** | macOS 14+ | PDF export via offscreen `WKWebView.pdf(configuration:)`, `WKNavigationDelegate` for load completion |
| **UniformTypeIdentifiers** | macOS 14+ | UTType definitions for `.markdown`, `.plainText`, `.html`, `.pdf`, `.fileURL` |

### Markdown Parsing

| Framework | Version | Usage |
|-----------|---------|-------|
| **swift-markdown** | 0.5.0 (exact) | `Document(parsing:options:)` for AST generation, `MarkupWalker` protocol for HTML conversion, AST node types (`Heading`, `Paragraph`, `CodeBlock`, `Strong`, `Emphasis`, `Link`, `Image`, `UnorderedList`, `OrderedList`, `ListItem`, `BlockQuote`, `Table`, `ThematicBreak`, `Strikethrough`, `InlineCode`, `SoftBreak`, `LineBreak`, `HTMLBlock`, `InlineHTML`), source range mapping |

### Syntax Highlighting (Declared but Unused)

| Framework | Version | Usage |
|-----------|---------|-------|
| **Highlightr** | 2.2.1 (exact) | Declared in `project.yml` as dependency. `EditorTheme.highlightrTheme` property references theme names (e.g., "github", "monokai-sublime", "solarized-light"). However, no Swift file actually `import Highlightr`. The dependency is linked but not used in current code. Likely planned for code block syntax highlighting |

### Apple System Frameworks

| Framework | Usage |
|-----------|-------|
| **Foundation** | `NSRange`, `NSLock`, `FileManager`, `ISO8601DateFormatter`, `UserDefaults`, `Timer`, `NotificationCenter`, `ProcessInfo` |
| **os** | Imported in `MarkdownDocument.swift` (logger, though not actively used in current code) |
| **CoreGraphics** | `CGFloat`, `CGRect`, `NSRect` for layout calculations |
| **QuartzCore** | `CAMediaTimingFunction` for typewriter scroll animation |

## Build Tools

| Tool | Version | Purpose |
|------|---------|---------|
| **Xcode** | 16.0+ | IDE, compiler, simulator, test runner |
| **XcodeGen** | (project dependency) | Generates `.xcodeproj` from `project.yml` declarative configuration |
| **Swift Package Manager** | Built into Xcode | Dependency resolution for swift-markdown and Highlightr |

## Test Tools

| Tool | Purpose |
|------|---------|
| **Swift Testing** | Test framework (`import Testing`, `@Test`, `@Suite`, `#expect`, `Issue.record`). Used exclusively -- no XCTest |
| **Xcode Test Runner** | Executes tests via `shoechooTests` target with coverage gathering enabled |
| **Parameterized Tests** | Used via `@Test(arguments:)` for heading levels (1-6), theme presets, heading font sizes |

## Platform Requirements

| Requirement | Value |
|-------------|-------|
| Minimum macOS | 14.0 (Sonoma) |
| Architecture | Universal (Apple Silicon + Intel, via Xcode default) |
| Code signing | Ad-hoc (`CODE_SIGN_IDENTITY: "-"`) |
| Hardened runtime | Enabled |
| Sandbox | Entitlements file present (`shoechoo.entitlements`) |
| Document types | Markdown (`.md`, `.markdown`), Plain Text |
| UTI | `net.daringfireball.markdown` (exported type) |

## Missing from Stack (Potential Gaps)

| Category | Status | Recommendation |
|----------|--------|----------------|
| Linting | Not configured | Add SwiftLint or swift-format for consistent style enforcement |
| Formatting | Not configured | Add SwiftFormat for automated formatting |
| CI/CD | Not configured | Add GitHub Actions for build + test on push |
| Crash reporting | Not present | Consider integrating for beta/release builds |
| Logging | `os` imported but no structured logging | Add `os.Logger` for debug diagnostics |
| Accessibility | Partial (reduce-motion check) | Add VoiceOver support, accessibility labels |
