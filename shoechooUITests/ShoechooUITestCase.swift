import XCTest

class ShoechooUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // Handle macOS "Reopen documents?" dialog after crash recovery.
        // Button title uses smart apostrophe, so match by accessibility identifier.
        let dontReopenButton = app.buttons["action-button--999"]
        if dontReopenButton.waitForExistence(timeout: 3) {
            dontReopenButton.click()
        }

        // DocumentGroup: create new document if no editor appeared
        let newDocTimeout: TimeInterval = 3
        let textView = app.textViews.firstMatch
        if !textView.waitForExistence(timeout: newDocTimeout) {
            app.typeKey("n", modifierFlags: .command)
            XCTAssertTrue(textView.waitForExistence(timeout: 5), "Editor text view should appear")
        }
    }

    override func tearDownWithError() throws {
        app.typeKey("w", modifierFlags: .command)
        let dontSaveButton = app.buttons["Don\u{2019}t Save"]
        if dontSaveButton.waitForExistence(timeout: 2) {
            dontSaveButton.click()
        }
        app = nil
    }

    /// Get the main editor text view
    var editorTextView: XCUIElement {
        app.textViews["editor.textView"]
    }

    /// Type text into the editor
    func typeInEditor(_ text: String) {
        let textView = editorTextView.exists ? editorTextView : app.textViews.firstMatch
        textView.click()
        textView.typeText(text)
    }
}
