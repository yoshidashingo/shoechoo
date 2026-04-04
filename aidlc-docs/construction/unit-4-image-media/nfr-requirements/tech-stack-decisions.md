# Tech Stack Decisions: Unit 4 — Image & Media

## Core Dependencies

| Technology | Choice | Version | Rationale |
|-----------|--------|---------|-----------|
| Language | Swift 6 | 6.0+ | Modern concurrency, strict safety |
| UI Framework | AppKit (NSTextView) + SwiftUI | macOS 14+ | NSTextView for editor; SwiftUI for supplementary UI |
| Image Loading | NSImage / CGImageSource | macOS 14+ (built-in) | System framework for safe image decoding; no third-party needed |
| Drag & Drop | NSDraggingInfo (AppKit) | macOS 14+ (built-in) | Standard AppKit drag & drop protocol for NSTextView |
| Clipboard | NSPasteboard | macOS 14+ (built-in) | System pasteboard API for copy/paste image handling |
| File I/O | FileManager | macOS 14+ (built-in) | Atomic writes, directory creation, disk space checks |
| Concurrency | Swift Actors | Built-in | ImageService actor + FileService actor for thread safety |
| Filename Generation | SHA256 (CryptoKit) | Built-in | Content-addressable filenames; deterministic and human-readable |
| Testing | Swift Testing + XCTest | Built-in | Protocol-based mocking for FileService |

## Rejected Alternatives

| Technology | Rejected | Reason |
|-----------|----------|--------|
| SDWebImage / Kingfisher | For image loading | Designed for network image caching; overkill for local file loading |
| UUID for filenames | For filename generation | Not human-readable; SHA256 of content is deterministic and deduplicates |
| Custom drag & drop | For drop handling | NSDraggingInfo is the standard AppKit protocol; custom adds no value |
| Third-party clipboard library | For paste handling | NSPasteboard is sufficient and avoids unnecessary dependency |
| CoreImage | For image validation | CGImageSource is lighter weight for format validation; CoreImage is for processing |

## Actor Architecture

```
WYSIWYGTextView (AppKit, main actor)
    |
    | drag & drop / paste event
    v
EditorViewModel (@MainActor)
    |
    | insertImage(from:)
    v
ImageService (actor)
    |
    | validate + generate filename + coordinate write
    v
FileService (actor)
    |
    | atomic file write to assets directory
    v
Document assets directory
```

**Key architecture decisions**:
- `ImageService` is an actor that owns the image import pipeline: validation, filename generation, and coordination
- `FileService` is a separate actor for all disk I/O: atomic writes, directory creation, space checks
- Separation allows independent testing and prevents file system operations from leaking into image logic
- `EditorViewModel` receives the Markdown image reference (`![](assets/filename.png)`) and inserts it into the document

## Filename Generation Strategy

```swift
// Content-based: SHA256 hash prefix + original extension
// Example: "a1b2c3d4e5f6-photo.png"
func generateFilename(data: Data, originalName: String) -> String {
    let hash = SHA256.hash(data: data).prefix(6).hexString
    let ext = URL(fileURLWithPath: originalName).pathExtension
    return "\(hash)-\(originalName.sanitized).\(ext)"
}
```

**Rationale**: SHA256 prefix ensures uniqueness for different content; preserving the original name aids human readability; deterministic output enables testing.

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

**Note**: Unit 4 adds no new SPM dependencies. NSImage, CGImageSource, CryptoKit, and FileManager are all system frameworks. Exact versions pinned per SECURITY-10. Package.resolved MUST be committed.
