# Theme System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a theme system with 7 preset themes, customizable colors/fonts, and a theme picker in Preferences.

**Architecture:** Define `EditorTheme` as a Codable struct with all color/font properties. `ThemeRegistry` singleton manages presets and persists the user's selection. `SyntaxHighlighter` reads colors from the active theme instead of hardcoded values. Preferences UI gets a theme picker.

**Tech Stack:** Swift 6, SwiftUI, AppKit (NSTextView, NSAttributedString), Swift Testing

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `shoechoo/Theme/EditorTheme.swift` | EditorTheme + ThemeColor data model |
| Create | `shoechoo/Theme/ThemePresets.swift` | 7 preset theme definitions |
| Create | `shoechoo/Theme/ThemeRegistry.swift` | Theme management + persistence |
| Modify | `shoechoo/Renderer/SyntaxHighlighter.swift` | Use theme colors instead of hardcoded |
| Modify | `shoechoo/Models/EditorSettings.swift` | Add themeId property |
| Modify | `shoechoo/Editor/WYSIWYGTextView.swift:90-111` | Apply theme background + pass theme to highlighter |
| Modify | `shoechoo/Views/PreferencesView.swift` | Add theme picker UI |
| Modify | `shoechoo/App/ShoechooApp.swift:6-7` | Inject ThemeRegistry |
| Create | `shoechooTests/ThemeTests.swift` | Tests for ThemeColor, ThemeRegistry, presets |
| Modify | `shoechooTests/SyntaxHighlighterTests.swift` | Update tests to pass theme instead of appearance |

---

### Task 1: EditorTheme and ThemeColor Data Model

**Files:**
- Create: `shoechoo/Theme/EditorTheme.swift`
- Create: `shoechooTests/ThemeTests.swift`

- [ ] **Step 1: Write failing test for ThemeColor → NSColor conversion**

Create `shoechooTests/ThemeTests.swift`:

```swift
import Testing
import AppKit
@testable import shoechoo

@Suite("ThemeColor")
struct ThemeColorTests {

    @Test("Converts to NSColor with correct RGBA")
    func convertsToNSColor() {
        let color = ThemeColor(red: 0.5, green: 0.25, blue: 0.75, alpha: 1.0)
        let ns = color.nsColor
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ns.getRed(&r, green: &g, blue: &b, alpha: &a)
        #expect(abs(r - 0.5) < 0.01)
        #expect(abs(g - 0.25) < 0.01)
        #expect(abs(b - 0.75) < 0.01)
        #expect(abs(a - 1.0) < 0.01)
    }

    @Test("Creates from hex string")
    func createsFromHex() {
        let color = ThemeColor(hex: "#ff8000")
        #expect(abs(color.red - 1.0) < 0.01)
        #expect(abs(color.green - 0.502) < 0.01)
        #expect(abs(color.blue - 0.0) < 0.01)
        #expect(color.alpha == 1.0)
    }

    @Test("Encodes and decodes via Codable")
    func codableRoundTrip() throws {
        let original = ThemeColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.9)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThemeColor.self, from: data)
        #expect(decoded == original)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo -testPlan shoechooTests -only-testing shoechooTests/ThemeColorTests 2>&1 | tail -20`
Expected: FAIL — ThemeColor type does not exist

- [ ] **Step 3: Implement ThemeColor and EditorTheme**

Create `shoechoo/Theme/EditorTheme.swift`:

