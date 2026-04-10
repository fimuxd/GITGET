import XCTest

final class SettingFlowUITests: GITGETUITestCase {
    func testFriendsTabShowsEmptyState() {
        let app = launchApp()

        XCTAssertTrue(app.textFields["friends.usernameField"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["friends.addButton"].exists)
        XCTAssertTrue(app.staticTexts["No friends yet"].waitForExistence(timeout: 5))
    }

    func testPopulatedStateShowsProfileCard() {
        let app = launchApp(state: "populated")

        XCTAssertTrue(app.staticTexts["The Octocat"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["@octocat"].exists)
        XCTAssertTrue(app.staticTexts["GitHub contribution test fixture"].exists)
    }

    func testSettingsTabShowsThemeAndGuide() {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.buttons["settings.howToUseButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.aboutButton"].exists)
        XCTAssertTrue(app.staticTexts["Graph Theme"].exists)
    }

    func testTutorialSheetFlow() {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settings.howToUseButton"].waitForExistence(timeout: 5))
        app.buttons["settings.howToUseButton"].tap()

        XCTAssertTrue(app.buttons["tutorial.closeButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Step 01"].exists)

        let scrollView = app.scrollViews["tutorial.scrollView"]
        XCTAssertTrue(scrollView.exists)
        scrollView.swipeUp()
        scrollView.swipeUp()

        XCTAssertTrue(app.staticTexts["Step 04"].waitForExistence(timeout: 5))

        app.buttons["tutorial.closeButton"].tap()
        XCTAssertFalse(app.buttons["tutorial.closeButton"].waitForExistence(timeout: 1))
    }

    func testAboutSheetShowsPrimaryActions() {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settings.aboutButton"].waitForExistence(timeout: 5))
        app.buttons["settings.aboutButton"].tap()

        XCTAssertTrue(app.buttons["about.rateButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["about.supportButton"].exists)
        XCTAssertTrue(app.buttons["about.githubButton"].exists)
        XCTAssertTrue(app.buttons["about.linkedinButton"].exists)
        XCTAssertTrue(app.buttons["about.instagramButton"].exists)
    }

    func testAboutActionsPresentUITestStubs() {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settings.aboutButton"].waitForExistence(timeout: 5))
        app.buttons["settings.aboutButton"].tap()
        XCTAssertTrue(app.buttons["about.rateButton"].waitForExistence(timeout: 5))

        app.buttons["about.rateButton"].tap()
        XCTAssertTrue(app.staticTexts["Review Prompt"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        app.buttons["about.supportButton"].tap()
        XCTAssertTrue(app.staticTexts["Mail Composer"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        app.buttons["about.githubButton"].tap()
        XCTAssertTrue(app.staticTexts["GitHub"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        app.buttons["about.linkedinButton"].tap()
        XCTAssertTrue(app.staticTexts["LinkedIn"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()

        app.buttons["about.instagramButton"].tap()
        XCTAssertTrue(app.staticTexts["Instagram"].waitForExistence(timeout: 5))
    }
}
