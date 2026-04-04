<h1 align="center">
  <img src="docs/icon.png" alt="Shoe Choo" width="128">
  <br>
  Shoe Choo Editor
  <br>
  <br>
</h1>

<p align="center">
  A distraction-free Markdown editor for macOS that lets you focus on writing.
</p>

<p align="center">
  <a href="https://github.com/yoshidashingo/shoechoo/releases/latest"><img src="https://img.shields.io/github/v/release/yoshidashingo/shoechoo" alt="release"></a>
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE"><img src="https://img.shields.io/github/license/yoshidashingo/shoechoo" alt="license"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue" alt="platform">
  <img src="https://img.shields.io/badge/swift-6-orange" alt="swift">
</p>

<p align="center">
  <a href="README.md">English</a> •
  <a href="README-ja.md">日本語</a>
</p>

## Features

### Seamless Editing
- **Live Preview** — What you see is what you get. Markdown syntax is rendered inline as you type, just like Typora
- **Clean Interface** — Minimal UI that stays out of your way so you can focus on your words
- **Syntax Highlighting** — Subtle, readable highlighting for Markdown elements and code blocks (via Highlightr)

### Writing Focus
- **Focus Mode** — Dims everything except the current paragraph to keep you in the zone
- **Typewriter Scrolling** — Keeps the active line centered on screen for a comfortable writing posture
- **Full Screen** — Immersive full-screen writing with no distractions

### Markdown
- **GFM Support** — Headings, bold, italic, strikethrough, lists, task lists, tables, code blocks, blockquotes, horizontal rules, links, and images
- **Image Support** — Drag & drop or paste images directly into your document (auto-saved to `{filename}.assets/`)
- **Export** — Save as HTML or PDF

### General
- **Native macOS App** — Built with Swift 6 and SwiftUI + AppKit (TextKit 2) for a fast, lightweight experience
- **File Management** — Open, edit, and save `.md` files with standard macOS file handling (auto-save, Versions)
- **Dark Mode** — Full support for macOS light and dark appearances with override option
- **Sidebar** — Quick access to recently opened files
- **Preferences** — Customizable font, font size, line spacing, and appearance

## Requirements

- macOS 14 (Sonoma) or later

## Installation

1. Download the latest version from the **[Releases page](https://github.com/yoshidashingo/shoechoo/releases/latest)**
2. Open the `.zip` or `.dmg` and move `shoechoo.app` to your Applications folder
3. Launch Shoe Choo

> **Note**: This app is not notarized. On first launch, macOS will block it. To open it:
>
> **Option A** (Terminal):
> ```
> xattr -cr "/Applications/shoechoo.app"
> ```
> Then launch the app normally.
>
> **Option B** (System Settings):
> 1. Try to open `shoechoo.app` (it will be blocked)
> 2. Open **System Settings** > **Privacy & Security**
> 3. Scroll down to find the blocked app message and click **Open Anyway**

## Usage

1. Launch Shoe Choo — a new editor window opens
2. Start writing in Markdown — formatting is rendered live as you type
3. **⌘N** — Create a new document
4. **⌘O** — Open an existing Markdown file
5. **⌘S** — Save the current document
6. **⇧⌘F** — Toggle focus mode
7. **⇧⌘E** — Export to HTML

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | New document |
| ⌘O | Open file |
| ⌘S | Save |
| ⇧⌘S | Save as |
| ⌘B | Bold |
| ⌘I | Italic |
| ⌘K | Insert link |
| ⇧⌘K | Inline code |
| ⌘1–6 | Set heading level |
| ⇧⌘F | Toggle focus mode |
| ⇧⌘T | Toggle typewriter scroll |
| ⇧⌘E | Export to HTML |
| ⇧⌥⌘E | Export to PDF |
| ⌃⌘F | Toggle full screen |

## Roadmap

- [x] macOS app
- [ ] iOS / iPadOS app
- [ ] iCloud sync across devices

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 6 (strict concurrency) |
| UI framework | SwiftUI (window/settings/toolbar) + AppKit NSTextView (text editing) |
| Markdown parsing | [swift-markdown](https://github.com/swiftlang/swift-markdown) |
| Testing | Swift Testing (`@Test`, `#expect`, `@Suite`) |
| PDF generation | WebKit `WKWebView.pdf(configuration:)` |
| Persistence | `ReferenceFileDocument` (SwiftUI document model) |
| Minimum | macOS 14 Sonoma |

## Architecture

See `ARCHITECTURE.md` for full details. Core pipeline:

```
User Input → Coordinator.textDidChange()
  → EditorViewModel.sourceText update
  → MarkdownParser.parse() → EditorNodeModel.applyParseResult()
  → SyntaxHighlighter.apply() → NSTextStorage attributes
  → Focus Mode dimming (when enabled)
```

### Directory Structure

```
shoechoo/
├── App/           # ShoechooApp, MarkdownDocument
├── Models/        # EditorNode, EditorNodeModel, EditorViewModel, EditorSettings
├── Parser/        # MarkdownParser (swift-markdown AST → EditorNode)
├── Renderer/      # SyntaxHighlighter (EditorNode → NSTextStorage attributes)
├── Theme/         # EditorTheme, ThemePresets, ThemeRegistry
├── Editor/        # ShoechooTextView (NSTextView), WYSIWYGTextView (NSViewRepresentable)
├── Views/         # EditorView, SidebarView, OutlineView, PreferencesView
└── Services/      # ExportService, FileService, ImageService (all actors)
```

### Theme System

- Colors accessed via `EditorTheme` protocol — never hardcoded
- `ThemeRegistry` manages active theme selection
- 7 preset themes: GitHub, Newsprint, Night, Pixyll, Whitey, Solarized Dark/Light

## Building from Source

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
git clone https://github.com/yoshidashingo/shoechoo.git
cd shoechoo
brew install xcodegen
xcodegen generate
xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -configuration Release CODE_SIGN_IDENTITY="-" build
```

Or run `xcodegen generate`, then open `shoechoo.xcodeproj` in Xcode and build with ⌘B.

### Build & Test Commands

```bash
# Build
xcodebuild -scheme shoechoo -destination 'platform=macOS' build

# Test (Swift Testing framework — outputs ◇/✔/✘)
xcodebuild -scheme shoechoo -destination 'platform=macOS' test
```

### Commit Convention

```
<type>: <description>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

### Documentation

- **Design docs**: specs and plans in `docs/`
- **Steering files**: work-in-progress docs in `.steering/[YYYYMMDD]-[title]/`

## License

[MIT](LICENSE)
