import XCTest

final class AppLaunchUITests: ShoechooUITestCase {

    func testAppLaunchesWithEditorWindow() throws {
        // ウィンドウが表示されていること
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "App should have a window")

        // エディタ（テキストビュー）が存在すること
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists, "Editor text view should be visible")
    }

    func testWindowTitleShowsUntitled() throws {
        let window = app.windows.firstMatch
        // DocumentGroup の新規ドキュメントは "Untitled" というタイトル
        XCTAssertTrue(window.title.contains("Untitled"), "New document should be Untitled, got: \(window.title)")
    }

    func testStatsBarIsVisible() throws {
        // accessibilityIdentifier "editor.stats" で配置されたステータスバー
        let statsBar = app.groups["editor.stats"].firstMatch
        if statsBar.waitForExistence(timeout: 3) {
            XCTAssertTrue(statsBar.exists, "Stats bar should be visible")
        } else {
            // フォールバック: "words" を含むテキストで探す
            let statsText = app.staticTexts.matching(
                NSPredicate(format: "value CONTAINS[c] 'words' OR label CONTAINS[c] 'words'")
            ).firstMatch
            XCTAssertTrue(statsText.waitForExistence(timeout: 3), "Stats bar showing word count should be visible")
        }
    }

    func testToolbarButtonsExist() throws {
        // ツールバーボタンの存在確認 — SwiftUI toolbar buttons
        let boldButton = app.buttons["toolbar.bold"]
        XCTAssertTrue(boldButton.waitForExistence(timeout: 5), "Bold button should exist")
        XCTAssertTrue(app.buttons["toolbar.italic"].exists, "Italic button should exist")
        XCTAssertTrue(app.buttons["toolbar.inlineCode"].exists, "Inline code button should exist")
        XCTAssertTrue(app.buttons["toolbar.focusMode"].exists, "Focus mode button should exist")
        XCTAssertTrue(app.buttons["toolbar.export"].exists, "Export button should exist")
    }
}
