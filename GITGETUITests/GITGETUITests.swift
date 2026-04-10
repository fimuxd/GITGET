import XCTest

final class GITGETUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testInitialLaunchShowsFriendsEmptyState() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Add Friend"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No friends yet"].exists)
        XCTAssertTrue(app.textFields["username-field"].exists)
        XCTAssertTrue(app.textFields["server-origin-field"].exists)
        XCTAssertTrue(app.buttons["add-account-button"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

    @MainActor
    func testAddingAccountsSupportsProviderSwitchAndPreventsDuplicates() throws {
        let app = launchApp()

        let usernameField = app.textFields["username-field"]
        let serverField = app.textFields["server-origin-field"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))

        usernameField.tap()
        usernameField.typeText("octocat")
        app.buttons["add-account-button"].tap()

        XCTAssertTrue(app.staticTexts["Octocat"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["@octocat"].exists)

        usernameField.tap()
        usernameField.typeText("octocat")
        app.buttons["add-account-button"].tap()
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'Octocat'")).count, 1)

        app.segmentedControls["provider-picker"].buttons["GitLab"].tap()
        XCTAssertEqual(serverField.placeholderValue, "https://gitlab.example.com")

        usernameField.tap()
        usernameField.typeText("haru")
        serverField.tap()
        serverField.typeText("gitlab.company.com")
        app.buttons["add-account-button"].tap()

        XCTAssertTrue(app.staticTexts["Haru"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["@haru"].exists)
    }

    @MainActor
    func testLoadingFriendShowsSpinnerAndRefreshes() throws {
        let app = launchApp(scenario: "loadingFriend")

        let loadingUsername = app.descendants(matching: .any)["profile-username-github-loading-friend"]
        XCTAssertTrue(waitForElementToAppear(loadingUsername, in: app))
        XCTAssertTrue(app.staticTexts["Loading profile"].waitForExistence(timeout: 5))

        app.buttons["friends-refresh-button"].tap()
        XCTAssertTrue(waitForElementToAppear(loadingUsername, in: app))
        XCTAssertTrue(app.staticTexts["Loading profile"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFriendErrorStatesFlow() throws {
        let app = launchApp(scenario: "friendStates")

        let errorUsername = app.descendants(matching: .any)["profile-username-github-error-friend"]
        let graphErrorUsername = app.descendants(matching: .any)["profile-username-github-graph-error-friend"]
        XCTAssertTrue(waitForElementToAppear(errorUsername, in: app))
        XCTAssertTrue(waitForElementToAppear(graphErrorUsername, in: app))
        XCTAssertTrue(app.staticTexts["Account not found or currently unavailable."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Could not load contribution graph."].waitForExistence(timeout: 5))

        app.buttons["friends-refresh-button"].tap()
        XCTAssertTrue(waitForElementToAppear(errorUsername, in: app))
        XCTAssertTrue(waitForElementToAppear(graphErrorUsername, in: app))
        XCTAssertTrue(app.staticTexts["Account not found or currently unavailable."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Could not load contribution graph."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testGreenFriendDeleteFlow() throws {
        let app = launchApp(scenario: "greenFriend")

        let deleteButton = app.buttons["profile-delete-github-green-friend"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))

        deleteButton.tap()

        XCTAssertFalse(deleteButton.waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["No friends yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsThemeTutorialAndRoadmapFlow() throws {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.staticTexts["Theme"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Graph Theme"].exists)
        XCTAssertTrue(app.staticTexts["Widget configuration is still GitHub-only."].exists)
        XCTAssertTrue(app.staticTexts["GitLab support is available in the app list view first."].exists)

        app.buttons["how-to-use-button"].tap()

        XCTAssertTrue(app.otherElements["tutorial-sheet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Step 01"].exists)
        app.swipeUp()
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Step 04"].exists)

        app.buttons["tutorial-close-button"].tap()
        XCTAssertFalse(app.otherElements["tutorial-sheet"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testAboutPreviewFlows() throws {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()
        app.buttons["about-button"].tap()

        let aboutRateAction = app.buttons["about-rate-button"]
        let aboutSupportAction = app.buttons["about-support-button"]
        XCTAssertTrue(app.buttons["about-close-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(aboutRateAction.waitForExistence(timeout: 5))
        XCTAssertTrue(aboutSupportAction.waitForExistence(timeout: 5))

        aboutRateAction.tap()
        XCTAssertTrue(app.staticTexts["Review Request"].waitForExistence(timeout: 5))
        app.buttons["preview-sheet-close-button"].tap()

        aboutSupportAction.tap()
        XCTAssertTrue(app.staticTexts["Mail Composer"].waitForExistence(timeout: 5))
        app.buttons["preview-sheet-close-button"].tap()

        app.buttons["about-github-button"].tap()
        XCTAssertTrue(app.staticTexts["GitHub"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["https://github.com/fimuxd"].exists)
        app.buttons["preview-sheet-close-button"].tap()
    }

    @discardableResult
    private func launchApp(scenario: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        if let scenario {
            app.launchEnvironment["UITEST_SCENARIO"] = scenario
        }
        app.launch()
        return app
    }

    private func addAccount(username: String, app: XCUIApplication) {
        let usernameField = app.textFields["username-field"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))
        usernameField.tap()
        usernameField.typeText(username)
        app.buttons["add-account-button"].tap()
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
    }

    private func waitForElementToAppear(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        if element.waitForExistence(timeout: 2) {
            return true
        }

        for _ in 0 ..< 6 {
            app.swipeUp()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        for _ in 0 ..< 6 {
            app.swipeDown()
            if element.waitForExistence(timeout: 1) {
                return true
            }
        }

        return false
    }

}
