import XCTest

final class ToolbarUITests: ShoechooUITestCase {

    // MARK: - Helpers

    /// Clear all text in editor (select all + delete)
    private func clearEditor() {
        let textView = editorTextView.exists ? editorTextView : app.textViews.firstMatch
        textView.click()
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(.delete, modifierFlags: [])
        usleep(300_000)
    }

    /// Get the current text value from the editor
    private func editorValue() -> String {
        let textView = app.textViews.firstMatch
        return textView.value as? String ?? ""
    }

    /// Click the text view to ensure it has focus
    private func focusEditor() {
        let textView = editorTextView.exists ? editorTextView : app.textViews.firstMatch
        textView.click()
        usleep(200_000)
    }

    // MARK: - Toolbar Button Tests

    func testBoldToggleViaToolbar() throws {
        clearEditor()
        typeInEditor("bold text")
        app.typeKey("a", modifierFlags: .command)

        let boldButton = app.buttons["toolbar.bold"]
        XCTAssertTrue(boldButton.waitForExistence(timeout: 3))
        boldButton.click()

        // After toolbar click, refocus editor to read value
        usleep(500_000)
        let value = editorValue()
        XCTAssertTrue(value.contains("**bold text**"), "Text should be wrapped with bold markers, got: \(value)")
    }

    func testItalicToggleViaToolbar() throws {
        clearEditor()
        typeInEditor("italic text")
        app.typeKey("a", modifierFlags: .command)

        let italicButton = app.buttons["toolbar.italic"]
        XCTAssertTrue(italicButton.waitForExistence(timeout: 3))
        italicButton.click()

        usleep(500_000)
        let value = editorValue()
        XCTAssertTrue(value.contains("*italic text*"), "Text should be wrapped with italic markers, got: \(value)")
    }

    func testInlineCodeToggleViaToolbar() throws {
        clearEditor()
        typeInEditor("code")
        app.typeKey("a", modifierFlags: .command)

        let codeButton = app.buttons["toolbar.inlineCode"]
        XCTAssertTrue(codeButton.waitForExistence(timeout: 3))
        codeButton.click()

        usleep(500_000)
        let value = editorValue()
        XCTAssertTrue(value.contains("`code`"), "Text should be wrapped with backticks, got: \(value)")
    }

    // MARK: - Keyboard Shortcut Tests

    func testBoldViaKeyboardShortcut() throws {
        clearEditor()
        typeInEditor("shortcut bold")
        app.typeKey("a", modifierFlags: .command)
        app.typeKey("b", modifierFlags: .command)

        usleep(500_000)
        let value = editorValue()
        XCTAssertTrue(value.contains("**shortcut bold**"), "⌘B should toggle bold, got: \(value)")
    }

    func testItalicViaKeyboardShortcut() throws {
        clearEditor()
        typeInEditor("shortcut italic")
        app.typeKey("a", modifierFlags: .command)
        app.typeKey("i", modifierFlags: .command)

        usleep(500_000)
        let value = editorValue()
        XCTAssertTrue(value.contains("*shortcut italic*"), "⌘I should toggle italic, got: \(value)")
    }
}
