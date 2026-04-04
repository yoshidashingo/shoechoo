enum ThemePresets {

    static let defaultTheme = github

    static let all: [EditorTheme] = [
        github, newsprint, night, pixyll, whitey, solarizedLight, solarizedDark
    ]

    static let github = EditorTheme(
        id: "github", name: "GitHub", isDark: false,
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
