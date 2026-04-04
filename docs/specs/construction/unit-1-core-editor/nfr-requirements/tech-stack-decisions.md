---
layout: default
---

# Tech Stack Decisions: Unit 1 — Core Editor Engine

## Core Dependencies

| Technology | Choice | Version | Rationale |
|-----------|--------|---------|-----------|
| Language | Swift 6 | 6.0+ | Modern concurrency, strict safety |
| UI Framework | AppKit (NSTextView) | macOS 14+ | TextKit 2 requires NSTextView; no SwiftUI native rich text editor |
| Text Engine | TextKit 2 | macOS 14+ | NSTextContentStorage + NSTextLayoutManager for modern text layout |
| Markdown Parser | swift-markdown (Apple) | Latest stable | Typed AST, internal cmark-gfm, GFM spec compliance |
| Syntax Highlighting | Highlightr | Latest stable | highlight.js wrapper for code block coloring |
| Concurrency | Swift Structured Concurrency | Built-in | async/await, actors for thread-safe parsing |
| Testing | Swift Testing + XCTest | Built-in | Modern test framework for unit/integration tests |

## Rejected Alternatives

| Technology | Rejected | Reason |
|-----------|----------|--------|
| WKWebView + ProseMirror | For editor surface | Not native; loses IME, VoiceOver, Undo integration |
| cmark (direct C binding) | For parser | swift-markdown wraps cmark-gfm and adds typed Swift AST |
| Ink (John Sundell) | For parser | Less maintained, no GFM tables/task lists |
| tree-sitter | For incremental parsing | Overkill for Markdown; cmark is fast enough for full reparse |
| Combine | For reactive pipeline | Unnecessary with @Observable + async/await |

## TextKit 2 Stack Configuration

```
NSTextContentStorage (model)
    |
    v
NSTextLayoutManager (layout)
    |
    v
NSTextContainer (geometry)
    |
    v
ShoechooTextView : NSTextView (display)
```

**Key TextKit 2 decisions**:
- Use `NSTextContentStorage` (not legacy `NSTextStorage`) for modern text model
- Use `NSTextLayoutManager` (not legacy `NSLayoutManager`) for fragment-based layout
- `NSTextLayoutFragment` is the unit of layout invalidation — maps well to our block-level re-rendering
- Replace attributed string content per-block via `NSTextContentStorage.performEditingTransaction`

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

**Note**: Exact versions pinned per SECURITY-10. Package.resolved MUST be committed.
