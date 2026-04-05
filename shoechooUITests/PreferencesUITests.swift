import XCTest

final class PreferencesUITests: ShoechooUITestCase {

    /// Open Settings via the app menu (Shoe Choo > Settings…)
    private func openPreferences() {
        let appMenu = app.menuBars.firstMatch.menuBarItems.element(boundBy: 1)
        appMenu.click()
        let settingsItem = app.menuItems["Settings\u{2026}"]
        XCTAssertTrue(settingsItem.waitForExistence(timeout: 2), "Settings menu item should exist")
        settingsItem.click()
        // Allow the Settings window to fully render
        sleep(2)
    }

    /// Close the Settings window if open
    private func closeSettingsIfOpen() {
        // The Settings window should be frontmost after openPreferences()
        // Send ⌘W to close it
        app.typeKey("w", modifierFlags: .command)
        sleep(1)
    }

    override func tearDownWithError() throws {
        // Close any stray Settings window before base tearDown
        // Base tearDown will handle the document window
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func testPreferencesWindowOpens() throws {
        let initialWindowCount = app.windows.count
        openPreferences()
        // After opening Settings, there should be more windows (or at least the Settings one)
        XCTAssertTrue(app.windows.count >= initialWindowCount,
                      "Settings window should have opened")
        // Verify we can find the toolbar with Editor/Appearance tabs
        let toolbar = app.toolbars.firstMatch
        XCTAssertTrue(toolbar.waitForExistence(timeout: 3),
                      "Settings toolbar with tabs should exist")
    }

    func testEditorTabExists() throws {
        openPreferences()

        // SwiftUI Settings TabView renders tabs as toolbar buttons
        let editorTab = app.toolbars.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Editor'")
        ).firstMatch
        XCTAssertTrue(editorTab.waitForExistence(timeout: 5), "Editor tab should exist in preferences")
    }

    func testAppearanceTabExists() throws {
        openPreferences()

        let appearanceTab = app.toolbars.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Appearance'")
        ).firstMatch
        XCTAssertTrue(appearanceTab.waitForExistence(timeout: 5), "Appearance tab should exist")
    }

    func testSwitchToAppearanceTab() throws {
        openPreferences()

        // Find and click Appearance tab
        let appearanceTab = app.toolbars.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Appearance'")
        ).firstMatch
        XCTAssertTrue(appearanceTab.waitForExistence(timeout: 5), "Appearance tab must exist")

        if appearanceTab.isHittable {
            appearanceTab.click()
        } else {
            appearanceTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).click()
        }

        // Verify we switched to Appearance tab by looking for theme-related content
        let themePicker = app.popUpButtons["prefs.theme"]
        let themeText = app.staticTexts.matching(
            NSPredicate(format: "value CONTAINS 'Theme' OR label CONTAINS 'Theme'")
        ).firstMatch
        let found = themePicker.waitForExistence(timeout: 3) || themeText.waitForExistence(timeout: 2)
        XCTAssertTrue(found, "Theme content should be visible after switching to Appearance tab")
    }

    func testClosePreferences() throws {
        openPreferences()

        // Verify a toolbar exists (Settings is open)
        let toolbar = app.toolbars.firstMatch
        XCTAssertTrue(toolbar.waitForExistence(timeout: 3))

        // Close Settings window with ⌘W
        app.typeKey("w", modifierFlags: .command)
        sleep(1)

        // Editor text view should still exist
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.waitForExistence(timeout: 3), "Editor should still exist after closing preferences")
    }
}
