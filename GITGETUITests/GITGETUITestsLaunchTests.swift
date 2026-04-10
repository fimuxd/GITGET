import XCTest

final class GITGETUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Add Friend"].waitForExistence(timeout: 5))
    }
}
