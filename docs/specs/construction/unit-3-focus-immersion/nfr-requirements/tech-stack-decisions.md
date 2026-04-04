---
layout: default
---

# Tech Stack Decisions: Unit 3 — Focus & Immersion

## Core Dependencies

| Technology | Choice | Version | Rationale |
|-----------|--------|---------|-----------|
| Language | Swift 6 | 6.0+ | Modern concurrency, strict safety |
| UI Framework | AppKit (NSTextView) | macOS 14+ | Direct access to NSTextLayoutFragment for per-paragraph alpha |
| Layout Engine | TextKit 2 | macOS 14+ | NSTextLayoutFragment-based dimming; fragment-level visual control |
| Animation | NSAnimationContext | macOS 14+ | Native animation with Reduce Motion support built-in |
| Full-Screen | NSWindow native | macOS 14+ | System full-screen with menu bar auto-hide and Mission Control integration |
| Settings Storage | UserDefaults | Built-in | Persist focus mode and typewriter preferences (shared EditorSettings) |
| Settings Binding | @AppStorage | SwiftUI | Reactive binding for focus/typewriter toggle states |
| Testing | Swift Testing + XCTest | Built-in | Modern test framework for unit/integration tests |

## Rejected Alternatives

| Technology | Rejected | Reason |
|-----------|----------|--------|
| Overlay NSView for dimming | For paragraph dimming | Extra view hierarchy; interferes with hit testing and VoiceOver; alpha on NSTextLayoutFragment is lighter |
| Custom scroll view | For typewriter scrolling | scrollRangeToVisible with offset is sufficient; custom scroll view adds complexity without benefit |
| Custom full-screen implementation | For immersive mode | NSWindow native full-screen provides menu bar hide, Mission Control, Space support for free |
| Core Animation layer per paragraph | For dimming animation | Too many layers for large documents; NSTextLayoutFragment alpha is managed by TextKit 2 layout system |
| SwiftUI .animation() | For transitions | Focus mode operates at AppKit NSTextView level; NSAnimationContext is the correct AppKit animation API |
| Combine / Timer | For typewriter scroll debounce | Unnecessary; scroll updates are driven by NSTextView selection change delegate, which fires at appropriate frequency |

## Focus Mode Architecture

```
EditorViewModel (@Observable)
    |
    +-- isFocusModeEnabled: Bool
    +-- isTypewriterEnabled: Bool
    +-- activeParagraphRange: NSRange?
    |
    v
ShoechooTextView : NSTextView
    |
    +-- NSTextLayoutManager
    |       |
    |       +-- enumerateTextLayoutFragments(...)
    |               |
    |               +-- fragment.alpha = 1.0  (active paragraph)
    |               +-- fragment.alpha = 0.3  (dimmed paragraphs)
    |
    +-- scrollRangeToVisible(_:) + vertical offset  (typewriter)
    |
    +-- NSWindow.toggleFullScreen(_:)  (immersive)
```

**Key architectural decisions**:
- Dimming via `NSTextLayoutFragment` alpha property — no overlay views, no extra layers, no accessibility interference
- Typewriter scrolling via `scrollRangeToVisible` with a calculated vertical offset to center the cursor line
- Full-screen delegates to `NSWindow.toggleFullScreen(_:)` — no custom window chrome or title bar manipulation
- All state lives in `EditorViewModel`; ShoechooTextView reads via @Observable and applies visual changes
- `EditorSettings` persists user preferences (focus enabled, typewriter enabled, dimmed alpha) via @AppStorage / UserDefaults

## Animation Configuration

```swift
NSAnimationContext.runAnimationGroup { context in
    context.duration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : 0.2
    context.allowsImplicitAnimation = true
    // Apply dimming alpha changes
    textLayoutManager.enumerateTextLayoutFragments(from: location, options: options) { fragment in
        fragment.alpha = isActive ? 1.0 : dimmedAlpha
        return true
    }
}
```

**Reduce Motion**: All animations check `accessibilityDisplayShouldReduceMotion` and set duration to 0 when enabled.

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

**Note**: Exact versions pinned per SECURITY-10. Package.resolved MUST be committed. No additional dependencies introduced in Unit 3.
