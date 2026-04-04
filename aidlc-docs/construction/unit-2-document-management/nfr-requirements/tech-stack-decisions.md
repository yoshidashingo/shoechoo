# Tech Stack Decisions: Unit 2 — Document Management

## Core Dependencies

| Technology | Choice | Version | Rationale |
|-----------|--------|---------|-----------|
| Language | Swift 6 | 6.0+ | Modern concurrency, strict safety |
| UI Framework | SwiftUI + AppKit | macOS 14+ | DocumentGroup (SwiftUI) for lifecycle; NSTextView (AppKit) for editor |
| Document Model | NSDocument | macOS 14+ | Built-in auto-save, Versions, crash recovery, recent documents |
| Scene Management | DocumentGroup | SwiftUI | Multi-document lifecycle with automatic window management |
| Settings Storage | UserDefaults | Built-in | Simple key-value persistence for editor preferences |
| Settings Binding | @AppStorage | SwiftUI | Reactive binding from UserDefaults to SwiftUI views |
| File Type | UTType (.md) | UniformTypeIdentifiers | System-level file association for Markdown files |
| File I/O | FileService | Custom | Thin wrapper around Foundation file APIs with validation |
| Testing | Swift Testing + XCTest | Built-in | Modern test framework for unit/integration/snapshot tests |

## Rejected Alternatives

| Technology | Rejected | Reason |
|-----------|----------|--------|
| Custom file management | For document lifecycle | NSDocument provides auto-save, Versions, crash recovery for free |
| WindowGroup | For scene type | DocumentGroup handles file open/save/new lifecycle automatically |
| Core Data | For settings persistence | Overkill for ~15 simple key-value preferences; UserDefaults is sufficient |
| @Observable + manual persistence | For settings binding | @AppStorage provides direct two-way binding to UserDefaults in SwiftUI |
| Custom UTI plist | For file association | UTType API (UniformTypeIdentifiers) is the modern replacement |
| SQLite / Realm | For document storage | Markdown files are plain text; no need for structured database storage |
| iCloud Drive sync | For Unit 2 scope | Out of scope; NSDocument supports this but deferred to future unit |

## Document Architecture

```
ShoechooApp : App
    |
    DocumentGroup(newDocument: MarkdownDocument())
        |
        EditorView
            |
            +-- ShoechooTextView (NSViewRepresentable -> NSTextView)
            +-- EditorViewModel (@Observable)
            +-- EditorSettings (@AppStorage-backed)
```

**Key architectural decisions**:
- `MarkdownDocument` conforms to `FileDocument` (SwiftUI) backed by `NSDocument` patterns
- `DocumentGroup` manages the multi-window lifecycle; each window owns its MarkdownDocument instance
- `EditorViewModel` is per-document; `EditorSettings` is app-wide (shared via @AppStorage)
- `FileService` provides validated file I/O with atomic writes and sandbox-aware path checking

## File Type Registration

```swift
import UniformTypeIdentifiers

extension UTType {
    static let markdown = UTType(importedAs: "net.daringfireball.markdown")
}
```

**Supported extensions**: `.md`, `.markdown`, `.mdown`
**Conforms to**: `public.plain-text`, `public.text`

## Build Configuration

| Setting | Value |
|---------|-------|
| Deployment Target | macOS 14.0 (Sonoma) |
| Swift Language Version | 6 |
| Strict Concurrency | Complete |
| App Sandbox | Enabled |
| File Access | User Selected (Read-Write) |
| Optimization (Debug) | -Onone |
| Optimization (Release) | -O |

## SPM Dependencies (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-markdown.git", exact: "0.5.0"),
    .package(url: "https://github.com/raspu/Highlightr.git", exact: "2.2.1"),
]
```

**Note**: Exact versions pinned per SECURITY-10. Package.resolved MUST be committed. No additional dependencies introduced in Unit 2.