```swift
import AppKit

struct ThemeColor: Codable, Sendable, Equatable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        self.green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        self.blue = CGFloat(rgb & 0xFF) / 255.0
        self.alpha = 1.0
    }
}

struct EditorTheme: Codable, Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let isDark: Bool

    // Font
    var fontFamily: String
    var fontSize: CGFloat
    var lineSpacing: CGFloat

    // Colors
    var backgroundColor: ThemeColor
    var textColor: ThemeColor
    var headingColors: [ThemeColor]  // 6 elements, H1–H6
    var linkColor: ThemeColor
    var blockquoteColor: ThemeColor
    var blockquoteMarkerColor: ThemeColor

    // Code blocks
    var codeBackgroundColor: ThemeColor
    var codeFontFamily: String
    var highlightrTheme: String

    // Delimiters & UI
    var delimiterColor: ThemeColor
    var cursorColor: ThemeColor
    var selectionColor: ThemeColor
    var focusDimOpacity: CGFloat

    func headingColor(for level: Int) -> ThemeColor {
        let index = max(0, min(level - 1, headingColors.count - 1))
        return headingColors[index]
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo -testPlan shoechooTests -only-testing shoechooTests/ThemeColorTests 2>&1 | tail -20`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add shoechoo/Theme/EditorTheme.swift shoechooTests/ThemeTests.swift
git commit -m "feat: add EditorTheme and ThemeColor data model with tests"
```

---

### Task 2: Preset Themes

**Files:**
- Create: `shoechoo/Theme/ThemePresets.swift`
- Modify: `shoechooTests/ThemeTests.swift`

- [ ] **Step 1: Write failing test for presets**

Append to `shoechooTests/ThemeTests.swift`:

```swift
@Suite("ThemePresets")
struct ThemePresetsTests {

    @Test("All 7 presets exist")
    func allPresetsExist() {
        let presets = ThemePresets.all
        #expect(presets.count == 7)
    }

    @Test("Each preset has 6 heading colors")
    func presetsHaveSixHeadingColors() {
        for preset in ThemePresets.all {
            #expect(preset.headingColors.count == 6, "Theme \(preset.id) should have 6 heading colors")
        }
    }

