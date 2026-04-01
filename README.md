<h1 align="center">
  <img src="docs/icon.png" alt="shoechoo" width="128">
  <br>
  shoechoo
  <br>
  <br>
</h1>

<p align="center">
  A distraction-free Markdown editor for macOS that lets you focus on writing.
</p>

<p align="center">
  <a href="https://github.com/yoshidashingo/shoechoo/releases/latest"><img src="https://img.shields.io/github/v/release/yoshidashingo/shoechoo?v=1" alt="release"></a>
  <a href="https://github.com/yoshidashingo/shoechoo/blob/main/LICENSE"><img src="https://img.shields.io/github/license/yoshidashingo/shoechoo?v=1" alt="license"></a>
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
- **Syntax Highlighting** — Subtle, readable highlighting for Markdown elements without visual clutter

### Writing Focus
- **Focus Mode** — Dims everything except the current paragraph to keep you in the zone
- **Typewriter Scrolling** — Keeps the active line centered on screen for a comfortable writing posture
- **Full Screen** — Immersive full-screen writing with no distractions

### Markdown
- **Full Markdown Support** — Headings, lists, tables, code blocks, math (LaTeX), footnotes, and more
- **Image Support** — Drag & drop or paste images directly into your document
- **Export** — Save as Markdown, HTML, or PDF

### General
- **Native macOS App** — Built with Swift and SwiftUI for a fast, lightweight experience
- **File Management** — Open, edit, and save `.md` files with standard macOS file handling
- **Dark Mode** — Full support for macOS light and dark appearances
- **Minimal Footprint** — Low memory usage, instant launch

## Requirements

- macOS 14 (Sonoma) or later

## Installation

1. Download the latest version from the **[Releases page](https://github.com/yoshidashingo/shoechoo/releases/latest)**
2. Open the `.zip` or `.dmg` and move `shoechoo.app` to your Applications folder
3. Launch shoechoo

> **Note**: This app is not notarized. On first launch, macOS will block it. To open it:
>
> **Option A** (Terminal):
> ```
> xattr -cr /Applications/shoechoo.app
> ```
> Then launch the app normally.
>
> **Option B** (System Settings):
> 1. Try to open `shoechoo.app` (it will be blocked)
> 2. Open **System Settings** → **Privacy & Security**
> 3. Scroll down to find the blocked app message and click **Open Anyway**

## Usage

1. Launch shoechoo — a new editor window opens
2. Start writing in Markdown — formatting is rendered live as you type
3. **⌘N** — Create a new document
4. **⌘O** — Open an existing Markdown file
5. **⌘S** — Save the current document
6. **⌘⇧F** — Toggle focus mode
7. **⌘⇧E** — Export to HTML or PDF

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | New document |
| ⌘O | Open file |
| ⌘S | Save |
| ⌘⇧S | Save as |
| ⌘⇧F | Toggle focus mode |
| ⌘⇧E | Export |
| ⌃⌘F | Toggle full screen |

## Roadmap

- [x] macOS app
- [ ] iOS / iPadOS app
- [ ] iCloud sync across devices

## Building from Source

```bash
git clone https://github.com/yoshidashingo/shoechoo.git
cd shoechoo
xcodebuild -project shoechoo.xcodeproj -scheme shoechoo -configuration Release build
```

Or open `shoechoo.xcodeproj` in Xcode and build with ⌘B.

## License

MIT
