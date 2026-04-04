import SwiftUI

enum AppearanceMode: String, CaseIterable, Sendable {
    case system
    case light
    case dark
}

@Observable
@MainActor
final class EditorSettings {
    var fontFamily: String {
        didSet { UserDefaults.standard.set(fontFamily, forKey: "fontFamily") }
    }
    var fontSize: CGFloat {
        didSet { UserDefaults.standard.set(fontSize, forKey: "fontSize") }
    }
    var lineSpacing: CGFloat {
        didSet { UserDefaults.standard.set(lineSpacing, forKey: "lineSpacing") }
    }

    var appearanceOverride: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceOverride.rawValue, forKey: "appearanceOverride") }
    }

    var defaultFocusMode: Bool {
        didSet { UserDefaults.standard.set(defaultFocusMode, forKey: "defaultFocusMode") }
    }
    var defaultTypewriterScroll: Bool {
        didSet { UserDefaults.standard.set(defaultTypewriterScroll, forKey: "defaultTypewriterScroll") }
    }
    var autoSaveEnabled: Bool {
        didSet { UserDefaults.standard.set(autoSaveEnabled, forKey: "autoSaveEnabled") }
    }
    var autoSaveIntervalSeconds: Int {
        didSet { UserDefaults.standard.set(autoSaveIntervalSeconds, forKey: "autoSaveIntervalSeconds") }
    }

    static let shared = EditorSettings()

    private init() {
        let defaults = UserDefaults.standard
        self.fontFamily = defaults.string(forKey: "fontFamily") ?? "SF Mono"
        self.fontSize = defaults.object(forKey: "fontSize") as? CGFloat ?? 14
        self.lineSpacing = defaults.object(forKey: "lineSpacing") as? CGFloat ?? 6
        self.appearanceOverride = AppearanceMode(rawValue: defaults.string(forKey: "appearanceOverride") ?? "") ?? .system
        self.defaultFocusMode = defaults.bool(forKey: "defaultFocusMode")
        self.defaultTypewriterScroll = defaults.bool(forKey: "defaultTypewriterScroll")
        if defaults.object(forKey: "autoSaveEnabled") == nil {
            self.autoSaveEnabled = true
        } else {
            self.autoSaveEnabled = defaults.bool(forKey: "autoSaveEnabled")
        }
        self.autoSaveIntervalSeconds = defaults.object(forKey: "autoSaveIntervalSeconds") as? Int ?? 10
    }
}
