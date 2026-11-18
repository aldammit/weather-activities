import XCTest

/// Launches the app and checks the search screen comes up. Makes no network requests.
final class LaunchUITests: XCTestCase {
    @MainActor
    func testLaunchShowsTheSearchScreen() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.textFields["Search for a city"].waitForExistence(timeout: 10))
        let header = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Find activities")).firstMatch
        XCTAssertTrue(header.exists)
    }
}
