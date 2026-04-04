---
layout: default
---

# Technical Environment Document: Shoe Choo

## Language & Version
- **Language**: Swift 6
- **Minimum Deployment Target**: macOS 14 (Sonoma)
- **Xcode**: 16+

## Framework & UI
- **UI Framework**: SwiftUI (primary) + AppKit integration where needed (NSTextView, menus)
- **Architecture**: MVVM with SwiftUI's @Observable macro
- **Concurrency**: Swift structured concurrency (async/await, actors)

## Build System
- **Project Type**: Xcode project (.xcodeproj)
- **Package Manager**: Swift Package Manager (SPM)
- **Build Tool**: xcodebuild / Xcode

## Key Dependencies (Candidates)

| Library | Purpose | Notes |
|---------|---------|-------|
| swift-markdown (Apple) | Markdown parsing to AST | Official Apple library, maintained |
| Highlightr | Code block syntax highlighting | Wraps highlight.js |
| SwiftUI-Introspect | Access underlying AppKit views | For TextKit 2 integration |

## Prohibited Libraries

| Library | Reason | Alternative |
|---------|--------|-------------|
| Electron / WebView-based editors | Not native, high memory | Native TextKit 2 |
| Realm / Core Data | Overkill for a text editor | File-based storage |
| RxSwift / Combine (heavy use) | Unnecessary with Swift Concurrency | async/await, @Observable |

## Distribution
- **Primary**: Direct download via GitHub Releases (DMG + ZIP)
- **Future**: Mac App Store (requires Sandbox compliance review)
- **Code Signing**: Developer ID (not notarized initially)

## Testing Framework
- **Unit Tests**: XCTest + Swift Testing
- **UI Tests**: XCUITest
- **Snapshot Tests**: Considered for UI consistency

## Code Style & Conventions

### File Structure (Target)
```
shoechoo/
├── shoechoo.xcodeproj
├── shoechoo/
│   ├── App/
│   │   └── ShoechooApp.swift        # @main entry point
│   ├── Models/
│   │   ├── Document.swift            # Markdown document model
│   │   └── EditorState.swift         # Editor state management
│   ├── Views/
│   │   ├── EditorView.swift          # Main WYSIWYG editor
│   │   ├── SidebarView.swift         # File browser sidebar
│   │   └── ToolbarView.swift         # Toolbar configuration
│   ├── ViewModels/
│   │   └── EditorViewModel.swift     # Editor business logic
│   ├── Services/
│   │   ├── MarkdownParser.swift      # Markdown parsing service
│   │   ├── FileService.swift         # File I/O operations
│   │   └── ExportService.swift       # HTML/PDF export
│   ├── Editor/
│   │   ├── WYSIWYGTextView.swift     # Core WYSIWYG rendering
│   │   ├── MarkdownRenderer.swift    # Inline Markdown renderer
│   │   └── FocusMode.swift           # Focus mode overlay
│   ├── Extensions/
│   │   └── ...
│   ├── Resources/
│   │   └── Assets.xcassets
│   └── Info.plist
├── shoechooTests/
│   └── ...
├── shoechooUITests/
│   └── ...
├── docs/                              # GitHub Pages site
├── aidlc-docs/                        # AI-DLC documentation
└── README.md
```

### Naming Conventions
- Types: PascalCase (`EditorViewModel`, `MarkdownParser`)
- Properties / Methods: camelCase (`currentDocument`, `parseMarkdown()`)
- Constants: camelCase (`defaultFontSize`)
- Protocols: PascalCase with `-able`/`-ing` suffix where appropriate

### Example — Typical View
```swift
import SwiftUI

struct EditorView: View {
    @State private var viewModel = EditorViewModel()

    var body: some View {
        WYSIWYGTextView(
            text: $viewModel.content,
            focusMode: viewModel.isFocusModeEnabled
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Focus", systemImage: "eye") {
                    viewModel.toggleFocusMode()
                }
            }
        }
    }
}
```

### Example — Typical Service
```swift
import Foundation

actor FileService {
    func load(from url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw FileServiceError.invalidEncoding
        }
        return content
    }

    func save(_ content: String, to url: URL) async throws {
        let data = Data(content.utf8)
        try data.write(to: url, options: .atomic)
    }
}
```

### Example — Typical Test
```swift
import Testing
@testable import shoechoo

struct MarkdownParserTests {
    @Test func parsesHeading() {
        let parser = MarkdownParser()
        let result = parser.parse("# Hello")
        #expect(result.first?.type == .heading(level: 1))
        #expect(result.first?.text == "Hello")
    }
}
```

## Security Basics
- No network access required for core functionality
- Files stored locally on user's filesystem
- No user accounts or authentication
- Sandbox-compatible design for future Mac App Store distribution
