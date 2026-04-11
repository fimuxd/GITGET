//
//  GITGETTests.swift
//  GITGETTests
//
//  Created by Bo-Young PARK on 12/27/20.
//

import XCTest
@testable import GITGET

class GITGETTests: XCTestCase {

    @MainActor
    func testSavedContributionAccountsMigratesIntoAllFriendsTeamStore() throws {
        let userDefaults = makeTestUserDefaults(function: #function)
        let legacyAccounts = [
            ContributionAccount(provider: .github, username: "  octocat  "),
            ContributionAccount(provider: .github, username: "octocat", serverOrigin: "https://github.com"),
            ContributionAccount(provider: .gitlab, username: "haru", serverOrigin: "gitlab.example.com/team"),
            ContributionAccount(provider: .gitlab, username: "haru", serverOrigin: "https://gitlab.example.com")
        ]
        userDefaults.set(try JSONEncoder().encode(legacyAccounts), forKey: ContributionViewModel.accountsKey)

        let viewModel = ContributionViewModel(userDefaults: userDefaults, shouldRefreshOnLoad: false)
        let persistedStore = try XCTUnwrap(loadTeamStore(from: userDefaults))

        XCTAssertEqual(viewModel.profiles.map(\.id), [
            "github:public:octocat",
            "gitlab:https://gitlab.example.com:haru"
        ])
        XCTAssertEqual(persistedStore.version, ContributionTeamStore.currentVersion)
        XCTAssertEqual(persistedStore.teams, [ContributionTeam.allFriends(accountIDs: persistedStore.accounts.map(\.id))])
        XCTAssertEqual(persistedStore.selectedTeamID, ContributionTeam.allFriendsID)
        XCTAssertEqual(persistedStore.selectedAccounts.map(\.id), viewModel.profiles.map(\.id))
    }

    @MainActor
    func testLegacyUsernameMigratesIntoAllFriendsTeamStore() throws {
        let userDefaults = makeTestUserDefaults(function: #function)
        userDefaults.set("  octocat  ", forKey: "username")

        let viewModel = ContributionViewModel(userDefaults: userDefaults, shouldRefreshOnLoad: false)
        let persistedStore = try XCTUnwrap(loadTeamStore(from: userDefaults))

        XCTAssertEqual(viewModel.profiles.map(\.account), [ContributionAccount(provider: .github, username: "octocat")])
        XCTAssertEqual(persistedStore.teams, [ContributionTeam.allFriends(accountIDs: ["github:public:octocat"])])
        XCTAssertEqual(persistedStore.selectedTeamID, ContributionTeam.allFriendsID)
    }

    @MainActor
    func testDuplicateUsernameStaysDistinctAcrossProviderAndOrigin() throws {
        let userDefaults = makeTestUserDefaults(function: #function)
        let legacyAccounts = [
            ContributionAccount(provider: .github, username: "octocat"),
            ContributionAccount(provider: .gitlab, username: "octocat"),
            ContributionAccount(provider: .github, username: "octocat", serverOrigin: "github.example.com")
        ]
        userDefaults.set(try JSONEncoder().encode(legacyAccounts), forKey: ContributionViewModel.accountsKey)

        let viewModel = ContributionViewModel(userDefaults: userDefaults, shouldRefreshOnLoad: false)
        let persistedStore = try XCTUnwrap(loadTeamStore(from: userDefaults))

        XCTAssertEqual(viewModel.profiles.map(\.id), [
            "github:public:octocat",
            "gitlab:public:octocat",
            "github:https://github.example.com:octocat"
        ])
        XCTAssertEqual(Set(persistedStore.accounts.map(\.id)).count, 3)
    }

    @MainActor
    func testFreshInstallDoesNotWriteTeamStore() {
        let userDefaults = makeTestUserDefaults(function: #function)

        let viewModel = ContributionViewModel(userDefaults: userDefaults, shouldRefreshOnLoad: false)

        XCTAssertTrue(viewModel.profiles.isEmpty)
        XCTAssertNil(userDefaults.data(forKey: ContributionViewModel.teamStoreKey))
        XCTAssertNil(userDefaults.data(forKey: ContributionViewModel.accountsKey))
        XCTAssertNil(userDefaults.string(forKey: "username"))
    }

    func testTeamStoreCrudKeepsAllFriendsProtectedAndFirst() {
        let accounts = [
            ContributionAccount(provider: .github, username: "anna"),
            ContributionAccount(provider: .gitlab, username: "bora")
        ]
        let designTeam = ContributionTeam(id: "fixture.team.design", name: "Design", accountIDs: [accounts[0].id])
        let iosTeam = ContributionTeam(id: "fixture.team.ios", name: "iOS", accountIDs: [accounts[1].id])

        let store = ContributionTeamStore(
            version: ContributionTeamStore.currentVersion,
            selectedTeamID: designTeam.id,
            teams: [ContributionTeam.allFriends(accountIDs: accounts.map(\.id)), designTeam, iosTeam],
            accounts: accounts
        )
        let createdStore = store.creatingTeam(named: "QA")
        let createdTeam = try? XCTUnwrap(createdStore.selectedTeam)
        XCTAssertNotNil(createdTeam)

        guard let createdTeam else { return }

        let assignedStore = createdStore.settingMembership(forAccountID: accounts[0].id, inTeamID: createdTeam.id, isIncluded: true)
        let reorderedStore = assignedStore.reorderingCustomTeams(from: 2, to: 0)
        let renamedStore = reorderedStore.renamingTeam(withID: createdTeam.id, to: "Platform")
        let deletedStore = renamedStore.deletingTeam(withID: createdTeam.id)
        let protectedStore = deletedStore.deletingTeam(withID: ContributionTeam.allFriendsID)

        XCTAssertEqual(renamedStore.teams.first?.id, ContributionTeam.allFriendsID)
        XCTAssertEqual(renamedStore.customTeams.map(\.name), ["Platform", "Design", "iOS"])
        XCTAssertTrue(renamedStore.teams.first?.accountIDs.contains(accounts[0].id) == true)
        XCTAssertFalse(deletedStore.teams.contains(where: { $0.id == createdTeam.id }))
        XCTAssertEqual(protectedStore, deletedStore)
    }

    func testTeamStoreNormalizationRebuildsAllFriendsAndFallsBackSelection() {
        let accounts = [
            ContributionAccount(provider: .github, username: "  anna  "),
            ContributionAccount(provider: .gitlab, username: "bora", serverOrigin: "gitlab.example.com/team"),
            ContributionAccount(provider: .github, username: "anna")
        ]
        let store = ContributionTeamStore(
            version: ContributionTeamStore.currentVersion,
            selectedTeamID: "fixture.team.missing",
            teams: [
                ContributionTeam(
                    id: "fixture.team.design",
                    name: "  Design  ",
                    accountIDs: [accounts[1].id, "missing.account", accounts[1].id, accounts[0].id]
                )
            ],
            accounts: accounts
        )

        let normalizedStore = store.normalized()

        XCTAssertEqual(normalizedStore.accounts.map(\.id), [
            "github:public:anna",
            "gitlab:https://gitlab.example.com:bora"
        ])
        XCTAssertEqual(normalizedStore.teams.map(\.id), [
            ContributionTeam.allFriendsID,
            "fixture.team.design"
        ])
        XCTAssertEqual(normalizedStore.teams.first, ContributionTeam.allFriends(accountIDs: normalizedStore.accounts.map(\.id)))
        XCTAssertEqual(normalizedStore.selectedTeamID, ContributionTeam.allFriendsID)
        XCTAssertEqual(normalizedStore.customTeams.first?.name, "Design")
        XCTAssertEqual(normalizedStore.customTeams.first?.accountIDs, [
            "gitlab:https://gitlab.example.com:bora",
            "github:public:anna"
        ])
    }

    func testContributionAccountDecodesLegacyPayloadWithoutServerOrigin() throws {
        let data = #"{"provider":"github","username":"octocat"}"#.data(using: .utf8)!

        let account = try JSONDecoder().decode(ContributionAccount.self, from: data)

        XCTAssertEqual(account.provider, .github)
        XCTAssertEqual(account.username, "octocat")
        XCTAssertNil(account.serverOrigin)
    }

    func testContributionAccountNormalizesUsernameAndServerOrigin() {
        let account = ContributionAccount(
            provider: .gitlab,
            username: "  haru  ",
            serverOrigin: "gitlab.example.com/gitlab?from=app#section"
        )

        XCTAssertEqual(account.username, "haru")
        XCTAssertEqual(account.serverOrigin, "https://gitlab.example.com")
    }

    func testGitHubEnterpriseServerOriginUsesWebOriginAndAPIV3() {
        XCTAssertEqual(
            ContributionProvider.github.webBaseURL(serverOrigin: "github.example.com/api/v3").absoluteString,
            "https://github.example.com"
        )
        XCTAssertEqual(
            ContributionProvider.github.apiBaseURL(serverOrigin: "github.example.com/api/v3").absoluteString,
            "https://github.example.com/api/v3"
        )
        XCTAssertEqual(
            ContributionProvider.github.apiBaseURL(serverOrigin: "https://github.com").absoluteString,
            "https://api.github.com"
        )
    }

    func testGitLabServerOriginUsesAPIV4() {
        XCTAssertEqual(
            ContributionProvider.gitlab.webBaseURL(serverOrigin: "https://gitlab.example.com/gitlab").absoluteString,
            "https://gitlab.example.com"
        )
        XCTAssertEqual(
            ContributionProvider.gitlab.apiBaseURL(serverOrigin: "https://gitlab.example.com/gitlab").absoluteString,
            "https://gitlab.example.com/api/v4"
        )
        XCTAssertEqual(
            ContributionProvider.gitlab.apiBaseURL(serverOrigin: "gitlab.com").absoluteString,
            "https://gitlab.com/api/v4"
        )
    }

    func testServerOriginNormalizationPrefersHTTPS() {
        XCTAssertEqual(
            ContributionProvider.github.webBaseURL(serverOrigin: "http://github.example.com/internal").absoluteString,
            "https://github.example.com"
        )
        XCTAssertEqual(
            ContributionProvider.gitlab.apiBaseURL(serverOrigin: "gitlab.example.com/team").absoluteString,
            "https://gitlab.example.com/api/v4"
        )
    }

    func testAccountAwareURLConstructionUsesCustomOrigins() {
        let githubAccount = ContributionAccount(
            provider: .github,
            username: "octocat",
            serverOrigin: "github.example.com"
        )
        let gitLabAccount = ContributionAccount(
            provider: .gitlab,
            username: "haru",
            serverOrigin: "https://gitlab.example.com/gitlab"
        )

        XCTAssertEqual(
            URL.userAPI(account: githubAccount).absoluteString,
            "https://github.example.com/api/v3/users"
        )
        XCTAssertEqual(
            URL.contributionsAPI(account: githubAccount).absoluteString,
            "https://github.example.com/users"
        )
        XCTAssertEqual(
            URL.userAPI(account: gitLabAccount).absoluteString,
            "https://gitlab.example.com/api/v4/users"
        )
        XCTAssertEqual(
            URL.contributionsAPI(account: gitLabAccount).absoluteString,
            "https://gitlab.example.com/users"
        )
    }

    func testParseContributionsFromGitHubFragment() throws {
        let html = """
        <table>
          <tbody>
            <tr>
              <td id="contribution-day-component-0-0" class="ContributionCalendar-day" data-date="2026-04-07" data-level="0"></td>
              <tool-tip for="contribution-day-component-0-0">No contributions on April 7th.</tool-tip>
              <td id="contribution-day-component-0-1" class="ContributionCalendar-day" data-date="2026-04-08" data-level="2"></td>
              <tool-tip for="contribution-day-component-0-1">12 contributions on April 8th.</tool-tip>
              <td id="contribution-day-component-0-2" class="ContributionCalendar-day" data-date="2026-04-09" data-level="4"></td>
              <tool-tip for="contribution-day-component-0-2">1 contribution on April 9th.</tool-tip>
            </tr>
          </tbody>
        </table>
        """

        let contributions = try ContributionAPI.parseContributions(from: html)

        XCTAssertEqual(contributions.count, 3)
        XCTAssertEqual(contributions.map(\.count), [0, 12, 1])
        XCTAssertEqual(contributions.map(\.level), [.zero, .two, .four])
        XCTAssertEqual(contributions.map { Contribution.string(from: $0.date) }, ["2026-04-07", "2026-04-08", "2026-04-09"])
    }

    func testComparisonMetricsUseMostRecentSevenActiveDaysAndCurrentYearOnly() {
        let contributions = [
            makeMetricsContribution(dayOffset: 0, count: 4),
            makeMetricsContribution(dayOffset: -1, count: 0),
            makeMetricsContribution(dayOffset: -2, count: 3),
            makeMetricsContribution(dayOffset: -3, count: 2),
            makeMetricsContribution(dayOffset: -4, count: 1),
            makeMetricsContribution(dayOffset: -5, count: 5),
            makeMetricsContribution(dayOffset: -6, count: 6),
            makeMetricsContribution(dayOffset: -7, count: 7),
            makeMetricsContribution(dayOffset: -8, count: 8),
            makeMetricsContribution(dayOffset: -400, count: 50)
        ]

        let metrics = ContributionComparisonMetrics(contributions: contributions)

        XCTAssertEqual(metrics.todayContributionCount, 4)
        XCTAssertEqual(metrics.last7ActiveDayContributionCount, 28)
        XCTAssertEqual(metrics.currentYearContributionCount, 36)
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    private func makeTestUserDefaults(function: StaticString) -> UserDefaults {
        let suiteName = "GITGETTests.\(function)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeMetricsContribution(dayOffset: Int, count: Int) -> Contribution {
        let date = Calendar.gitHubUTC.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        return Contribution(date: date, count: count, level: .zero)
    }

    @MainActor
    private func loadTeamStore(from userDefaults: UserDefaults) -> ContributionTeamStore? {
        guard let data = userDefaults.data(forKey: ContributionViewModel.teamStoreKey) else {
            return nil
        }

        return try? JSONDecoder().decode(ContributionTeamStore.self, from: data)
    }

}

final class ContributionViewModelTeamStateTests: XCTestCase {
    @MainActor
    func testAddingAccountUsesSelectedTeamAndAllFriendsMembership() throws {
        let userDefaults = makeTestUserDefaults(function: #function)
        let viewModel = ContributionViewModel(
            userDefaults: userDefaults,
            shouldRefreshOnLoad: false,
            uiTestEnvironment: [
                "GITGET_UI_TEST_MODE": "1",
                "GITGET_UI_TEST_STATE": "team_empty"
            ]
        )

        viewModel.createTeam(named: "Platform")
        let createdTeam = try XCTUnwrap(viewModel.selectedTeam)
        XCTAssertEqual(createdTeam.name, "Platform")

        viewModel.selectedProvider = .github
        viewModel.enteredUserName = "newfriend"
        viewModel.enteredServerOrigin = ""
        viewModel.addAccount()

        let persistedStore = try XCTUnwrap(loadTeamStore(from: userDefaults))
        let newAccountID = "github:public:newfriend"

        XCTAssertTrue(persistedStore.teams.first(where: { $0.id == ContributionTeam.allFriendsID })?.accountIDs.contains(newAccountID) == true)
        XCTAssertTrue(persistedStore.teams.first(where: { $0.id == createdTeam.id })?.accountIDs.contains(newAccountID) == true)
        XCTAssertEqual(persistedStore.selectedTeamID, createdTeam.id)
    }

    @MainActor
    func testRemovingSelectedTeamMembershipKeepsAccountInAllFriends() throws {
        let userDefaults = makeTestUserDefaults(function: #function)
        let viewModel = ContributionViewModel(
            userDefaults: userDefaults,
            shouldRefreshOnLoad: false,
            uiTestEnvironment: [
                "GITGET_UI_TEST_MODE": "1",
                "GITGET_UI_TEST_STATE": "team_ranked"
            ]
        )

        let removedProfile = try XCTUnwrap(viewModel.selectedTeamMembers.first?.profile)
        viewModel.removeProfileFromSelectedTeam(removedProfile)

        let persistedStore = try XCTUnwrap(loadTeamStore(from: userDefaults))

        XCTAssertFalse(persistedStore.teams.first(where: { $0.id == "fixture.team.ranked" })?.accountIDs.contains(removedProfile.id) == true)
        XCTAssertTrue(persistedStore.teams.first(where: { $0.id == ContributionTeam.allFriendsID })?.accountIDs.contains(removedProfile.id) == true)
    }

    @MainActor
    func testRefreshAllUsesAllPersistedAccountsNotJustSelectedTeamProjection() {
        let viewModel = makeFixtureViewModel(state: "team_empty", function: #function)
        var refreshedAccountIDs: [String] = []

        viewModel.refreshAll { account in
            refreshedAccountIDs.append(account.id)
        }

        XCTAssertTrue(viewModel.selectedTeamMembers.isEmpty)
        XCTAssertEqual(refreshedAccountIDs, [
            "github:public:octocat",
            "gitlab:public:haru"
        ])
    }

    @MainActor
    func testLoadSavedAccountsRefreshesPersistedAccountsWhenSelectedTeamIsEmpty() throws {
        let userDefaults = makeTestUserDefaults(function: #function)
        let accounts = [
            ContributionAccount(provider: .github, username: "octocat"),
            ContributionAccount(provider: .gitlab, username: "haru")
        ]
        let persistedStore = ContributionTeamStore(
            version: ContributionTeamStore.currentVersion,
            selectedTeamID: "fixture.team.empty",
            teams: [
                ContributionTeam.allFriends(accountIDs: accounts.map(\.id)),
                ContributionTeam(id: "fixture.team.empty", name: "Design Team", accountIDs: [])
            ],
            accounts: accounts
        ).normalized()
        userDefaults.set(try JSONEncoder().encode(persistedStore), forKey: ContributionViewModel.teamStoreKey)

        var refreshedAccountIDs: [String] = []
        let viewModel = ContributionViewModel(
            userDefaults: userDefaults,
            shouldRefreshOnLoad: true,
            refreshProfileHandler: { account in
                refreshedAccountIDs.append(account.id)
            }
        )

        XCTAssertEqual(viewModel.selectedTeamID, "fixture.team.empty")
        XCTAssertTrue(viewModel.profiles.isEmpty)
        XCTAssertEqual(refreshedAccountIDs, [
            "github:public:octocat",
            "gitlab:public:haru"
        ])
    }

    @MainActor
    func testLateRefreshCompletionDoesNotReinsertRemovedAccount() throws {
        let userDefaults = makeTestUserDefaults(function: #function)
        let viewModel = ContributionViewModel(
            userDefaults: userDefaults,
            shouldRefreshOnLoad: false,
            uiTestEnvironment: [
                "GITGET_UI_TEST_MODE": "1",
                "GITGET_UI_TEST_STATE": "team_ranked"
            ]
        )

        let removedProfile = try XCTUnwrap(viewModel.selectedTeamMembers.first?.profile)
        viewModel.removeProfile(removedProfile)

        XCTAssertNil(viewModel.profile(for: removedProfile.id))
        XCTAssertFalse(viewModel.teams.contains { $0.accountIDs.contains(removedProfile.id) })

        viewModel.apply(removedProfile)

        XCTAssertNil(viewModel.profile(for: removedProfile.id))
        XCTAssertFalse(viewModel.teams.contains { $0.accountIDs.contains(removedProfile.id) })

        let persistedStore = try XCTUnwrap(loadTeamStore(from: userDefaults))
        XCTAssertFalse(persistedStore.accounts.contains { $0.id == removedProfile.id })
        XCTAssertFalse(persistedStore.teams.contains { $0.accountIDs.contains(removedProfile.id) })
    }

    @MainActor
    func testTeamRankedFixtureProvidesDeterministicOrderedMetrics() throws {
        let viewModel = makeFixtureViewModel(state: "team_ranked", function: #function)
        let summary = try XCTUnwrap(viewModel.selectedTeamSummary)

        XCTAssertEqual(viewModel.selectedTeam?.id, "fixture.team.ranked")
        XCTAssertEqual(viewModel.selectedComparisonMetric, .today)
        XCTAssertEqual(viewModel.teams.map(\.id), [ContributionTeam.allFriendsID, "fixture.team.ranked"])
        XCTAssertEqual(viewModel.profiles.map(\.id), [
            "github:public:anna",
            "gitlab:https://gitlab.example.com:bora",
            "github:https://github.example.com:chris"
        ])
        XCTAssertEqual(summary.members.map(\.id), viewModel.profiles.map(\.id))
        XCTAssertEqual(summary.rankings.map(\.metric), ContributionComparisonMetric.allCases)
        XCTAssertEqual(summary.rankedMembers.map(\.id), [
            "github:public:anna",
            "gitlab:https://gitlab.example.com:bora",
            "github:https://github.example.com:chris"
        ])
        XCTAssertTrue(summary.unavailableMembers.isEmpty)
        XCTAssertEqual(summary.rankedMembers.map(\.metrics), [
            ContributionComparisonMetrics(todayContributionCount: 7, last7DayContributionCount: 28, currentYearContributionCount: 36),
            ContributionComparisonMetrics(todayContributionCount: 5, last7DayContributionCount: 20, currentYearContributionCount: 24),
            ContributionComparisonMetrics(todayContributionCount: 2, last7DayContributionCount: 8, currentYearContributionCount: 8)
        ])
        XCTAssertEqual(summary.aggregateMetrics, ContributionComparisonMetrics(todayContributionCount: 14, last7DayContributionCount: 56, currentYearContributionCount: 68))
        XCTAssertEqual(summary.partialFailureCount, 0)

        let allFriendsMembers = viewModel.teamMembers(for: ContributionTeam.allFriendsID)
        XCTAssertEqual(allFriendsMembers.map(\.id), summary.members.map(\.id))
    }

    @MainActor
    func testTeamEmptyFixturePreservesAllFriendsSemantics() throws {
        let viewModel = makeFixtureViewModel(state: "team_empty", function: #function)
        let selectedSummary = try XCTUnwrap(viewModel.selectedTeamSummary)
        let allFriendsSummary = try XCTUnwrap(viewModel.orderedTeamSummaries.first { $0.id == ContributionTeam.allFriendsID })

        XCTAssertEqual(viewModel.selectedTeamID, "fixture.team.empty")
        XCTAssertEqual(viewModel.teams.map(\.id), [ContributionTeam.allFriendsID, "fixture.team.empty"])
        XCTAssertTrue(viewModel.profiles.isEmpty)
        XCTAssertTrue(selectedSummary.members.isEmpty)
        XCTAssertEqual(selectedSummary.aggregateMetrics, .zero)
        XCTAssertEqual(allFriendsSummary.members.map(\.id), [
            "github:public:octocat",
            "gitlab:public:haru"
        ])
        XCTAssertEqual(allFriendsSummary.aggregateMetrics, ContributionComparisonMetrics(todayContributionCount: 3, last7DayContributionCount: 14, currentYearContributionCount: 14))
    }

    @MainActor
    func testTeamPartialFailureFixtureFlagsUnavailableMembersWithoutBreakingState() throws {
        let viewModel = makeFixtureViewModel(state: "team_partial_failure", function: #function)
        let summary = try XCTUnwrap(viewModel.selectedTeamSummary)

        XCTAssertEqual(viewModel.selectedTeam?.id, "fixture.team.partial")
        XCTAssertEqual(summary.members.map(\.id), [
            "github:public:alex",
            "gitlab:public:bella",
            "github:https://github.example.com:casey",
            "gitlab:https://gitlab.example.com:drew"
        ])
        XCTAssertEqual(summary.members.map { $0.comparisonInput.availability }, [
            .complete,
            .profileOnly,
            .contributionsOnly,
            .unavailable
        ])
        XCTAssertEqual(summary.rankedMembers.map(\.id), [
            "github:public:alex",
            "github:https://github.example.com:casey"
        ])
        XCTAssertEqual(summary.unavailableMembers.map(\.id), [
            "gitlab:public:bella",
            "gitlab:https://gitlab.example.com:drew"
        ])
        XCTAssertEqual(summary.aggregateMetrics, ContributionComparisonMetrics(todayContributionCount: 4, last7DayContributionCount: 19, currentYearContributionCount: 19))
        XCTAssertEqual(summary.partialFailureCount, 3)
        XCTAssertEqual(summary.rankedMembers[1].metrics, ContributionComparisonMetrics(todayContributionCount: 1, last7DayContributionCount: 9, currentYearContributionCount: 9))
        XCTAssertEqual(summary.unavailableMembers[0].errorMessage, "Could not load contribution graph.")
        XCTAssertEqual(summary.unavailableMembers[0].unavailableReasonLabel, "Contribution graph unavailable")
        XCTAssertEqual(summary.unavailableMembers[1].errorMessage, "Account not found or currently unavailable.")
        XCTAssertEqual(summary.unavailableMembers[1].unavailableReasonLabel, "Profile and contribution graph unavailable")
    }

    @MainActor
    func testRankingUsesSelectedMetricThenTodayThenProviderAndUsername() {
        let inputs = [
            makeComparisonInput(
                id: "gitlab:public:adam",
                displayName: "Aaron",
                today: 4,
                last7: 18,
                year: 50,
                availability: .complete
            ),
            makeComparisonInput(
                id: "github:public:zulu",
                displayName: "Zulu",
                today: 4,
                last7: 18,
                year: 30,
                availability: .complete
            ),
            makeComparisonInput(
                id: "github:public:bravo",
                displayName: "Bravo",
                today: 2,
                last7: 18,
                year: 90,
                availability: .complete
            ),
            makeComparisonInput(
                id: "gitlab:public:missing",
                displayName: "Missing",
                today: 9,
                last7: 20,
                year: 120,
                availability: .profileOnly,
                errorMessage: "Could not load contribution graph."
            )
        ]

        XCTAssertEqual(
            ContributionViewModel.rankedComparisonInputs(from: inputs, metric: .today).map(\.id),
            ["github:public:zulu", "gitlab:public:adam", "github:public:bravo"]
        )
        XCTAssertEqual(
            ContributionViewModel.rankedComparisonInputs(from: inputs, metric: .last7ActiveDays).map(\.id),
            ["github:public:zulu", "gitlab:public:adam", "github:public:bravo"]
        )
        XCTAssertEqual(
            ContributionViewModel.rankedComparisonInputs(from: inputs, metric: .currentYear).map(\.id),
            ["github:public:bravo", "gitlab:public:adam", "github:public:zulu"]
        )
        XCTAssertEqual(
            ContributionViewModel.unavailableComparisonInputs(from: inputs).map(\.id),
            ["gitlab:public:missing"]
        )
    }

    @MainActor
    func testRankingSeparationKeepsAvailableMembersRankedAndUnavailableMembersSortedByFailureSeverity() {
        let inputs = [
            makeComparisonInput(
                id: "gitlab:public:zoe",
                displayName: "Zoe",
                today: 4,
                last7: 12,
                year: 20,
                availability: .contributionsOnly
            ),
            makeComparisonInput(
                id: "github:public:anna",
                displayName: "Anna",
                today: 4,
                last7: 12,
                year: 20,
                availability: .complete
            ),
            makeComparisonInput(
                id: "gitlab:public:bella",
                displayName: "Bella",
                today: 9,
                last7: 30,
                year: 40,
                availability: .profileOnly,
                errorMessage: "Could not load contribution graph."
            ),
            makeComparisonInput(
                id: "github:public:chris",
                displayName: "Chris",
                today: 6,
                last7: 21,
                year: 25,
                availability: .unavailable,
                errorMessage: "Account not found or currently unavailable."
            ),
            makeComparisonInput(
                id: "github:public:drew",
                displayName: "Drew",
                today: 8,
                last7: 15,
                year: 18,
                availability: .loading
            )
        ]

        XCTAssertEqual(
            ContributionViewModel.rankedComparisonInputs(from: inputs, metric: .today).map(\.id),
            ["github:public:anna", "gitlab:public:zoe"]
        )
        XCTAssertEqual(
            ContributionViewModel.unavailableComparisonInputs(from: inputs).map(\.id),
            ["gitlab:public:bella", "github:public:chris", "github:public:drew"]
        )
        XCTAssertEqual(
            ContributionViewModel.unavailableComparisonInputs(from: inputs).map(\.unavailableReasonLabel),
            [
                "Contribution graph unavailable",
                "Profile and contribution graph unavailable",
                "Refreshing contribution graph"
            ]
        )
    }

    @MainActor
    func testLegacyMigrationFixtureBuildsAllFriendsSummary() throws {
        let viewModel = makeFixtureViewModel(state: "legacy_migration", function: #function)
        let summary = try XCTUnwrap(viewModel.selectedTeamSummary)

        XCTAssertEqual(viewModel.selectedTeamID, ContributionTeam.allFriendsID)
        XCTAssertEqual(viewModel.teams, [ContributionTeam.allFriends(accountIDs: [
            "github:public:octocat",
            "gitlab:https://gitlab.example.com:haru"
        ])])
        XCTAssertEqual(summary.members.map(\.id), [
            "github:public:octocat",
            "gitlab:https://gitlab.example.com:haru"
        ])
        XCTAssertEqual(summary.rankedMembers.map(\.id), [
            "github:public:octocat",
            "gitlab:https://gitlab.example.com:haru"
        ])
        XCTAssertEqual(summary.aggregateMetrics, ContributionComparisonMetrics(todayContributionCount: 5, last7DayContributionCount: 20, currentYearContributionCount: 20))
        XCTAssertTrue(summary.unavailableMembers.isEmpty)
        XCTAssertEqual(summary.insight(for: .hottestToday)?.headline, "The Octocat")
        XCTAssertEqual(summary.insight(for: .mostActiveThisYear)?.detail, "12 contributions this year")
    }

    @MainActor
    private func makeFixtureViewModel(state: String, function: StaticString) -> ContributionViewModel {
        let userDefaults = makeTestUserDefaults(function: function)
        return ContributionViewModel(
            userDefaults: userDefaults,
            shouldRefreshOnLoad: false,
            uiTestEnvironment: [
                "GITGET_UI_TEST_MODE": "1",
                "GITGET_UI_TEST_STATE": state
            ]
        )
    }

    private func makeTestUserDefaults(function: StaticString) -> UserDefaults {
        let suiteName = "ContributionViewModelTeamStateTests.\(function)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeComparisonInput(
        id: String,
        displayName: String,
        today: Int,
        last7: Int,
        year: Int,
        availability: ContributionMemberAvailability,
        errorMessage: String? = nil
    ) -> ContributionComparisonInput {
        let components = id.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        let provider = components.first == "gitlab" ? ContributionProvider.gitlab : ContributionProvider.github
        let username = components.last.map(String.init) ?? displayName.lowercased()

        return ContributionComparisonInput(
            account: ContributionAccount(provider: provider, username: username),
            displayName: displayName,
            username: username,
            providerTitle: provider.title,
            metrics: ContributionComparisonMetrics(
                todayContributionCount: today,
                last7DayContributionCount: last7,
                currentYearContributionCount: year
            ),
            availability: availability,
            errorMessage: errorMessage
        )
    }

    @MainActor
    private func loadTeamStore(from userDefaults: UserDefaults) -> ContributionTeamStore? {
        guard let data = userDefaults.data(forKey: ContributionViewModel.teamStoreKey) else {
            return nil
        }

        return try? JSONDecoder().decode(ContributionTeamStore.self, from: data)
    }
}

final class WidgetContractTests: XCTestCase {
    func testGitHubWidgetProviderAlwaysBuildsGitHubAccount() {
        let account = GitHubContributionsProvider.gitHubAccount(for: "  octocat  ")

        XCTAssertEqual(account.provider, .github)
        XCTAssertEqual(account.username, "octocat")
        XCTAssertNil(account.serverOrigin)
    }

    func testGitHubWidgetIntentKeepsOnlyExpectedConfigurationFields() {
        let intent = GitHubContributionsWidgetIntent()

        XCTAssertNil(intent.username)
        XCTAssertEqual(intent.theme, .default)
    }
}

final class TeamInsightComputationTests: XCTestCase {
    @MainActor
    func testTeamRankedFixtureBuildsDeterministicInsights() throws {
        let viewModel = makeFixtureViewModel(state: "team_ranked", function: #function)
        let summary = try XCTUnwrap(viewModel.selectedTeamSummary)

        XCTAssertEqual(summary.insights.map(\.kind), ContributionTeamInsightKind.allCases)
        XCTAssertEqual(
            summary.insight(for: .hottestToday),
            ContributionTeamInsight(
                kind: .hottestToday,
                headline: "Anna",
                detail: "7 contributions today",
                isFallback: false
            )
        )
        XCTAssertEqual(
            summary.insight(for: .streakLeader),
            ContributionTeamInsight(
                kind: .streakLeader,
                headline: "Anna",
                detail: "7 active days in a row",
                isFallback: false
            )
        )
        XCTAssertEqual(
            summary.insight(for: .biggest7DayMover),
            ContributionTeamInsight(
                kind: .biggest7DayMover,
                headline: "Anna",
                detail: "+28 vs previous 7 days",
                isFallback: false
            )
        )
        XCTAssertEqual(
            summary.insight(for: .mostActiveThisYear),
            ContributionTeamInsight(
                kind: .mostActiveThisYear,
                headline: "Anna",
                detail: "36 contributions this year",
                isFallback: false
            )
        )
    }

    @MainActor
    func testTeamEmptyFixtureFallsBackForAllInsights() throws {
        let viewModel = makeFixtureViewModel(state: "team_empty", function: #function)
        let summary = try XCTUnwrap(viewModel.selectedTeamSummary)

        XCTAssertEqual(summary.insights.count, 4)
        XCTAssertTrue(summary.insights.allSatisfy(\.isFallback))
        XCTAssertEqual(Set(summary.insights.map(\.headline)), ["Not enough data yet"])
        XCTAssertEqual(
            summary.insights,
            [
                ContributionTeamInsight(
                    kind: .hottestToday,
                    headline: "Not enough data yet",
                    detail: "No team member has a contribution recorded for today.",
                    isFallback: true
                ),
                ContributionTeamInsight(
                    kind: .streakLeader,
                    headline: "Not enough data yet",
                    detail: "A contribution graph is required to calculate streaks.",
                    isFallback: true
                ),
                ContributionTeamInsight(
                    kind: .biggest7DayMover,
                    headline: "Not enough data yet",
                    detail: "Not enough recent contribution activity to compare two 7-day windows.",
                    isFallback: true
                ),
                ContributionTeamInsight(
                    kind: .mostActiveThisYear,
                    headline: "Not enough data yet",
                    detail: "No team member has enough yearly contribution history yet.",
                    isFallback: true
                )
            ]
        )
    }

    @MainActor
    func testTeamPartialFailureFixtureComputesInsightsFromAvailableMembersOnly() throws {
        let viewModel = makeFixtureViewModel(state: "team_partial_failure", function: #function)
        let summary = try XCTUnwrap(viewModel.selectedTeamSummary)

        XCTAssertEqual(summary.insight(for: .hottestToday)?.headline, "Alex")
        XCTAssertEqual(summary.insight(for: .streakLeader)?.headline, "Alex")
        XCTAssertEqual(summary.insight(for: .biggest7DayMover)?.headline, "Alex")
        XCTAssertEqual(summary.insight(for: .mostActiveThisYear)?.headline, "Alex")
        XCTAssertFalse(summary.insights.contains { $0.headline == "Bella" || $0.headline == "Drew" })
    }

    func testContributionProfileInsightInputsUseDeterministicReferenceDates() {
        let referenceDate = Contribution.date(from: "2026-04-10")!
        let profile = makeProfile(
            id: "github:public:anna",
            displayName: "Anna",
            contributions: [
                makeContribution(date: "2026-03-27", count: 2),
                makeContribution(date: "2026-04-01", count: 1),
                makeContribution(date: "2026-04-04", count: 4),
                makeContribution(date: "2026-04-08", count: 3),
                makeContribution(date: "2026-04-09", count: 2),
                makeContribution(date: "2026-04-10", count: 1)
            ]
        )

        XCTAssertEqual(profile.activeStreakCount(referenceDate: referenceDate), 3)
        XCTAssertEqual(profile.sevenDayMomentum(referenceDate: referenceDate), 9)
    }

    func testContributionProfileSevenDayMomentumReturnsNilWithoutRecentSignal() {
        let referenceDate = Contribution.date(from: "2026-04-10")!
        let profile = makeProfile(
            id: "github:public:anna",
            displayName: "Anna",
            contributions: [
                makeContribution(date: "2026-03-01", count: 7),
                makeContribution(date: "2026-03-02", count: 3)
            ]
        )

        XCTAssertNil(profile.sevenDayMomentum(referenceDate: referenceDate))
        XCTAssertEqual(profile.activeStreakCount(referenceDate: referenceDate), 0)
    }

    @MainActor
    private func makeFixtureViewModel(state: String, function: StaticString) -> ContributionViewModel {
        let userDefaults = makeTestUserDefaults(function: function)
        return ContributionViewModel(
            userDefaults: userDefaults,
            shouldRefreshOnLoad: false,
            uiTestEnvironment: [
                "GITGET_UI_TEST_MODE": "1",
                "GITGET_UI_TEST_STATE": state
            ]
        )
    }

    private func makeTestUserDefaults(function: StaticString) -> UserDefaults {
        let suiteName = "TeamInsightComputationTests.\(function)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeProfile(
        id: String,
        displayName: String,
        contributions: [Contribution]
    ) -> ContributionProfile {
        let components = id.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        let provider = components.first == "gitlab" ? ContributionProvider.gitlab : ContributionProvider.github
        let username = components.last.map(String.init) ?? displayName.lowercased()

        return ContributionProfile(
            account: ContributionAccount(provider: provider, username: username),
            user: User(
                login: username,
                name: displayName,
                profileImageURL: nil,
                bio: nil,
                location: nil,
                company: nil,
                followers: nil,
                following: nil,
                createdAt: nil
            ),
            contributions: contributions,
            isLoading: false,
            errorMessage: nil,
            hasResolvedUser: true,
            hasResolvedContributions: true
        )
    }

    private func makeContribution(date: String, count: Int) -> Contribution {
        Contribution(
            date: Contribution.date(from: date)!,
            count: count,
            level: contributionLevel(for: count)
        )
    }

    private func contributionLevel(for count: Int) -> Contribution.Level {
        switch count {
        case ..<1:
            return .zero
        case 1...3:
            return .one
        case 4...6:
            return .two
        case 7...9:
            return .three
        default:
            return .four
        }
    }
}
