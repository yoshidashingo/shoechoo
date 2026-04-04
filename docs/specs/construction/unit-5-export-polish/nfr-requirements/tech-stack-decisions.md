---
layout: default
---

# Tech Stack Decisions: Unit 5 — Export & Polish

## Core Dependencies

| Technology | Choice | Version | Rationale |
|-----------|--------|---------|-----------|
| Language | Swift 6 | 6.0+ | Modern concurrency, strict safety |
| UI Framework | SwiftUI + AppKit | macOS 14+ | NavigationSplitView for sidebar; AppKit for editor integration |
| HTML Export | swift-markdown HTML Visitor | exact: 0.5.0 | Typed AST walk produces safe, structured HTML; no regex |
| PDF Rendering | WKWebView (offscreen) | macOS 14+ (built-in) | Renders HTML+CSS to PDF preserving styling; system framework |
| Sidebar Layout | NavigationSplitView | macOS 14+ (SwiftUI) | Native macOS sidebar pattern with system animations |
| Recent Files | NSDocumentController | macOS 14+ (built-in) | System-managed recent document URLs; no custom tracking needed |
| Dark Mode | NSAppearance + semantic NSColor | macOS 14+ (built-in) | System appearance integration; automatic color adaptation |
| State Persistence | @AppStorage (UserDefaults) | Built-in | Lightweight sidebar state persistence across launches |
| Concurrency | Swift Actors | Built-in | ExportService actor for off-main-thread export |
| Testing | Swift Testing + XCTest | Built-in | Snapshot tests for sidebar; HTML string assertions for export |

## Rejected Alternatives

| Technology | Rejected | Reason |
|-----------|----------|--------|
| Regex/String replacement | For HTML generation | Fragile, error-prone, no structure guarantee; AST visitor is correct by construction |
| Core Graphics direct PDF | For PDF rendering | Loses CSS styling; would require manual layout of every element |
| Print framework (NSPrintOperation) | For PDF export | Less control over output; WKWebView produces higher fidelity PDF |
| Custom recent files tracking | For sidebar | NSDocumentController already tracks recent files; duplicating adds maintenance burden |
| Custom theming engine | For dark mode | NSAppearance + semantic colors handle everything; custom theming is unnecessary complexity |
| List + sidebar manual layout | For sidebar | NavigationSplitView is the standard SwiftUI pattern for Mac sidebars |
| Third-party HTML sanitizer | For export safety | HTML visitor only emits known-safe tags; no need for post-hoc sanitization |

## Export Pipeline Architecture

```
User action (Export menu)
    |
    v
EditorViewModel (@MainActor)
    |
    | current document Markdown string
    v
ExportService (actor)
    |
    |--- exportHTML(markdown:) ---> HTML String ---> Save to file
    |
    |--- exportPDF(markdown:) ---> HTML String
    |                                   |
    |                                   v
    |                            WKWebView (offscreen, @MainActor)
    |                                   |
    |                                   v
    |                            PDF Data ---> Save to file
    v
NSSavePanel (user picks destination)
```

**Key architecture decisions**:
- `ExportService` is an actor that owns the export pipeline: Markdown parsing, HTML generation, and PDF coordination
- HTML generation uses swift-markdown's `MarkupWalker` pattern to visit AST nodes and emit HTML — no regex or string templates
- WKWebView for PDF runs on `@MainActor` (WebKit requirement); ExportService coordinates the handoff
- NSSavePanel presented after export completes; file is written to user-chosen location

## Sidebar Architecture

```
NavigationSplitView
    |
    |--- Sidebar (SidebarView)
    |       |
    |       |--- Recent Files section (NSDocumentController.recentDocumentURLs)
    |       |--- File metadata (name, date, size)
    |       |--- @AppStorage for collapsed/expanded state
    |
    |--- Detail (EditorView)
            |
            |--- WYSIWYGTextView (existing)
            |--- Dark mode via semantic NSColor
```

**Key sidebar decisions**:
- `NavigationSplitView` provides native sidebar behavior (collapse, resize, keyboard navigation)
- Recent files sourced from `NSDocumentController.shared.recentDocumentURLs` — no custom persistence
- Sidebar state (collapsed, selected item) persisted via `@AppStorage` for restart survival

## Dark Mode Strategy

| Element | Color Source | Behavior |
|---------|-------------|----------|
| Editor text | `NSColor.labelColor` | Auto-adapts light/dark |
| Editor background | `NSColor.textBackgroundColor` | Auto-adapts light/dark |
| Secondary text | `NSColor.secondaryLabelColor` | Auto-adapts light/dark |
| Sidebar background | System default (NavigationSplitView) | Auto-adapts light/dark |
| Code block background | `NSColor.controlBackgroundColor` | Auto-adapts light/dark |
| Syntax highlighting | Highlightr theme switch (light/dark) | Switched on `NSAppearance` change |

**Rationale**: Semantic NSColor values are validated by Apple for WCAG AA contrast. Only syntax highlighting requires explicit theme switching via Highlightr.

## Build Configuration

| Setting | Value |
|---------|-------|
| Deployment Target | macOS 14.0 (Sonoma) |
| Swift Language Version | 6 |
| Strict Concurrency | Complete |
| Optimization (Debug) | -Onone |
| Optimization (Release) | -O |

## SPM Dependencies (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.5.0"),
    .package(url: "https://github.com/raspu/Highlightr.git", exact: "2.2.1"),
]
```

**Note**: Unit 5 adds no new SPM dependencies. WKWebView, NavigationSplitView, NSDocumentController, and NSAppearance are all system frameworks. Exact versions pinned per SECURITY-10. Package.resolved MUST be committed.
