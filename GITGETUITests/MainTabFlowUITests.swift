import XCTest

final class MainTabFlowUITests: GITGETUITestCase {
    func testFriendsTabShowsEmptyState() {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["friends.noTeamsTitle"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Manage"].tap()

        XCTAssertTrue(app.otherElements["manage.teamsCard"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["friends.usernameField"].exists)
        XCTAssertTrue(app.buttons["friends.addButton"].exists)
    }

    func testFriendsTabTeamNavigation() {
        let app = launchApp(state: "team_empty")

        XCTAssertTrue(app.buttons["friends.teamButton.system.all-friends"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["friends.teamButton.fixture.team.empty"].exists)

        app.buttons["friends.teamButton.system.all-friends"].tap()

        let selectedTeamName = app.staticTexts["friends.selectedTeamName"]
        XCTAssertTrue(selectedTeamName.waitForExistence(timeout: 5))
        XCTAssertEqual(selectedTeamName.label, "All Friends")

        app.terminate()

        let relaunchedApp = launchApp(state: "team_empty", preserveSelection: true)
        let relaunchedSelectedTeamName = relaunchedApp.staticTexts["friends.selectedTeamName"]

        XCTAssertTrue(relaunchedSelectedTeamName.waitForExistence(timeout: 5))
        XCTAssertEqual(relaunchedSelectedTeamName.label, "All Friends")
    }

    func testPopulatedStateShowsProfileCard() {
        let app = launchApp(state: "populated")
        let memberTeamsButton = app.buttons["friends.memberTeamsButton.github:public:octocat"]

        let selectedTeamName = app.staticTexts["friends.selectedTeamName"]
        XCTAssertTrue(selectedTeamName.waitForExistence(timeout: 5))
        XCTAssertEqual(selectedTeamName.label, "All Friends")
        assertSelectedTeamMessage("Showing 1 saved member with team comparison ranked by today.")
        XCTAssertTrue(app.buttons["friends.refreshButton"].exists)
        scrollToFriendsElement(memberTeamsButton)
        XCTAssertTrue(memberTeamsButton.waitForExistence(timeout: 5))
    }

    func testComparisonMetricSwitching() throws {
        let app = launchApp(state: "team_ranked")
        let comparisonCard = app.otherElements["friends.comparison.card"]
        let last7ActiveDaysButton = comparisonMetricButton("7 Active Days")
        let yearButton = comparisonMetricButton("Year")

        scrollToFriendsElement(comparisonCard)
        XCTAssertTrue(comparisonCard.waitForExistence(timeout: 5))
        XCTAssertFalse(last7ActiveDaysButton.isSelected)
        XCTAssertFalse(yearButton.isSelected)

        XCTAssertTrue(last7ActiveDaysButton.waitForExistence(timeout: 5))
        last7ActiveDaysButton.tap()
        XCTAssertTrue(last7ActiveDaysButton.isSelected)

        scrollToFriendsElement(comparisonCard)
        XCTAssertTrue(yearButton.waitForExistence(timeout: 5))
        yearButton.tap()
        XCTAssertTrue(yearButton.isSelected)
    }

    func testInsightCardsRenderRankedState() throws {
        let app = launchApp(state: "team_ranked")
        let insightCard = app.otherElements["friends.insights.card"]

        scrollToFriendsElement(insightCard)
        XCTAssertTrue(insightCard.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["friends.insights.headline.hottestToday"].label, "Anna")
        XCTAssertEqual(app.staticTexts["friends.insights.detail.hottestToday"].label, "7 contributions today")
        XCTAssertEqual(app.staticTexts["friends.insights.headline.streakLeader"].label, "Anna")
        XCTAssertEqual(app.staticTexts["friends.insights.detail.biggest7DayMover"].label, "+28 vs previous 7 days")
        XCTAssertEqual(app.staticTexts["friends.insights.headline.mostActiveThisYear"].label, "Anna")
    }

    func testInsightCardsRenderFallbackState() throws {
        let app = launchApp(state: "team_empty")
        let insightCard = app.otherElements["friends.insights.card"]

        scrollToFriendsElement(insightCard)
        XCTAssertTrue(insightCard.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["friends.insights.headline.hottestToday"].label, "Not enough data yet")
        XCTAssertEqual(app.staticTexts["friends.insights.detail.hottestToday"].label, "No team member has a contribution recorded for today.")
        XCTAssertEqual(app.staticTexts["friends.insights.detail.streakLeader"].label, "A contribution graph is required to calculate streaks.")
        XCTAssertEqual(app.staticTexts["friends.insights.detail.biggest7DayMover"].label, "Not enough recent contribution activity to compare two 7-day windows.")
        XCTAssertEqual(app.staticTexts["friends.insights.detail.mostActiveThisYear"].label, "No team member has enough yearly contribution history yet.")

        let emptyTeamTitle = app.staticTexts["friends.teamEmptyTitle"]
        scrollToFriendsElement(emptyTeamTitle)
        XCTAssertTrue(emptyTeamTitle.waitForExistence(timeout: 5))
    }

    func testLegacyMigrationFixtureShowsAllFriendsByDefault() {
        let app = launchApp(state: "legacy_migration")
        let octocatTeamsButton = app.buttons["friends.memberTeamsButton.github:public:octocat"]
        let haruTeamsButton = app.buttons["friends.memberTeamsButton.gitlab:https://gitlab.example.com:haru"]

        XCTAssertTrue(app.staticTexts["friends.selectedTeamName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["friends.selectedTeamName"].label, "All Friends")
        XCTAssertTrue(app.buttons["friends.teamButton.system.all-friends"].exists)
        scrollToFriendsElement(octocatTeamsButton)
        XCTAssertTrue(octocatTeamsButton.waitForExistence(timeout: 5))
        scrollToFriendsElement(haruTeamsButton)
        XCTAssertTrue(haruTeamsButton.waitForExistence(timeout: 5))
    }

    func testPartialFailureStateShowsComparisonAndUnavailableMembersSeparately() {
        let app = launchApp(state: "team_partial_failure")
        let comparisonCard = app.otherElements["friends.comparison.card"]
        let unavailableCard = app.otherElements["friends.unavailable.card"]

        scrollToFriendsElement(comparisonCard)
        XCTAssertTrue(comparisonCard.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["friends.comparison.row.github:public:alex"].exists)
        XCTAssertTrue(app.otherElements["friends.comparison.row.github:https://github.example.com:casey"].exists)
        XCTAssertFalse(app.otherElements["friends.comparison.row.gitlab:public:bella"].exists)

        scrollToFriendsElement(unavailableCard)
        XCTAssertTrue(unavailableCard.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["friends.unavailable.row.gitlab:public:bella"].exists)
        XCTAssertTrue(app.otherElements["friends.unavailable.row.gitlab:https://gitlab.example.com:drew"].exists)
    }

    func testSettingsTabShowsThemeAndGuide() {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.buttons["settings.howToUseButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.aboutButton"].exists)
        XCTAssertTrue(app.staticTexts["Graph Theme"].exists)
    }

    func testSettingsTabShowsThemeAndGuideInDarkMode() {
        let app = launchApp(interfaceStyle: .dark)

        app.tabBars.buttons["Settings"].tap()

        XCTAssertTrue(app.buttons["settings.howToUseButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.aboutButton"].exists)
        XCTAssertTrue(app.staticTexts["Graph Theme"].exists)
    }

    func testWidgetSetupGuideSheetFlow() {
        let app = launchApp()

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["settings.howToUseButton"].waitForExistence(timeout: 5))
        app.buttons["settings.howToUseButton"].tap()

        XCTAssertTrue(app.buttons["widgetSetupGuide.closeButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Step 01"].exists)

        let scrollView = app.scrollViews["widgetSetupGuide.scrollView"]
        XCTAssertTrue(scrollView.exists)
        scrollView.swipeUp()
        scrollView.swipeUp()

        XCTAssertTrue(app.staticTexts["Step 04"].waitForExistence(timeout: 5))

        app.buttons["widgetSetupGuide.closeButton"].tap()
        XCTAssertFalse(app.buttons["widgetSetupGuide.closeButton"].waitForExistence(timeout: 1))
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
        XCTAssertTrue(app.buttons["about.rateButton"].waitForExistence(timeout: 5))

        app.buttons["about.supportButton"].tap()
        XCTAssertTrue(app.staticTexts["Mail Composer"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["about.rateButton"].waitForExistence(timeout: 5))

        app.buttons["about.githubButton"].tap()
        XCTAssertTrue(app.staticTexts["GitHub"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["about.rateButton"].waitForExistence(timeout: 5))

        app.buttons["about.linkedinButton"].tap()
        XCTAssertTrue(app.staticTexts["LinkedIn"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["about.rateButton"].waitForExistence(timeout: 5))

        app.buttons["about.instagramButton"].tap()
        XCTAssertTrue(app.staticTexts["Instagram"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["about.rateButton"].waitForExistence(timeout: 5))
    }

    func testTeamManagementFlow() {
        let app = launchApp(state: "team_ranked")

        let selectedTeamName = app.staticTexts["friends.selectedTeamName"]
        scrollDownToFriendsElement(app.otherElements["friends.selectedTeamCard"])
        XCTAssertTrue(selectedTeamName.waitForExistence(timeout: 5))
        XCTAssertEqual(selectedTeamName.label, "iOS Team")

        app.buttons["friends.manageTeamsButton"].tap()
        let createField = app.textFields["friends.teamManager.createField"]
        XCTAssertTrue(createField.waitForExistence(timeout: 5))
        createField.tap()
        createField.typeText("QA Team")
        app.buttons["friends.teamManager.createButton"].tap()
        let createdTeamNameLabel = app.staticTexts.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label == %@", "friends.teamManager.name.", "QA Team")
        ).firstMatch
        XCTAssertTrue(createdTeamNameLabel.waitForExistence(timeout: 5))
        let createdTeamID = createdTeamNameLabel.identifier.replacingOccurrences(of: "friends.teamManager.name.", with: "")

        let moveDownRankedButton = app.buttons["friends.teamManager.moveDown.fixture.team.ranked"]
        XCTAssertTrue(moveDownRankedButton.waitForExistence(timeout: 5))
        moveDownRankedButton.tap()
        XCTAssertEqual(app.staticTexts["friends.teamManager.position.fixture.team.ranked"].label, "Position 2")
        let teamManagerDoneButton = app.buttons["friends.teamManager.doneButton"]
        XCTAssertTrue(teamManagerDoneButton.waitUntilHittable(timeout: 5))
        app.buttons["friends.teamManager.doneButton"].tap()
        XCTAssertTrue(app.buttons["friends.teamManager.moveDown.fixture.team.ranked"].waitForNonExistence(timeout: 5))

        scrollDownToFriendsElement(app.otherElements["friends.selectedTeamCard"])
        XCTAssertEqual(selectedTeamName.label, "QA Team")

        let selectedTeamRenameButton = app.buttons["friends.selectedTeamRenameButton"]
        XCTAssertTrue(selectedTeamRenameButton.waitForExistence(timeout: 5))
        selectedTeamRenameButton.tap()
        let renameField = app.textFields["friends.teamRename.field.\(createdTeamID)"]
        XCTAssertTrue(renameField.waitForExistence(timeout: 5))
        renameField.clearAndEnterText("iOS Platform")
        app.buttons["friends.teamRename.save.\(createdTeamID)"].tap()
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 5))
        XCTAssertEqual(selectedTeamName.label, "iOS Platform")

        app.buttons["friends.teamButton.system.all-friends"].tap()
        XCTAssertEqual(selectedTeamName.label, "All Friends")
        XCTAssertTrue(app.staticTexts["friends.selectedTeamProtectedLabel"].exists)
        XCTAssertFalse(app.buttons["friends.selectedTeamDeleteButton"].exists)

        let annaTeamsButton = app.buttons["friends.memberTeamsButton.github:public:anna"]
        scrollToFriendsElement(annaTeamsButton)
        annaTeamsButton.tap()
        let platformToggle = app.switches["friends.memberTeamToggle.github:public:anna.\(createdTeamID)"]
        XCTAssertTrue(platformToggle.waitForExistence(timeout: 5))
        if platformToggle.value as? String != "1" {
            platformToggle.tap()
        }
        app.buttons["friends.memberTeamSheet.done.github:public:anna"].tap()
        XCTAssertTrue(platformToggle.waitForNonExistence(timeout: 5))

        scrollDownToFriendsElement(app.otherElements["friends.selectedTeamCard"])
        let renamedTeamButton = app.buttons["friends.teamButton.\(createdTeamID)"]
        XCTAssertTrue(renamedTeamButton.waitUntilHittable(timeout: 5))
        renamedTeamButton.tap()
        XCTAssertEqual(selectedTeamName.label, "iOS Platform")

        app.buttons["friends.selectedTeamManageButton"].tap()
        let createdTeamDeleteButton = app.buttons["friends.teamManager.delete.\(createdTeamID)"]
        XCTAssertTrue(createdTeamDeleteButton.waitForExistence(timeout: 5))
        createdTeamDeleteButton.tap()
        let deleteConfirmationButton = app.buttons["friends.teamDelete.confirm.\(createdTeamID)"].firstMatch
        XCTAssertTrue(deleteConfirmationButton.waitForExistence(timeout: 5))
        deleteConfirmationButton.tap()

        XCTAssertEqual(selectedTeamName.label, "All Friends")
        let annaAllFriendsTeamsButton = app.buttons["friends.memberTeamsButton.github:public:anna"]
        scrollToFriendsElement(annaAllFriendsTeamsButton)
        XCTAssertTrue(annaAllFriendsTeamsButton.waitForExistence(timeout: 5))

        app.terminate()

        let relaunchedApp = launchApp(state: "team_ranked", preserveTeamStore: true)
        let relaunchedSelectedTeamName = relaunchedApp.staticTexts["friends.selectedTeamName"]
        XCTAssertTrue(relaunchedSelectedTeamName.waitForExistence(timeout: 5))
        XCTAssertEqual(relaunchedSelectedTeamName.label, "All Friends")
        XCTAssertTrue(relaunchedApp.staticTexts["friends.selectedTeamProtectedLabel"].exists)
        XCTAssertFalse(relaunchedApp.staticTexts["iOS Platform"].exists)
    }
}

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()

        guard let currentValue = value as? String else {
            typeText(text)
            return
        }

        let deleteText = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteText + text)
    }

    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}

private extension XCUIElement {
    func waitUntilHittable(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