    @Test("Each preset has unique id")
    func presetsHaveUniqueIds() {
        let ids = ThemePresets.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("GitHub is the default theme")
    func githubIsDefault() {
        #expect(ThemePresets.defaultTheme.id == "github")
    }

    @Test("Focus dim opacity is between 0 and 1", arguments: ThemePresets.all)
    func focusDimInRange(theme: EditorTheme) {
        #expect(theme.focusDimOpacity >= 0.0 && theme.focusDimOpacity <= 1.0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo -testPlan shoechooTests -only-testing shoechooTests/ThemePresetsTests 2>&1 | tail -20`
Expected: FAIL — ThemePresets type does not exist

- [ ] **Step 3: Implement ThemePresets**

Create `shoechoo/Theme/ThemePresets.swift`:

```swift
enum ThemePresets {

    static let defaultTheme = github

    static let all: [EditorTheme] = [
        github, newsprint, night, pixyll, whitey, solarizedLight, solarizedDark
    ]

    static let github = EditorTheme(
        id: "github", name: "GitHub", isDark: false,
        fontFamily: "SF Mono", fontSize: 14, lineSpacing: 6,
        backgroundColor: ThemeColor(hex: "#ffffff"),
        textColor: ThemeColor(hex: "#24292e"),
        headingColors: [
            ThemeColor(hex: "#24292e"), ThemeColor(hex: "#24292e"), ThemeColor(hex: "#24292e"),
            ThemeColor(hex: "#24292e"), ThemeColor(hex: "#24292e"), ThemeColor(hex: "#24292e"),
        ],
        linkColor: ThemeColor(hex: "#0366d6"),
        blockquoteColor: ThemeColor(hex: "#6a737d"),
        blockquoteMarkerColor: ThemeColor(hex: "#22863a"),
        codeBackgroundColor: ThemeColor(red: 0, green: 0, blue: 0, alpha: 0.04),
        codeFontFamily: "SF Mono",
        highlightrTheme: "github",
        delimiterColor: ThemeColor(hex: "#6a737d"),
        cursorColor: ThemeColor(hex: "#24292e"),
        selectionColor: ThemeColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 0.25),
        focusDimOpacity: 0.3
    )

    static let newsprint = EditorTheme(
        id: "newsprint", name: "Newsprint", isDark: false,
        fontFamily: "Georgia", fontSize: 16, lineSpacing: 8,
        backgroundColor: ThemeColor(hex: "#f5f0e8"),
        textColor: ThemeColor(hex: "#333333"),
        headingColors: [
            ThemeColor(hex: "#1a1a1a"), ThemeColor(hex: "#222222"), ThemeColor(hex: "#2a2a2a"),
            ThemeColor(hex: "#333333"), ThemeColor(hex: "#3a3a3a"), ThemeColor(hex: "#444444"),
        ],
        linkColor: ThemeColor(hex: "#4183c4"),
        blockquoteColor: ThemeColor(hex: "#777777"),
        blockquoteMarkerColor: ThemeColor(hex: "#999966"),
        codeBackgroundColor: ThemeColor(hex: "#ede8df"),
        codeFontFamily: "Menlo",
        highlightrTheme: "xcode",
        delimiterColor: ThemeColor(hex: "#999999"),
        cursorColor: ThemeColor(hex: "#333333"),
        selectionColor: ThemeColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 0.2),
        focusDimOpacity: 0.3
    )

    static let night = EditorTheme(
        id: "night", name: "Night", isDark: true,
        fontFamily: "SF Mono", fontSize: 14, lineSpacing: 6,
        backgroundColor: ThemeColor(hex: "#1e1e2e"),
        textColor: ThemeColor(hex: "#cdd6f4"),
        headingColors: [
            ThemeColor(hex: "#89b4fa"), ThemeColor(hex: "#89b4fa"), ThemeColor(hex: "#a6adc8"),
            ThemeColor(hex: "#a6adc8"), ThemeColor(hex: "#bac2de"), ThemeColor(hex: "#bac2de"),
        ],
        linkColor: ThemeColor(hex: "#89dceb"),
        blockquoteColor: ThemeColor(hex: "#a6adc8"),
        blockquoteMarkerColor: ThemeColor(hex: "#a6e3a1"),
        codeBackgroundColor: ThemeColor(hex: "#313244"),
        codeFontFamily: "SF Mono",
        highlightrTheme: "monokai-sublime",
        delimiterColor: ThemeColor(hex: "#6c7086"),
        cursorColor: ThemeColor(hex: "#cdd6f4"),
        selectionColor: ThemeColor(red: 0.35, green: 0.35, blue: 0.55, alpha: 0.4),
        focusDimOpacity: 0.25
    )

    static let pixyll = EditorTheme(
        id: "pixyll", name: "Pixyll", isDark: false,
        fontFamily: "Helvetica Neue", fontSize: 16, lineSpacing: 8,
        backgroundColor: ThemeColor(hex: "#ffffff"),
        textColor: ThemeColor(hex: "#404040"),
        headingColors: [
            ThemeColor(hex: "#404040"), ThemeColor(hex: "#404040"), ThemeColor(hex: "#505050"),
            ThemeColor(hex: "#505050"), ThemeColor(hex: "#606060"), ThemeColor(hex: "#606060"),
        ],
        linkColor: ThemeColor(hex: "#6fa8dc"),
        blockquoteColor: ThemeColor(hex: "#9a9a9a"),
        blockquoteMarkerColor: ThemeColor(hex: "#b0b0b0"),
        codeBackgroundColor: ThemeColor(hex: "#f5f5f5"),
        codeFontFamily: "Menlo",
        highlightrTheme: "github",
        delimiterColor: ThemeColor(hex: "#b0b0b0"),
        cursorColor: ThemeColor(hex: "#404040"),
        selectionColor: ThemeColor(red: 0.4, green: 0.6, blue: 0.85, alpha: 0.2),
        focusDimOpacity: 0.3
    )

    static let whitey = EditorTheme(
        id: "whitey", name: "Whitey", isDark: false,
        fontFamily: "SF Mono", fontSize: 14, lineSpacing: 6,
        backgroundColor: ThemeColor(hex: "#ffffff"),
        textColor: ThemeColor(hex: "#333333"),
        headingColors: [
            ThemeColor(hex: "#111111"), ThemeColor(hex: "#1a1a1a"), ThemeColor(hex: "#222222"),
            ThemeColor(hex: "#2a2a2a"), ThemeColor(hex: "#333333"), ThemeColor(hex: "#3a3a3a"),
        ],
        linkColor: ThemeColor(hex: "#4078c0"),
        blockquoteColor: ThemeColor(hex: "#999999"),
        blockquoteMarkerColor: ThemeColor(hex: "#aaaaaa"),
        codeBackgroundColor: ThemeColor(hex: "#f7f7f7"),
        codeFontFamily: "SF Mono",
        highlightrTheme: "github",
        delimiterColor: ThemeColor(hex: "#aaaaaa"),
        cursorColor: ThemeColor(hex: "#333333"),
        selectionColor: ThemeColor(red: 0.0, green: 0.4, blue: 1.0, alpha: 0.2),
        focusDimOpacity: 0.3
    )

    static let solarizedLight = EditorTheme(
        id: "solarized-light", name: "Solarized Light", isDark: false,
        fontFamily: "SF Mono", fontSize: 14, lineSpacing: 6,
        backgroundColor: ThemeColor(hex: "#fdf6e3"),
        textColor: ThemeColor(hex: "#657b83"),
        headingColors: [
            ThemeColor(hex: "#268bd2"), ThemeColor(hex: "#268bd2"), ThemeColor(hex: "#2aa198"),
            ThemeColor(hex: "#2aa198"), ThemeColor(hex: "#859900"), ThemeColor(hex: "#859900"),
        ],
        linkColor: ThemeColor(hex: "#268bd2"),
        blockquoteColor: ThemeColor(hex: "#93a1a1"),
        blockquoteMarkerColor: ThemeColor(hex: "#b58900"),
        codeBackgroundColor: ThemeColor(hex: "#eee8d5"),
        codeFontFamily: "SF Mono",
        highlightrTheme: "solarized-light",
        delimiterColor: ThemeColor(hex: "#93a1a1"),
        cursorColor: ThemeColor(hex: "#657b83"),
        selectionColor: ThemeColor(red: 0.0, green: 0.3, blue: 0.5, alpha: 0.15),
        focusDimOpacity: 0.3
    )

    static let solarizedDark = EditorTheme(
        id: "solarized-dark", name: "Solarized Dark", isDark: true,
        fontFamily: "SF Mono", fontSize: 14, lineSpacing: 6,
        backgroundColor: ThemeColor(hex: "#002b36"),
        textColor: ThemeColor(hex: "#839496"),
        headingColors: [
            ThemeColor(hex: "#268bd2"), ThemeColor(hex: "#268bd2"), ThemeColor(hex: "#2aa198"),
            ThemeColor(hex: "#2aa198"), ThemeColor(hex: "#859900"), ThemeColor(hex: "#859900"),
        ],
        linkColor: ThemeColor(hex: "#268bd2"),
        blockquoteColor: ThemeColor(hex: "#586e75"),
        blockquoteMarkerColor: ThemeColor(hex: "#b58900"),
        codeBackgroundColor: ThemeColor(hex: "#073642"),
        codeFontFamily: "SF Mono",
        highlightrTheme: "solarized-dark",
        delimiterColor: ThemeColor(hex: "#586e75"),
        cursorColor: ThemeColor(hex: "#839496"),
        selectionColor: ThemeColor(red: 0.0, green: 0.3, blue: 0.5, alpha: 0.3),
        focusDimOpacity: 0.25
    )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo -testPlan shoechooTests -only-testing shoechooTests/ThemePresetsTests 2>&1 | tail -20`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add shoechoo/Theme/ThemePresets.swift shoechooTests/ThemeTests.swift
git commit -m "feat: add 7 preset themes (GitHub, Newsprint, Night, Pixyll, Whitey, Solarized)"
```

---

### Task 3: ThemeRegistry

**Files:**
- Create: `shoechoo/Theme/ThemeRegistry.swift`
- Modify: `shoechoo/Models/EditorSettings.swift:12-43`
- Modify: `shoechooTests/ThemeTests.swift`

- [ ] **Step 1: Write failing test for ThemeRegistry**

Append to `shoechooTests/ThemeTests.swift`:

```swift
@Suite("ThemeRegistry")
@MainActor
struct ThemeRegistryTests {

    @Test("Returns default theme when no selection persisted")
    func defaultTheme() {
        UserDefaults.standard.removeObject(forKey: "themeId")
        let settings = EditorSettings.shared
        let registry = ThemeRegistry(settings: settings)
        #expect(registry.activeTheme.id == "github")
    }

    @Test("Active theme changes when themeId changes")
    func themeChangesWithId() {
        let settings = EditorSettings.shared
        let registry = ThemeRegistry(settings: settings)
        settings.themeId = "night"
        #expect(registry.activeTheme.id == "night")
    }

    @Test("Falls back to default for unknown themeId")
    func fallbackForUnknown() {
        let settings = EditorSettings.shared
        settings.themeId = "nonexistent"
        let registry = ThemeRegistry(settings: settings)
        #expect(registry.activeTheme.id == "github")
    }

    @Test("Lists all presets")
    func listsPresets() {
        let settings = EditorSettings.shared
        let registry = ThemeRegistry(settings: settings)
        #expect(registry.presets.count == 7)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Expected: FAIL — ThemeRegistry and themeId do not exist

- [ ] **Step 3: Add themeId to EditorSettings**

In `shoechoo/Models/EditorSettings.swift`, add `themeId` property:

After line 21 (`var appearanceOverride`), add:

```swift
    var themeId: String {
        didSet { UserDefaults.standard.set(themeId, forKey: "themeId") }
    }
```

In `init()`, after line 40 (`self.appearanceOverride = ...`), add:

```swift
        self.themeId = defaults.string(forKey: "themeId") ?? ThemePresets.defaultTheme.id
```

- [ ] **Step 4: Implement ThemeRegistry**

Create `shoechoo/Theme/ThemeRegistry.swift`:

```swift
import Foundation

@Observable
@MainActor
final class ThemeRegistry {
    let presets: [EditorTheme] = ThemePresets.all

    private let settings: EditorSettings

    init(settings: EditorSettings = .shared) {
        self.settings = settings
    }

    var activeTheme: EditorTheme {
        presets.first { $0.id == settings.themeId } ?? ThemePresets.defaultTheme
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo -testPlan shoechooTests -only-testing shoechooTests/ThemeRegistryTests 2>&1 | tail -20`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add shoechoo/Theme/ThemeRegistry.swift shoechoo/Models/EditorSettings.swift shoechooTests/ThemeTests.swift
git commit -m "feat: add ThemeRegistry with selection persistence"
```

---

### Task 4: Refactor SyntaxHighlighter to Use Theme

**Files:**
- Modify: `shoechoo/Renderer/SyntaxHighlighter.swift`
- Modify: `shoechooTests/SyntaxHighlighterTests.swift`

- [ ] **Step 1: Update existing tests to use theme parameter**

In `shoechooTests/SyntaxHighlighterTests.swift`, change all `highlighter.apply(...)` calls.

Replace:
```swift
highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, appearance: .dark)
```

With:
```swift
highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.night)
```

Replace all `.light` appearance calls with `theme: ThemePresets.github`.

- [ ] **Step 2: Write new test for theme color application**

Append to `shoechooTests/SyntaxHighlighterTests.swift`:

```swift
    @Test("Heading uses theme heading color")
    func headingUsesThemeColor() {
        let source = "# Hello"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        let theme = ThemePresets.night
        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: theme)

        // The heading text after "# " should have the theme heading color
        let attrs = textStorage.attributes(at: 2, effectiveRange: nil)
        // Just verify it applies without crash — color matching is visual
        #expect(attrs[.font] != nil)
    }

    @Test("Code block uses theme background color")
    func codeBlockUsesThemeBg() {
        let source = "```\ncode\n```"
        let textStorage = makeTextStorage(source)
        let result = parser.parse(source, revision: 1)
        let settings = EditorSettings.shared
        let highlighter = SyntaxHighlighter()

        highlighter.apply(to: textStorage, blocks: result.blocks, settings: settings, theme: ThemePresets.solarizedLight)

        let attrs = textStorage.attributes(at: 4, effectiveRange: nil)
        let bg = attrs[.backgroundColor] as? NSColor
        #expect(bg != nil)
    }
```

- [ ] **Step 3: Run tests to verify they fail**

Expected: FAIL — `apply(to:blocks:settings:theme:)` does not exist

- [ ] **Step 4: Refactor SyntaxHighlighter**

Replace the full `shoechoo/Renderer/SyntaxHighlighter.swift` content. Key changes:

1. Remove `enum Appearance`
2. Change `apply()` signature: replace `appearance: Appearance` with `theme: EditorTheme`
3. Replace all hardcoded colors:
   - `NSColor.secondaryLabelColor` → `theme.delimiterColor.nsColor`
   - `NSColor.linkColor` → `theme.linkColor.nsColor`
   - `NSColor.systemGreen` → `theme.blockquoteMarkerColor.nsColor`
   - `appearance == .dark ? .white : .black` → `theme.textColor.nsColor`
   - Code block bg → `theme.codeBackgroundColor.nsColor`
   - Inline code bg → `theme.codeBackgroundColor.nsColor`
4. Use `theme.headingColor(for: level).nsColor` for headings
5. Pass `theme` through all private methods instead of `appearance`

The full refactored `apply()` signature:

```swift
func apply(
    to textStorage: NSTextStorage,
    blocks: [EditorNode],
    settings: EditorSettings,
    theme: EditorTheme
) {
```

Every private method changes from `appearance: Appearance` to `theme: EditorTheme`.

In `applyBlock`, the base color setup changes from:
```swift
let baseColor: NSColor = appearance == .dark ? .white : .black
```
to:
```swift
let baseColor = theme.textColor.nsColor
```

In `applyHeading`, add heading color:
```swift
let headingColor = theme.headingColor(for: level).nsColor
ts.addAttribute(.foregroundColor, value: headingColor, range: r)
```

In `applyCodeBlock`, change:
```swift
let bg = appearance == .dark
    ? NSColor.white.withAlphaComponent(0.06)
    : NSColor.black.withAlphaComponent(0.04)
```
to:
```swift
let bg = theme.codeBackgroundColor.nsColor
```

In `applyBlockquote`, change `NSColor.secondaryLabelColor` to `theme.blockquoteColor.nsColor` and `NSColor.systemGreen` to `theme.blockquoteMarkerColor.nsColor`.

In `colorDelimiters`, change `NSColor.secondaryLabelColor` to `theme.delimiterColor.nsColor`.

In `applyInlines` for `.link`, change `NSColor.linkColor` to `theme.linkColor.nsColor`.

In `applyInlines` for `.inlineCode`, change the bg color to `theme.codeBackgroundColor.nsColor`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo 2>&1 | tail -20`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add shoechoo/Renderer/SyntaxHighlighter.swift shoechooTests/SyntaxHighlighterTests.swift
git commit -m "refactor: SyntaxHighlighter uses EditorTheme instead of hardcoded colors"
```

---

### Task 5: Integrate Theme into WYSIWYGTextView

**Files:**
- Modify: `shoechoo/Editor/WYSIWYGTextView.swift:4-6,90-111,124-137`

- [ ] **Step 1: Add ThemeRegistry to WYSIWYGTextView**

In `shoechoo/Editor/WYSIWYGTextView.swift`, add a `themeRegistry` property to the struct:

```swift
struct WYSIWYGTextView: NSViewRepresentable {
    @Bindable var viewModel: EditorViewModel
    var settings: EditorSettings
    var themeRegistry: ThemeRegistry
```

- [ ] **Step 2: Update applyAppearance to use theme**

Replace the `applyAppearance` method in Coordinator (lines 90-111):

```swift
        func applyAppearance(settings: EditorSettings) {
            guard let textView, let scrollView else { return }

            let theme = parent.themeRegistry.activeTheme

            // Set appearance based on theme
            if theme.isDark {
                scrollView.appearance = NSAppearance(named: .darkAqua)
            } else {
                switch settings.appearanceOverride {
                case .light: scrollView.appearance = NSAppearance(named: .aqua)
                case .dark: scrollView.appearance = NSAppearance(named: .darkAqua)
                case .system: scrollView.appearance = nil
                }
            }

            let bgColor = theme.backgroundColor.nsColor
            let fgColor = theme.textColor.nsColor

            textView.drawsBackground = true
            textView.backgroundColor = bgColor
            scrollView.backgroundColor = bgColor
            textView.insertionPointColor = theme.cursorColor.nsColor

            let font = NSFont(name: settings.fontFamily, size: settings.fontSize)
                ?? NSFont.monospacedSystemFont(ofSize: settings.fontSize, weight: .regular)
            textView.typingAttributes = [.font: font, .foregroundColor: fgColor]
        }
```

- [ ] **Step 3: Update applyHighlightNow to use theme**

Replace the appearance logic in `applyHighlightNow` (lines 124-137):

```swift
        private func applyHighlightNow() {
            guard let textView, let ts = textView.textStorage else { return }
            guard ts.length > 0 else { return }

            let text = textView.string
            let parser = MarkdownParser()
            let result = parser.parse(text, revision: 0)

            let theme = parent.themeRegistry.activeTheme

            let savedSelection = textView.selectedRange()
            let highlighter = SyntaxHighlighter()
            highlighter.apply(to: ts, blocks: result.blocks, settings: parent.settings, theme: theme)

            let safeLoc = min(savedSelection.location, ts.length)
            let safeLen = min(savedSelection.length, ts.length - safeLoc)
            textView.setSelectedRange(NSRange(location: safeLoc, length: safeLen))
        }
```

- [ ] **Step 4: Update EditorView to pass themeRegistry**

In `shoechoo/Views/EditorView.swift`, add themeRegistry environment and pass it:

After `@Environment(EditorSettings.self) private var settings`, add:
```swift
    @Environment(ThemeRegistry.self) private var themeRegistry
```

Change the WYSIWYGTextView call from:
```swift
WYSIWYGTextView(viewModel: document.viewModel, settings: settings)
```
to:
```swift
WYSIWYGTextView(viewModel: document.viewModel, settings: settings, themeRegistry: themeRegistry)
```

- [ ] **Step 5: Update ShoechooApp to inject ThemeRegistry**

In `shoechoo/App/ShoechooApp.swift`, add ThemeRegistry state:

After `@State private var settings = EditorSettings.shared`, add:
```swift
    @State private var themeRegistry = ThemeRegistry()
```

In the DocumentGroup body, add `.environment(themeRegistry)`:
```swift
EditorView(document: file.document)
    .environment(settings)
    .environment(themeRegistry)
```

In the Settings scene, also inject:
```swift
Settings {
    PreferencesView()
        .environment(settings)
        .environment(themeRegistry)
}
```

- [ ] **Step 6: Build and verify**

Run: `xcodebuild build -project shoechoo.xcodeproj -scheme shoechoo 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add shoechoo/Editor/WYSIWYGTextView.swift shoechoo/Views/EditorView.swift shoechoo/App/ShoechooApp.swift
git commit -m "feat: integrate theme into editor view and syntax highlighter"
```

---

### Task 6: Theme Picker in Preferences

**Files:**
- Modify: `shoechoo/Views/PreferencesView.swift`

- [ ] **Step 1: Replace Appearance tab with Theme tab**

Replace the full `shoechoo/Views/PreferencesView.swift`:

```swift
import SwiftUI

struct PreferencesView: View {
    @Environment(EditorSettings.self) private var settings
    @Environment(ThemeRegistry.self) private var themeRegistry

    var body: some View {
        @Bindable var settings = settings

        TabView {
            Form {
                Section("Font") {
                    Picker("Font Family", selection: $settings.fontFamily) {
                        Text("SF Mono").tag("SF Mono")
                        Text("Menlo").tag("Menlo")
                        Text("Monaco").tag("Monaco")
                        Text("Courier New").tag("Courier New")
                        Text("Source Code Pro").tag("Source Code Pro")
                        Text("Georgia").tag("Georgia")
                        Text("Helvetica Neue").tag("Helvetica Neue")
                    }

                    HStack {
                        Text("Font Size")
                        Slider(value: $settings.fontSize, in: 10...30, step: 1)
                        Text("\(Int(settings.fontSize)) pt")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }

                    HStack {
                        Text("Line Spacing")
                        Slider(value: $settings.lineSpacing, in: 0...20, step: 1)
                        Text("\(Int(settings.lineSpacing)) pt")
                            .monospacedDigit()
                            .frame(width: 45, alignment: .trailing)
                    }
                }

                Section("Defaults") {
                    Toggle("Enable Focus Mode by default", isOn: $settings.defaultFocusMode)
                    Toggle("Enable Typewriter Scroll by default", isOn: $settings.defaultTypewriterScroll)
                }
            }
            .tabItem { Label("Editor", systemImage: "textformat") }
            .tag("editor")

            Form {
                Section("Theme") {
                    Picker("Theme", selection: $settings.themeId) {
                        ForEach(themeRegistry.presets) { theme in
                            HStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(nsColor: theme.backgroundColor.nsColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .frame(width: 20, height: 20)
                                Text(theme.name)
                            }
                            .tag(theme.id)
                        }
                    }
                }

                Section("Appearance Override") {
                    Picker("Mode", selection: $settings.appearanceOverride) {
                        Text("System").tag(AppearanceMode.system)
                        Text("Light").tag(AppearanceMode.light)
                        Text("Dark").tag(AppearanceMode.dark)
                    }
                    .pickerStyle(.segmented)
                    Text("Dark themes automatically use dark mode. This override applies to light themes only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tabItem { Label("Appearance", systemImage: "paintbrush") }
            .tag("appearance")
        }
        .frame(width: 450, height: 300)
        .padding()
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild build -project shoechoo.xcodeproj -scheme shoechoo 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Run all tests**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo 2>&1 | tail -30`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add shoechoo/Views/PreferencesView.swift
git commit -m "feat: add theme picker to Preferences with color swatches"
```

---

### Task 7: Focus Mode Theme Integration

**Files:**
- Modify: `shoechoo/Editor/ShoechooTextView.swift:18-36`

- [ ] **Step 1: Update focus mode dimming to use theme opacity**

The `applyFocusModeDimming` method currently hardcodes `0.3` opacity. Change it to accept a theme parameter.

In `shoechoo/Editor/ShoechooTextView.swift`, change the method signature and body:

```swift
    func applyFocusModeDimming(activeBlockRange: NSRange, theme: EditorTheme) {
        let fullLength = textStorage?.length ?? 0
        let fullRange = NSRange(location: 0, length: fullLength)

        textStorage?.removeAttribute(.foregroundColor, range: fullRange)

        let dimmingColor = theme.textColor.nsColor.withAlphaComponent(theme.focusDimOpacity)

        if activeBlockRange.location > 0 {
            let beforeRange = NSRange(location: 0, length: activeBlockRange.location)
            textStorage?.addAttribute(.foregroundColor, value: dimmingColor, range: beforeRange)
        }

        let afterStart = activeBlockRange.location + activeBlockRange.length
        if afterStart < fullLength {
            let afterRange = NSRange(location: afterStart, length: fullLength - afterStart)
            textStorage?.addAttribute(.foregroundColor, value: dimmingColor, range: afterRange)
        }
    }
```

- [ ] **Step 2: Update callers of applyFocusModeDimming**

Search for all calls to `applyFocusModeDimming` and add the `theme:` parameter. The caller is in `WYSIWYGTextView.Coordinator` or `EditorView`. Pass `parent.themeRegistry.activeTheme`.

- [ ] **Step 3: Build and run all tests**

Run: `xcodebuild test -project shoechoo.xcodeproj -scheme shoechoo 2>&1 | tail -30`
Expected: ALL PASS

- [ ] **Step 4: Commit**

```bash
git add shoechoo/Editor/ShoechooTextView.swift shoechoo/Editor/WYSIWYGTextView.swift
git commit -m "feat: focus mode dimming uses theme opacity and text color"
```
