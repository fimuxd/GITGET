import XCTest

final class WidgetSmokeUITests: GITGETUITestCase {
    func testSpringBoardWidgetSmokeFlow() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["ENABLE_WIDGET_SPRINGBOARD_UI_TESTS"] == "1",
            "SpringBoard widget automation is opt-in because labels and menus vary across iOS versions and locales."
        )

        _ = launchApp(state: "populated")
        XCUIDevice.shared.press(.home)

        let springboard = springboard
        XCTAssertTrue(springboard.waitForExistence(timeout: 5))

        let gitGetIcon = springboard.icons["GitGet"]
        XCTAssertTrue(gitGetIcon.waitForExistence(timeout: 5))

        gitGetIcon.press(forDuration: 1.5)

        let editHomeScreenButton = springboard.buttons["Edit Home Screen"]
        XCTAssertTrue(editHomeScreenButton.waitForExistence(timeout: 5))
    }
}
