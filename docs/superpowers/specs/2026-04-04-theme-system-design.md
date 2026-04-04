# Theme System Design

**Date:** 2026-04-04
**Status:** Approved
**Issue:** #21

## Problem

Shoechoo currently has no theme system. All colors in `SyntaxHighlighter.swift` are hardcoded (`NSColor.secondaryLabelColor`, `NSColor.linkColor`, etc.), and appearance is limited to a light/dark mode toggle. Users cannot customize the editor's look, and there are no preset themes like competing editors (Typora, iA Writer).

## Solution

Add a theme system with 7 preset themes (Typora-inspired), a `Codable` theme data model for future extensibility, and a theme selection UI in Preferences.

## Data Model

### EditorTheme

```swift
struct EditorTheme: Codable, Identifiable, Sendable, Equatable {
    let id: String              // e.g. "github", "night"
    let name: String            // Display name
    let isDark: Bool            // Whether this is a dark theme

    // Font
    var fontFamily: String      // e.g. "SF Mono", "Georgia"
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
    var codeFontFamily: String          // e.g. "SF Mono"
    var highlightrTheme: String         // Highlightr theme name

    // Delimiters & UI
    var delimiterColor: ThemeColor
    var cursorColor: ThemeColor
    var selectionColor: ThemeColor
    var focusDimOpacity: CGFloat        // 0.0–1.0
}
```

### ThemeColor

Codable wrapper for RGBA color values, with computed `nsColor` property:

```swift
struct ThemeColor: Codable, Sendable, Equatable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
```

Convenience initializer from hex string for preset definitions.

## Theme Registry

`ThemeRegistry` is an `@Observable @MainActor` singleton that manages presets and user selection.

**Responsibilities:**
- Holds the array of preset themes
- Persists the selected theme ID to UserDefaults
- Provides `activeTheme: EditorTheme` computed from the selected ID
- Provides `effectiveTheme: EditorTheme` that factors in the user's font/spacing overrides from EditorSettings

**Integration with EditorSettings:**
- `EditorSettings` gains a `themeId: String` property (persisted to UserDefaults)
- When `themeId` changes, `SyntaxHighlighter` uses the new theme's colors on next `apply()` call
- `fontFamily`, `fontSize`, `lineSpacing` on EditorSettings override the theme defaults (user customization)

## Preset Themes (7)

| Theme | isDark | Background | Text | Heading | Code BG | Highlightr |
|-------|--------|-----------|------|---------|---------|------------|
| GitHub | false | #ffffff | #24292e | #24292e | #f6f8fa | github |
| Newsprint | false | #f5f0e8 | #333333 | #1a1a1a | #ede8df | xcode |
| Night | true | #1e1e2e | #cdd6f4 | #89b4fa | #313244 | monokai-sublime |
| Pixyll | false | #ffffff | #404040 | #404040 | #f5f5f5 | github |
| Whitey | false | #ffffff | #333333 | #111111 | #f7f7f7 | github |
| Solarized Light | false | #fdf6e3 | #657b83 | #268bd2 | #eee8d5 | solarized-light |
| Solarized Dark | true | #002b36 | #839496 | #268bd2 | #073642 | solarized-dark |

Each preset includes full color definitions for all ThemeColor fields, a default font family (monospace for code themes, serif for Newsprint), and all heading level colors (H1–H6 with decreasing emphasis).

## SyntaxHighlighter Changes

Replace all hardcoded colors with theme lookups:

| Current (hardcoded) | New (from theme) |
|---------------------|-----------------|
| `NSColor.secondaryLabelColor` (delimiters) | `theme.delimiterColor.nsColor` |
| `NSColor.linkColor` | `theme.linkColor.nsColor` |
| `NSColor.systemGreen` (blockquote markers) | `theme.blockquoteMarkerColor.nsColor` |
| `NSColor.white/.black` (base text) | `theme.textColor.nsColor` |
| `NSColor.white/black.withAlpha` (code bg) | `theme.codeBackgroundColor.nsColor` |
| `NSColor.labelColor.withAlpha(0.3)` (focus dim) | `theme.textColor.nsColor.withAlpha(theme.focusDimOpacity)` |

The `apply()` method gains a `theme: EditorTheme` parameter instead of `appearance: Appearance`.

## Background Color Application

The editor background color is set on the `NSTextView` (not via text attributes). `ShoechooTextView` or `WYSIWYGTextView` applies `theme.backgroundColor.nsColor` as `backgroundColor` when the theme changes.

## Preferences UI Changes

Expand the Appearance tab:

1. **Theme picker** — Picker with theme names, replaces the current light/dark segmented control
2. **Preview swatch** — Small colored rectangle showing background + text color of selected theme
3. The existing light/dark/system toggle becomes subordinate: if the user picks a dark theme, appearance automatically sets to dark (and vice versa). Manual override remains available.

The Editor tab (font, size, spacing) stays as-is — these override the theme defaults.

## File Structure

```
shoechoo/
├── Theme/                          (new directory)
│   ├── EditorTheme.swift           # EditorTheme + ThemeColor structs
│   ├── ThemePresets.swift          # 7 preset theme definitions
│   └── ThemeRegistry.swift         # Theme management singleton
├── Renderer/
│   └── SyntaxHighlighter.swift     # Modified: use theme colors
├── Models/
│   └── EditorSettings.swift        # Modified: add themeId property
├── Editor/
│   ├── ShoechooTextView.swift      # Modified: apply theme background
│   └── WYSIWYGTextView.swift       # Modified: pass theme to highlighter
├── Views/
│   └── PreferencesView.swift       # Modified: theme picker UI
└── App/
    └── ShoechooApp.swift           # Modified: inject ThemeRegistry
```

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Data format | Swift structs + Codable | Type-safe presets, JSON-ready for future external themes |
| Theme storage | ThemeRegistry singleton | Follows existing EditorSettings pattern |
| Selection persistence | UserDefaults (themeId string) | Consistent with existing settings approach |
| Font override | EditorSettings overrides theme | User font choice should persist across theme changes |
| Appearance integration | Theme isDark drives appearance | Reduces configuration burden; manual override kept |

## Out of Scope

- User-defined custom themes (file-based `.shoechoo-theme` import)
- Per-theme sidebar styling
- Theme preview in a full editor mock
- Theme marketplace or sharing
- Export theme as JSON

## Testing Strategy

- Unit tests for `ThemeColor` ↔ `NSColor` conversion
- Unit tests for `ThemeRegistry` selection and persistence
- Unit tests for all preset themes (valid colors, 6 heading colors each)
- Integration test: `SyntaxHighlighter` applies theme colors correctly
