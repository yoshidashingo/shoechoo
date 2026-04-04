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

    var backgroundColor: ThemeColor
    var textColor: ThemeColor
    var headingColors: [ThemeColor]  // 6 elements, H1-H6
    var linkColor: ThemeColor
    var blockquoteColor: ThemeColor
    var blockquoteMarkerColor: ThemeColor

    var codeBackgroundColor: ThemeColor
    var codeFontFamily: String
    var highlightrTheme: String

    var delimiterColor: ThemeColor
    var cursorColor: ThemeColor
    var selectionColor: ThemeColor
    var focusDimOpacity: CGFloat

    func headingColor(for level: Int) -> ThemeColor {
        let index = max(0, min(level - 1, headingColors.count - 1))
        return headingColors[index]
    }
}
