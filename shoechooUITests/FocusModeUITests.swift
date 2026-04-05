import XCTest

final class FocusModeUITests: ShoechooUITestCase {

    // MARK: - Focus Mode

    func testToggleFocusModeViaToolbar() throws {
        // Use clipboard paste for multiline text (typeText("\n") is unreliable)
        let textView = editorTextView.exists ? editorTextView : app.textViews.firstMatch
        textView.click()

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("# Heading\n\nParagraph one.\n\nParagraph two.\n\nParagraph three.", forType: .string)
        app.typeKey("v", modifierFlags: .command)
        usleep(500_000)

        let focusButton = app.buttons["toolbar.focusMode"]
        XCTAssertTrue(focusButton.waitForExistence(timeout: 3), "Focus mode button should exist")

        focusButton.click()  // ON
        usleep(500_000)

        // After toolbar click, click text view to restore focus
        textView.click()
        usleep(200_000)

        focusButton.click()  // OFF
        usleep(500_000)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.exists, "Editor should still be functional after focus mode toggle")
    }

    func testToggleFocusModeViaShortcut() throws {
        typeInEditor("Some text for focus mode test.")
        usleep(300_000)

        app.typeKey("f", modifierFlags: [.command, .shift])  // ON
        usleep(500_000)
        app.typeKey("f", modifierFlags: [.command, .shift])  // OFF
        usleep(500_000)

        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor should still be functional")
    }

    // MARK: - Typewriter Scroll

    func testToggleTypewriterScrollViaToolbar() throws {
        typeInEditor("Typewriter scroll test content.")
        usleep(300_000)

        let typewriterButton = app.buttons["toolbar.typewriterScroll"]
        XCTAssertTrue(typewriterButton.waitForExistence(timeout: 3), "Typewriter scroll button should exist")

        typewriterButton.click()  // ON
        usleep(500_000)

        // After toolbar click, click text view to restore focus
        let textView = editorTextView.exists ? editorTextView : app.textViews.firstMatch
        textView.click()
        usleep(200_000)

        typewriterButton.click()  // OFF
        usleep(500_000)

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.exists, "Editor should still be functional after typewriter scroll toggle")
    }

    func testToggleTypewriterScrollViaShortcut() throws {
        typeInEditor("Test.")
        usleep(300_000)

        app.typeKey("t", modifierFlags: [.command, .shift])  // ON
        usleep(500_000)
        app.typeKey("t", modifierFlags: [.command, .shift])  // OFF
        usleep(500_000)

        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor should still be functional")
    }
}
