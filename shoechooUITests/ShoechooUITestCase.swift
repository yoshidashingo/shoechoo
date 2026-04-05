import XCTest

class ShoechooUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // DocumentGroup の新規ドキュメント作成
        // Open Dialog が出る場合は ⌘N で新規ドキュメントを開く
        let newDocTimeout: TimeInterval = 3
        let textView = app.textViews.firstMatch
        if !textView.waitForExistence(timeout: newDocTimeout) {
            app.typeKey("n", modifierFlags: .command)
            XCTAssertTrue(textView.waitForExistence(timeout: 5), "Editor text view should appear")
        }
    }

    override func tearDownWithError() throws {
        // ドキュメントを保存せず閉じる
        app.typeKey("w", modifierFlags: .command)
        let dontSaveButton = app.buttons["Don't Save"]
        if dontSaveButton.waitForExistence(timeout: 2) {
            dontSaveButton.click()
        }
        app = nil
    }

    /// エディタのメインテキストビューを取得
    var editorTextView: XCUIElement {
        app.textViews["editor.textView"]
    }

    /// テキストを入力してエディタに反映されるのを待つ
    func typeInEditor(_ text: String) {
        let textView = editorTextView.exists ? editorTextView : app.textViews.firstMatch
        textView.click()
        textView.typeText(text)
    }
}
