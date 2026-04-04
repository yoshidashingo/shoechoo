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

                Section("Auto-Save") {
                    Toggle("Enable Auto-Save", isOn: $settings.autoSaveEnabled)

                    if settings.autoSaveEnabled {
                        Picker("Save after idle", selection: $settings.autoSaveIntervalSeconds) {
                            Text("5 seconds").tag(5)
                            Text("10 seconds").tag(10)
                            Text("30 seconds").tag(30)
                            Text("60 seconds").tag(60)
                        }
                    }
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
