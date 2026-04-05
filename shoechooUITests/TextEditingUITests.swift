import XCTest

final class TextEditingUITests: ShoechooUITestCase {

    // MARK: - Tests

    func testTypeTextAndVerify() throws {
        clearEditor()
        typeInEditor("Hello, World!")

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("Hello, World!"), "Typed text should appear in editor, got: \(value)")
    }

    func testTypeMarkdownHeading() throws {
        clearEditor()
        // '#' may conflict with keyboard shortcuts, so paste via clipboard
        pasteInEditor("# My Heading\n\nSome body text.")

        let textView = app.textViews.firstMatch
        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("# My Heading"), "Heading should appear in editor, got: \(value)")
        XCTAssertTrue(value.contains("Some body text."), "Body text should appear, got: \(value)")
    }

    func testWordCountUpdatesAfterTyping() throws {
        clearEditor()
        typeInEditor("one two three four five")

        // Wait for stats bar debounce (0.15s) plus rendering.
        // Stats Text elements share the "editor.stats" identifier, so match by value.
        let fiveWords = app.staticTexts.matching(
            NSPredicate(format: "value == '5 words'")
        ).firstMatch
        XCTAssertTrue(fiveWords.waitForExistence(timeout: 10), "Stats bar should show '5 words'")
    }

    func testMultilineInput() throws {
        clearEditor()
        // typeText with \n can lose keyboard focus, so paste via clipboard
        pasteInEditor("Line 1\nLine 2\nLine 3\n")

        // Stats bar shows each stat in a separate Text view: "N lines"
        let linesText = app.staticTexts.matching(
            NSPredicate(format: "value CONTAINS 'lines' OR label CONTAINS 'lines'")
        ).firstMatch
        XCTAssertTrue(linesText.waitForExistence(timeout: 10), "Stats bar should show line count")
    }
}
