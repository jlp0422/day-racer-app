import XCTest

final class DayRacerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the tab bar exists with expected tabs
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertTrue(app.tabBars.buttons["Leaderboard"].exists)
        XCTAssertTrue(app.tabBars.buttons["Friends"].exists)
        XCTAssertTrue(app.tabBars.buttons["Profile"].exists)
    }
}
