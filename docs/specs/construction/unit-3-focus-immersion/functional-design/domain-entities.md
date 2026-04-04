---
layout: default
---

# Domain Entities: Unit 3 — Focus & Immersion

## FocusModeState

Represents the current state of focus mode for a document editor session.

```swift
struct FocusModeState: Equatable {
    var isEnabled: Bool
    var activeBlockID: EditorNode.ID?
    var dimmingConfiguration: DimmingConfiguration
    var transitionStyle: TransitionStyle
}
```

### TransitionStyle

Controls how dimming transitions are animated, respecting accessibility preferences.

```swift
enum TransitionStyle: Equatable {
    case animated(duration: TimeInterval)   // Default: 0.2s fade
    case immediate                          // Used when "Reduce motion" is enabled
}
```

---

## DimmingConfiguration

Defines the visual parameters for dimming inactive paragraphs in focus mode.

```swift
struct DimmingConfiguration: Equatable {
    var inactiveAlpha: CGFloat              // Alpha for non-active blocks (default: 0.3)
    var activeAlpha: CGFloat                // Alpha for the active block (default: 1.0)
    var dimmingGranularity: DimmingGranularity
}
```

### DimmingGranularity

Defines what unit of text is considered "active" for dimming purposes.

```swift
enum DimmingGranularity: Equatable {
    case paragraph                          // Dim all blocks except the one containing the cursor
}
```

**Design note**: Only paragraph-level granularity is supported for MVP. Sentence-level or section-level granularity may be added in future units.

---

## TypewriterScrollState

Represents the current state of typewriter scrolling for a document editor session.

```swift
struct TypewriterScrollState: Equatable {
    var isEnabled: Bool
    var centerOffset: CGFloat?              // Computed: vertical center of the visible rect
    var activeLineRect: CGRect?             // Layout rect of the line containing the cursor
    var scrollBehavior: ScrollBehavior
}
```

### ScrollBehavior

Controls how the scroll position adjusts to keep the active line centered.

```swift
enum ScrollBehavior: Equatable {
    case smooth(duration: TimeInterval)     // Default: 0.15s animation
    case immediate                          // Used when "Reduce motion" is enabled
    case suppressed                         // Short document — no scroll needed
}
```

**Short document rule**: When the total document height is less than or equal to the visible area height, typewriter scrolling is suppressed to avoid adding unnecessary empty padding.

---

## FullScreenState

Represents the current full-screen writing mode state.

```swift
struct FullScreenState: Equatable {
    var isFullScreen: Bool
    var toolbarPolicy: ToolbarPolicy
    var sidebarPolicy: SidebarPolicy
}
```

### ToolbarPolicy

```swift
enum ToolbarPolicy: Equatable {
    case alwaysVisible                      // Normal windowed mode
    case autoHide                           // Full-screen: hide after inactivity
}
```

### SidebarPolicy

```swift
enum SidebarPolicy: Equatable {
    case visible                            // Normal windowed mode
    case hidden                             // Full-screen: sidebar collapsed
    case autoHide                           // Full-screen: show on hover near edge
}
```

---

## FocusImmersionSettings (EditorSettings Extension)

Persistent user preferences for focus and immersion features. These fields extend the existing `EditorSettings` model.

```swift
extension EditorSettings {
    // Already declared in EditorSettings (Unit 2):
    var defaultFocusMode: Bool              // Persist focus mode on/off (default: false)
    var defaultTypewriterScroll: Bool       // Persist typewriter scroll on/off (default: false)

    // Dimming preferences (new):
    var focusDimmingAlpha: CGFloat          // Inactive block alpha (default: 0.3)
}
```

---

## ActiveBlockRange

A lightweight value describing the text range of the currently active block, used to drive both dimming and typewriter scroll calculations.

```swift
struct ActiveBlockRange: Equatable {
    var blockID: EditorNode.ID
    var textRange: NSRange                  // Range in the NSTextStorage
    var layoutRect: CGRect                  // Bounding rect from NSTextLayoutManager
}
```

---

## KeyboardShortcutBinding

Represents a keyboard shortcut for focus/immersion commands.

```swift
enum FocusImmersionShortcut {
    case toggleFocusMode                    // Cmd+Shift+F
    case toggleTypewriterScroll             // Cmd+Ctrl+T
    case toggleFullScreen                   // Ctrl+Cmd+F (macOS standard)
}
```

| Shortcut | Key Combination | Action |
|----------|:---:|--------|
| toggleFocusMode | Cmd+Shift+F | Enable/disable focus mode dimming |
| toggleTypewriterScroll | Cmd+Ctrl+T | Enable/disable typewriter scrolling |
| toggleFullScreen | Ctrl+Cmd+F | Enter/exit native macOS full-screen |
