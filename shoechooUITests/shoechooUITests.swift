import XCTest

final class ShoechooUITests: XCTestCase {

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window after launch")
    }
}
