import SwiftUI

struct PreferencesView: View {
    @Environment(EditorSettings.self) private var settings

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
                Section("Appearance") {
                    Picker("Theme", selection: $settings.appearanceOverride) {
                        Text("System").tag(AppearanceMode.system)
                        Text("Light").tag(AppearanceMode.light)
                        Text("Dark").tag(AppearanceMode.dark)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .tabItem { Label("Appearance", systemImage: "paintbrush") }
            .tag("appearance")
        }
        .frame(width: 450, height: 250)
        .padding()
    }
}
