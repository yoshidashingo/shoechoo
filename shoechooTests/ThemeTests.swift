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
