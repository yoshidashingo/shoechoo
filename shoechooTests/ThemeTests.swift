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
