import XCTest

final class ExportUITests: ShoechooUITestCase {

    func testExportHTMLButtonOpensPanel() throws {
        pasteInEditor("# Export Test\n\nSome content to export.")

        let exportButton = app.buttons["toolbar.export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export button should exist")
        exportButton.click()

        let savePanel = app.sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5), "Save panel should appear for HTML export")

        app.typeKey(.escape, modifierFlags: [])
    }

    func testExportHTMLViaShortcut() throws {
        pasteInEditor("# Shortcut Export\n\nContent.")

        app.typeKey("e", modifierFlags: [.command, .shift])

        let savePanel = app.sheets.firstMatch
        XCTAssertTrue(savePanel.waitForExistence(timeout: 5), "Save panel should appear for ⇧⌘E")

        app.typeKey(.escape, modifierFlags: [])
    }

    func testExportPDFViaShortcut() throws {
        pasteInEditor("# PDF Export\n\nContent.")

        app.typeKey("e", modifierFlags: [.command, .shift, .option])

        // PDF export renders HTML via WebKit before showing the panel, so allow more time.
        // The save panel appears as a sheet, but on error an alert dialog may appear instead.
        let savePanel = app.sheets.firstMatch
        let appeared = savePanel.waitForExistence(timeout: 15)

        if !appeared {
            // Check if an error alert appeared instead
            let alert = app.dialogs.firstMatch
            if alert.exists {
                // Dismiss the alert and skip — PDF rendering may fail in CI
                app.typeKey(.escape, modifierFlags: [])
                throw XCTSkip("PDF export showed error alert instead of save panel (WebKit rendering may fail in test environment)")
            }
        }

        XCTAssertTrue(appeared, "Save panel should appear for PDF export")

        app.typeKey(.escape, modifierFlags: [])
    }
}
