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
