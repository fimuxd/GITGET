import XCTest

class GITGETUITestCase: XCTestCase {
    enum InterfaceStyle {
        case system
        case dark
    }

    var app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.terminate()
    }

    @discardableResult
    func launchApp(
        state: String = "initial",
        preserveSelection: Bool = false,
        preserveTeamStore: Bool = false,
        interfaceStyle: InterfaceStyle = .system
    ) -> XCUIApplication {
        if app.state != .notRunning {
            app.terminate()
        }

        app = XCUIApplication()
        app.launchArguments = ["-ApplePersistenceIgnoreState", "YES"]

        if interfaceStyle == .dark {
            app.launchArguments += ["-uiuserinterfacestyle", "dark"]
        }

        app.launchEnvironment["GITGET_UI_TEST_MODE"] = "1"
        app.launchEnvironment["GITGET_UI_TEST_STATE"] = state
        app.launchEnvironment["GITGET_UI_TEST_PRESERVE_SELECTION"] = preserveSelection ? "1" : "0"
        app.launchEnvironment["GITGET_UI_TEST_PRESERVE_TEAM_STORE"] = preserveTeamStore ? "1" : "0"
        app.launch()
        XCTAssertTrue(waitForFriendsScreen(), "Friends screen did not finish loading for state \(state)")
        return app
    }

    @discardableResult
    func waitForFriendsScreen(timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if app.staticTexts["friends.selectedTeamName"].exists {
                return true
            }

            if app.staticTexts["friends.noTeamsTitle"].exists {
                return true
            }

            if app.textFields["friends.usernameField"].exists {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        return false
    }

    func scrollToFriendsElement(_ element: XCUIElement, maxSwipes: Int = 8) {
        if element.exists && element.isHittable {
            return
        }

        let scrollContainer = app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch
        guard scrollContainer.exists else {
            return
        }

        var attemptedSwipes = 0
        while attemptedSwipes < maxSwipes {
            if element.exists && element.isHittable {
                return
            }

            scrollContainer.swipeUp()
            attemptedSwipes += 1
        }
    }

    func scrollDownToFriendsElement(_ element: XCUIElement, maxSwipes: Int = 8) {
        if element.exists && element.isHittable {
            return
        }

        let scrollContainer = app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch
        guard scrollContainer.exists else {
            return
        }

        var attemptedSwipes = 0
        while attemptedSwipes < maxSwipes {
            if element.exists && element.isHittable {
                return
            }

            scrollContainer.swipeDown()
            attemptedSwipes += 1
        }
    }

    func comparisonMetricButton(_ title: String) -> XCUIElement {
        app.segmentedControls["friends.comparison.metricPicker"].buttons[title]
    }

    func assertSelectedTeamMessage(_ expectedMessage: String, timeout: TimeInterval = 5) {
        let selectedTeamMessage = app.staticTexts["friends.selectedTeamMessage"]
        XCTAssertTrue(selectedTeamMessage.waitForExistence(timeout: timeout))
        XCTAssertEqual(selectedTeamMessage.label, expectedMessage)
    }

    var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }
}
