//
//  ContributionViewModel.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI

struct ContributionProfile: Identifiable {
    let account: ContributionAccount
    var user: User?
    var contributions: [Contribution]
    var isLoading: Bool
    var errorMessage: String?
    var hasResolvedUser: Bool
    var hasResolvedContributions: Bool

    var id: String { account.id }

    var providerTitle: String { account.provider.title }
    var username: String { user?.login ?? account.username }
    var name: String { user?.name ?? account.username }
    var bio: String { user?.bio ?? "Keep Contributions Green".localized }
    var location: String { user?.location ?? "Anywhere" }
    var company: String { user?.company ?? "Independent" }
    var followers: String { Self.formattedCount(user?.followers ?? 0) }
    var following: String { Self.formattedCount(user?.following ?? 0) }
    var startYear: String { String(user?.createdAt?.gitHubYear ?? Date().gitHubYear) }
    var currentYearContributions: Int {
        contributions
            .filter { $0.date.gitHubYear == Date().gitHubYear }
            .map(\.count)
            .reduce(0, +)
    }
    var todayContributionCount: Int? {
        contributions.last { $0.date.isGitHubToday }?.count
    }
    var hasContent: Bool {
        !contributions.isEmpty
    }

    var availability: ContributionMemberAvailability {
        if isLoading {
            return .loading
        }

        switch (hasResolvedUser, hasResolvedContributions) {
        case (true, true):
            return .complete
        case (true, false):
            return .profileOnly
        case (false, true):
            return .contributionsOnly
        case (false, false):
            return .unavailable
        }
    }

    var comparisonMetrics: ContributionComparisonMetrics {
        ContributionComparisonMetrics(contributions: contributions)
    }

    func activeStreakCount(referenceDate: Date = Date(), maxDays: Int = 7) -> Int {
        let calendar = Calendar.gitHubUTC
        let today = calendar.startOfDay(for: referenceDate)
        let countsByDay = Dictionary(uniqueKeysWithValues: contributions.map {
            (calendar.startOfDay(for: $0.date), $0.count)
        })

        var streak = 0
        for dayOffset in 0..<maxDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                break
            }

            if (countsByDay[date] ?? 0) > 0 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    func sevenDayMomentum(referenceDate: Date = Date()) -> Int? {
        let calendar = Calendar.gitHubUTC
        let today = calendar.startOfDay(for: referenceDate)
        let countsByDay = Dictionary(uniqueKeysWithValues: contributions.map {
            (calendar.startOfDay(for: $0.date), $0.count)
        })

        func contributionSum(dayOffsets: ClosedRange<Int>) -> Int {
            dayOffsets.reduce(0) { partialResult, dayOffset in
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                    return partialResult
                }

                return partialResult + (countsByDay[date] ?? 0)
            }
        }

        let currentWindowTotal = contributionSum(dayOffsets: 0...6)
        let previousWindowTotal = contributionSum(dayOffsets: 7...13)
        guard currentWindowTotal > 0 || previousWindowTotal > 0 else {
            return nil
        }

        return currentWindowTotal - previousWindowTotal
    }

    private static func formattedCount(_ count: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: count)) ?? "0"
    }
}

enum ContributionMemberAvailability: String {
    case loading
    case complete
    case profileOnly
    case contributionsOnly
    case unavailable
}

enum ContributionComparisonMetric: String, CaseIterable, Identifiable {
    case today
    case last7ActiveDays
    case currentYear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .last7ActiveDays:
            return "Last 7 Active Days"
        case .currentYear:
            return "Current Year"
        }
    }

    var shortTitle: String {
        switch self {
        case .today:
            return "Today"
        case .last7ActiveDays:
            return "7 Active Days"
        case .currentYear:
            return "Year"
        }
    }

    func value(from metrics: ContributionComparisonMetrics) -> Int {
        switch self {
        case .today:
            return metrics.todayContributionCount
        case .last7ActiveDays:
            return metrics.last7ActiveDayContributionCount
        case .currentYear:
            return metrics.currentYearContributionCount
        }
    }
}

struct ContributionComparisonMetrics: Equatable {
    let todayContributionCount: Int
    let last7DayContributionCount: Int
    let currentYearContributionCount: Int

    var last7ActiveDayContributionCount: Int {
        last7DayContributionCount
    }

    static let zero = ContributionComparisonMetrics(
        todayContributionCount: 0,
        last7DayContributionCount: 0,
        currentYearContributionCount: 0
    )

    init(
        todayContributionCount: Int,
        last7DayContributionCount: Int,
        currentYearContributionCount: Int
    ) {
        self.todayContributionCount = todayContributionCount
        self.last7DayContributionCount = last7DayContributionCount
        self.currentYearContributionCount = currentYearContributionCount
    }

    init(contributions: [Contribution], referenceDate: Date = Date()) {
        let calendar = Calendar.gitHubUTC
        let today = calendar.startOfDay(for: referenceDate)

        todayContributionCount = contributions.last(where: { calendar.isDate($0.date, inSameDayAs: today) })?.count ?? 0
        last7DayContributionCount = contributions
            .filter { contribution in contribution.count > 0 && calendar.startOfDay(for: contribution.date) <= today }
            .sorted { $0.date > $1.date }
            .prefix(7)
            .map(\.count)
            .reduce(0, +)
        currentYearContributionCount = contributions
            .filter { calendar.component(.year, from: $0.date) == calendar.component(.year, from: today) }
            .map(\.count)
            .reduce(0, +)
    }

    static func + (lhs: ContributionComparisonMetrics, rhs: ContributionComparisonMetrics) -> ContributionComparisonMetrics {
        ContributionComparisonMetrics(
            todayContributionCount: lhs.todayContributionCount + rhs.todayContributionCount,
            last7DayContributionCount: lhs.last7DayContributionCount + rhs.last7DayContributionCount,
            currentYearContributionCount: lhs.currentYearContributionCount + rhs.currentYearContributionCount
        )
    }
}

struct ContributionComparisonInput: Identifiable {
    let account: ContributionAccount
    let displayName: String
    let username: String
    let providerTitle: String
    let metrics: ContributionComparisonMetrics
    let availability: ContributionMemberAvailability
    let errorMessage: String?

    var id: String { account.id }

    var hasAvailableContributionGraph: Bool {
        availability == .complete || availability == .contributionsOnly
    }

    var providerNeutralRankingKey: String {
        "\(account.provider.rawValue.lowercased()):\(username.lowercased())"
    }

    var unavailableReasonLabel: String {
        switch availability {
        case .profileOnly:
            return "Contribution graph unavailable"
        case .unavailable:
            return "Profile and contribution graph unavailable"
        case .loading:
            return "Refreshing contribution graph"
        case .complete, .contributionsOnly:
            return "Contribution graph available"
        }
    }
}

struct ContributionMetricRanking: Identifiable {
    let metric: ContributionComparisonMetric
    let members: [ContributionComparisonInput]

    var id: String { metric.id }
}

enum ContributionTeamInsightKind: String, CaseIterable, Identifiable {
    case hottestToday
    case streakLeader
    case biggest7DayMover
    case mostActiveThisYear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hottestToday:
            return "Hottest Today"
        case .streakLeader:
            return "7-Day Streak Leader"
        case .biggest7DayMover:
            return "Biggest 7-Day Mover"
        case .mostActiveThisYear:
            return "Most Active This Year"
        }
    }
}

struct ContributionTeamInsight: Identifiable, Equatable {
    let kind: ContributionTeamInsightKind
    let headline: String
    let detail: String
    let isFallback: Bool

    var id: String { kind.id }
    var title: String { kind.title }
}

struct ContributionTeamMemberState: Identifiable {
    let teamID: String
    let profile: ContributionProfile
    let comparisonInput: ContributionComparisonInput

    var id: String { profile.id }
}

struct ContributionTeamSummary: Identifiable {
    let team: ContributionTeam
    let members: [ContributionTeamMemberState]
    let rankings: [ContributionMetricRanking]
    let insights: [ContributionTeamInsight]
    let unavailableMembers: [ContributionComparisonInput]
    let aggregateMetrics: ContributionComparisonMetrics
    let partialFailureCount: Int

    var id: String { team.id }

    func rankedMembers(for metric: ContributionComparisonMetric) -> [ContributionComparisonInput] {
        rankings.first(where: { $0.metric == metric })?.members ?? []
    }

    var rankedMembers: [ContributionComparisonInput] {
        rankings.first?.members ?? []
    }

    func insight(for kind: ContributionTeamInsightKind) -> ContributionTeamInsight? {
        insights.first { $0.kind == kind }
    }
}

@MainActor
final class ContributionViewModel: ObservableObject {
    private let userDefaults: UserDefaults
    private let processInfo: ProcessInfo
    private let shouldRefreshOnLoad: Bool
    private let uiTestEnvironment: [String: String]?
    private let refreshProfileHandler: ((ContributionAccount) -> Void)?

    @Published var enteredUserName: String = ""
    @Published var enteredServerOrigin: String = ""
    @Published var selectedProvider: ContributionProvider = .github
    @Published var selectedTheme: Theme = .default {
        didSet {
            userDefaults.set(selectedTheme.rawValue, forKey: Self.themeKey)
        }
    }
    @Published private(set) var profiles: [ContributionProfile] = []
    @Published private(set) var teams: [ContributionTeam] = []
    @Published private(set) var selectedTeamID: String?
    @Published private(set) var selectedComparisonMetric: ContributionComparisonMetric = .today

    static let accountsKey = "savedContributionAccounts"
    static let teamStoreKey = "savedContributionTeamStore"
    private static let themeKey = "selectedTheme"

    private var currentTeamStore: ContributionTeamStore?
    private var profilesByAccountID: [String: ContributionProfile] = [:]

    private var environment: [String: String] {
        uiTestEnvironment ?? processInfo.environment
    }

    private var shouldPreserveUITestSelection: Bool {
        environment["GITGET_UI_TEST_PRESERVE_SELECTION"] == "1"
    }

    private var shouldPreserveUITestStore: Bool {
        environment["GITGET_UI_TEST_PRESERVE_TEAM_STORE"] == "1"
    }

    var selectedTeam: ContributionTeam? {
        teams.first { $0.id == selectedTeamID }
    }

    var customTeams: [ContributionTeam] {
        teams.filter { $0.id != ContributionTeam.allFriendsID }
    }

    var orderedTeamSummaries: [ContributionTeamSummary] {
        teams.map { makeTeamSummary(for: $0) }
    }

    var selectedTeamSummary: ContributionTeamSummary? {
        guard let selectedTeam else { return nil }
        return makeTeamSummary(for: selectedTeam)
    }

    var selectedTeamMembers: [ContributionTeamMemberState] {
        selectedTeamSummary?.members ?? []
    }

    var selectedTeamComparisonInputs: [ContributionComparisonInput] {
        selectedTeamSummary?.rankedMembers(for: selectedComparisonMetric) ?? []
    }

    var selectedTeamUnavailableComparisonInputs: [ContributionComparisonInput] {
        selectedTeamSummary?.unavailableMembers ?? []
    }

    init(
        userDefaults: UserDefaults = .standard,
        processInfo: ProcessInfo = .processInfo,
        shouldRefreshOnLoad: Bool = true,
        uiTestEnvironment: [String: String]? = nil,
        refreshProfileHandler: ((ContributionAccount) -> Void)? = nil
    ) {
        self.userDefaults = userDefaults
        self.processInfo = processInfo
        self.shouldRefreshOnLoad = shouldRefreshOnLoad
        self.uiTestEnvironment = uiTestEnvironment
        self.refreshProfileHandler = refreshProfileHandler

        if applyUITestStateIfNeeded() {
            return
        }

        if let rawValue = userDefaults.object(forKey: Self.themeKey) as? Int,
           let theme = Theme(rawValue: rawValue) {
            selectedTheme = theme
        }

        loadSavedAccounts()
    }

    func addAccount() {
        let trimmedUsername = enteredUserName.trimmed
        guard !trimmedUsername.isEmpty else { return }

        let account = ContributionAccount(
            provider: selectedProvider,
            username: trimmedUsername,
            serverOrigin: enteredServerOrigin
        )

        if profilesByAccountID[account.id] != nil {
            enteredUserName = ""
            enteredServerOrigin = ""
            refreshProfile(for: account)
            return
        }

        profilesByAccountID[account.id] = Self.placeholderProfile(for: account)
        addAccountToTeamStore(account)
        enteredUserName = ""
        enteredServerOrigin = ""
        refreshProfile(for: account)
    }

    func removeProfiles(at offsets: IndexSet) {
        let removedAccountIDs = offsets.map { profiles[$0].account.id }
        removeAccountsFromTeamStore(withIDs: removedAccountIDs)
    }

    func removeProfile(_ profile: ContributionProfile) {
        removeAccountsFromTeamStore(withIDs: [profile.id])
    }

    func refreshAll() {
        refreshAll(using: performRefresh(for:))
    }

    func refreshAll(using refresh: (ContributionAccount) -> Void) {
        let accounts = currentTeamStore?.accounts ?? profiles.map(\.account)
        for account in accounts {
            refresh(account)
        }
    }

    func selectTeam(_ teamID: String) {
        guard let currentTeamStore else { return }

        let updatedStore = currentTeamStore.selectingTeam(withID: teamID)
        guard updatedStore.selectedTeamID != selectedTeamID else { return }

        applyTeamStore(updatedStore, preserveProfiles: true)
        persistTeamStore()
    }

    func createTeam(named name: String) {
        let store = (currentTeamStore ?? ContributionTeamStore.migratedFromLegacyAccounts([])).creatingTeam(named: name)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    func selectComparisonMetric(_ metric: ContributionComparisonMetric) {
        guard selectedComparisonMetric != metric else { return }
        selectedComparisonMetric = metric
    }

    func renameTeam(teamID: String, to name: String) {
        guard let currentTeamStore else { return }

        let store = currentTeamStore.renamingTeam(withID: teamID, to: name)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    func deleteTeam(teamID: String) {
        guard let currentTeamStore else { return }

        let store = currentTeamStore.deletingTeam(withID: teamID)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    func moveTeamUp(teamID: String) {
        guard let currentTeamStore,
              let sourceIndex = currentTeamStore.customTeams.firstIndex(where: { $0.id == teamID }),
              sourceIndex > 0 else { return }

        let store = currentTeamStore.reorderingCustomTeams(from: sourceIndex, to: sourceIndex - 1)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    func moveTeamDown(teamID: String) {
        guard let currentTeamStore,
              let sourceIndex = currentTeamStore.customTeams.firstIndex(where: { $0.id == teamID }),
              sourceIndex < currentTeamStore.customTeams.count - 1 else { return }

        let store = currentTeamStore.reorderingCustomTeams(from: sourceIndex, to: sourceIndex + 2)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    func isProtectedTeam(_ teamID: String) -> Bool {
        teamID == ContributionTeam.allFriendsID
    }

    func customTeamPosition(for teamID: String) -> Int? {
        customTeams.firstIndex(where: { $0.id == teamID }).map { $0 + 1 }
    }

    func canMoveTeamUp(_ teamID: String) -> Bool {
        guard let index = customTeams.firstIndex(where: { $0.id == teamID }) else { return false }
        return index > 0
    }

    func canMoveTeamDown(_ teamID: String) -> Bool {
        guard let index = customTeams.firstIndex(where: { $0.id == teamID }) else { return false }
        return index < customTeams.count - 1
    }

    func isMember(_ accountID: String, inTeamID teamID: String) -> Bool {
        teams.first(where: { $0.id == teamID })?.accountIDs.contains(accountID) == true
    }

    func setMembership(forAccountID accountID: String, inTeamID teamID: String, isIncluded: Bool) {
        guard let currentTeamStore else { return }

        let store = currentTeamStore.settingMembership(forAccountID: accountID, inTeamID: teamID, isIncluded: isIncluded)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    func removeProfileFromSelectedTeam(_ profile: ContributionProfile) {
        guard let selectedTeamID,
              selectedTeamID != ContributionTeam.allFriendsID else {
            removeProfile(profile)
            return
        }

        setMembership(forAccountID: profile.id, inTeamID: selectedTeamID, isIncluded: false)
    }

    func teamMembers(for teamID: String) -> [ContributionTeamMemberState] {
        orderedTeamSummaries.first(where: { $0.id == teamID })?.members ?? []
    }

    func comparisonInputs(
        for teamID: String,
        metric: ContributionComparisonMetric? = nil
    ) -> [ContributionComparisonInput] {
        let resolvedMetric = metric ?? selectedComparisonMetric
        return orderedTeamSummaries.first(where: { $0.id == teamID })?.rankedMembers(for: resolvedMetric) ?? []
    }

    func team(for teamID: String) -> ContributionTeam? {
        teams.first { $0.id == teamID }
    }

    func profile(for accountID: String) -> ContributionProfile? {
        profilesByAccountID[accountID]
    }

    func cellColorSet(for profile: ContributionProfile, columnsCount: Int) -> [[Color]] {
        guard let lastDate = profile.contributions.last?.date else {
            return []
        }

        let rows = 7
        let cellCount = rows * columnsCount - (rows - Calendar.current.component(.weekday, from: lastDate))
        let levels = profile.contributions.suffix(cellCount).map(\.level).chunked(into: rows)
        return levels.map { $0.map { selectedTheme.supplyColor(by: $0) } }
    }

    func refreshProfile(for account: ContributionAccount) {
        setLoading(true, for: account.id)

        Task {
            async let userResult = UserAPI.userInfo(of: account)
            async let contributionsResult = ContributionAPI.contributions(of: account)

            let resolvedUserResult = await userResult
            let resolvedContributionsResult = await contributionsResult

            let profile = makeProfile(
                for: account,
                userResult: resolvedUserResult,
                contributionsResult: resolvedContributionsResult
            )
            apply(profile)
        }
    }

    private func loadSavedAccounts() {
        if let data = userDefaults.data(forKey: Self.teamStoreKey),
           let decodedStore = try? JSONDecoder().decode(ContributionTeamStore.self, from: data) {
            let store = decodedStore.normalized()
            applyTeamStore(store)

            if shouldRefreshOnLoad, !store.accounts.isEmpty {
                refreshAll()
            }
            return
        }

        if let data = userDefaults.data(forKey: Self.accountsKey),
           let accounts = try? JSONDecoder().decode([ContributionAccount].self, from: data),
           !accounts.isEmpty {
            let store = ContributionTeamStore.migratedFromLegacyAccounts(accounts)
            applyTeamStore(store)
            persistTeamStore()

            if shouldRefreshOnLoad {
                refreshAll()
            }
            return
        }

        let legacyUsername = userDefaults.string(forKey: "username")?.trimmed ?? ""
        guard !legacyUsername.isEmpty else { return }

        let store = ContributionTeamStore.migratedFromLegacyUsername(legacyUsername)
        applyTeamStore(store)
        persistTeamStore()

        if shouldRefreshOnLoad {
            refreshAll()
        }
    }

    private func addAccountToTeamStore(_ account: ContributionAccount) {
        let selectedDestinationTeamID = selectedTeamID ?? ContributionTeam.allFriendsID
        let baseStore = currentTeamStore ?? ContributionTeamStore.migratedFromLegacyAccounts([])
        let store = baseStore.addingAccount(account, toTeamID: selectedDestinationTeamID)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    private func removeAccountsFromTeamStore(withIDs accountIDs: [String]) {
        guard let currentTeamStore else { return }

        let store = currentTeamStore.removingAccounts(withIDs: accountIDs)
        applyTeamStore(store, preserveProfiles: true)
        persistTeamStore()
    }

    private func persistTeamStore() {
        guard let currentTeamStore,
              let data = try? JSONEncoder().encode(currentTeamStore) else { return }

        userDefaults.set(data, forKey: Self.teamStoreKey)
    }

    private func applyTeamStore(_ store: ContributionTeamStore, preserveProfiles: Bool = false) {
        currentTeamStore = store
        teams = store.teams
        selectedTeamID = store.selectedTeamID

        let existingProfiles = preserveProfiles ? profilesByAccountID : profilesByAccountID
        var updatedProfilesByID: [String: ContributionProfile] = [:]
        for account in store.accounts {
            updatedProfilesByID[account.id] = existingProfiles[account.id] ?? Self.placeholderProfile(for: account)
        }

        profilesByAccountID = updatedProfilesByID
        syncSelectedProfiles()
    }

    private func syncSelectedProfiles() {
        guard let currentTeamStore else {
            profiles = []
            return
        }

        profiles = currentTeamStore.selectedAccounts.map { account in
            profilesByAccountID[account.id] ?? Self.placeholderProfile(for: account)
        }
    }

    private func setLoading(_ isLoading: Bool, for id: String) {
        guard var profile = profilesByAccountID[id] else { return }
        profile.isLoading = isLoading
        profile.errorMessage = nil
        profilesByAccountID[id] = profile
        syncSelectedProfiles()
    }

    private func performRefresh(for account: ContributionAccount) {
        if let refreshProfileHandler {
            refreshProfileHandler(account)
            return
        }

        refreshProfile(for: account)
    }

    private func makeProfile(
        for account: ContributionAccount,
        userResult: Result<User, Error>,
        contributionsResult: Result<[Contribution], Error>
    ) -> ContributionProfile {
        switch (userResult, contributionsResult) {
        case (.success(let user), .success(let contributions)):
            return ContributionProfile(
                account: account,
                user: user,
                contributions: contributions.sorted { $0.date < $1.date },
                isLoading: false,
                errorMessage: nil,
                hasResolvedUser: true,
                hasResolvedContributions: true
            )

        case (.success(let user), .failure):
            return ContributionProfile(
                account: account,
                user: user,
                contributions: [],
                isLoading: false,
                errorMessage: "Could not load contribution graph.",
                hasResolvedUser: true,
                hasResolvedContributions: false
            )

        case (.failure, .success(let contributions)):
            return ContributionProfile(
                account: account,
                user: User(
                    login: account.username,
                    name: account.username,
                    profileImageURL: nil,
                    bio: nil,
                    location: nil,
                    company: nil,
                    followers: nil,
                    following: nil,
                    createdAt: nil
                ),
                contributions: contributions.sorted { $0.date < $1.date },
                isLoading: false,
                errorMessage: nil,
                hasResolvedUser: false,
                hasResolvedContributions: true
            )

        case (.failure, .failure):
            return ContributionProfile(
                account: account,
                user: nil,
                contributions: [],
                isLoading: false,
                errorMessage: "Account not found or currently unavailable.",
                hasResolvedUser: false,
                hasResolvedContributions: false
            )
        }
    }

    func apply(_ profile: ContributionProfile) {
        guard currentTeamStore?.accounts.contains(where: { $0.id == profile.id }) == true else {
            return
        }

        profilesByAccountID[profile.id] = profile
        syncSelectedProfiles()
    }

    private func makeTeamSummary(for team: ContributionTeam) -> ContributionTeamSummary {
        let members = team.accountIDs.compactMap { accountID -> ContributionTeamMemberState? in
            guard let profile = profilesByAccountID[accountID] else { return nil }
            let comparisonInput = makeComparisonInput(for: profile)
            return ContributionTeamMemberState(teamID: team.id, profile: profile, comparisonInput: comparisonInput)
        }

        let comparisonInputs = members.map(\.comparisonInput)
        let rankings = ContributionComparisonMetric.allCases.map { metric in
            ContributionMetricRanking(
                metric: metric,
                members: Self.rankedComparisonInputs(from: comparisonInputs, metric: metric)
            )
        }
        let insights = ContributionTeamInsightKind.allCases.map { kind in
            Self.makeInsight(kind, from: members)
        }
        let unavailableMembers = Self.unavailableComparisonInputs(from: comparisonInputs)
        let aggregateMetrics = members
            .map { $0.comparisonInput.metrics }
            .reduce(.zero, +)
        let partialFailureCount = members
            .map(\.comparisonInput.availability)
            .filter { $0 != .complete }
            .count

        return ContributionTeamSummary(
            team: team,
            members: members,
            rankings: rankings,
            insights: insights,
            unavailableMembers: unavailableMembers,
            aggregateMetrics: aggregateMetrics,
            partialFailureCount: partialFailureCount
        )
    }

    private func makeComparisonInput(for profile: ContributionProfile) -> ContributionComparisonInput {
        ContributionComparisonInput(
            account: profile.account,
            displayName: profile.name,
            username: profile.username,
            providerTitle: profile.providerTitle,
            metrics: profile.comparisonMetrics,
            availability: profile.availability,
            errorMessage: profile.errorMessage
        )
    }

    private func applyUITestStateIfNeeded() -> Bool {
        guard environment["GITGET_UI_TEST_MODE"] == "1" else {
            return false
        }

        userDefaults.set(Theme.default.rawValue, forKey: Self.themeKey)

        if shouldPreserveUITestStore,
           let data = userDefaults.data(forKey: Self.teamStoreKey),
           let decodedStore = try? JSONDecoder().decode(ContributionTeamStore.self, from: data) {
            applyTeamStore(decodedStore.normalized())
            return true
        }

        switch environment["GITGET_UI_TEST_STATE"] {
        case "populated":
            applyPopulatedUITestState()
        case "legacy_migration":
            applyLegacyMigrationUITestState()
        case "team_empty":
            applyTeamEmptyUITestState()
        case "team_ranked":
            applyTeamRankedUITestState()
        case "team_partial_failure":
            applyTeamPartialFailureUITestState()
        default:
            applyInitialUITestState()
        }

        return true
    }

    private func applyInitialUITestState() {
        enteredUserName = ""
        enteredServerOrigin = ""
        selectedProvider = .github
        selectedTheme = .default
        selectedComparisonMetric = .today
        currentTeamStore = nil
        profilesByAccountID = [:]
        teams = []
        selectedTeamID = nil
        profiles = []
    }

    private func applyPopulatedUITestState() {
        let profile = Self.makeMockProfile()
        let store = ContributionTeamStore.migratedFromLegacyAccounts([profile.account])
        applyFixtureState(store: store, profiles: [profile])
    }

    private func applyLegacyMigrationUITestState() {
        let accounts = [
            ContributionAccount(provider: .github, username: "octocat"),
            ContributionAccount(provider: .gitlab, username: "haru", serverOrigin: "gitlab.example.com/team")
        ]

        let store = ContributionTeamStore.migratedFromLegacyAccounts(accounts)
        let profiles = [
            Self.makeFixtureProfile(
                account: accounts[0],
                name: "The Octocat",
                bio: "Migrated GitHub fixture",
                location: "San Francisco",
                company: "GitHub",
                followers: 3939,
                following: 9,
                dayOffsetsToCounts: [0: 4, -1: 2, -2: 1, -12: 5]
            ),
            Self.makeFixtureProfile(
                account: accounts[1],
                name: "Haru",
                bio: "Migrated GitLab fixture",
                location: "Seoul",
                company: "GITGET",
                followers: 21,
                following: 12,
                dayOffsetsToCounts: [0: 1, -1: 1, -5: 2, -15: 4]
            )
        ]

        applyFixtureState(store: store, profiles: profiles)
    }

    private func applyTeamEmptyUITestState() {
        let accounts = [
            ContributionAccount(provider: .github, username: "octocat"),
            ContributionAccount(provider: .gitlab, username: "haru")
        ]

        let store = ContributionTeamStore(
            version: ContributionTeamStore.currentVersion,
            selectedTeamID: "fixture.team.empty",
            teams: [
                ContributionTeam.allFriends(accountIDs: accounts.map(\.id)),
                ContributionTeam(id: "fixture.team.empty", name: "Design Team", accountIDs: [])
            ],
            accounts: accounts
        ).normalized()

        let profiles = [
            Self.makeFixtureProfile(
                account: accounts[0],
                name: "The Octocat",
                bio: "All Friends fixture",
                location: "San Francisco",
                company: "GitHub",
                followers: 3939,
                following: 9,
                dayOffsetsToCounts: [0: 2, -1: 2, -10: 3]
            ),
            Self.makeFixtureProfile(
                account: accounts[1],
                name: "Haru",
                bio: "All Friends fixture",
                location: "Seoul",
                company: "GITGET",
                followers: 21,
                following: 12,
                dayOffsetsToCounts: [0: 1, -3: 4, -20: 2]
            )
        ]

        applyFixtureState(store: store, profiles: profiles)
    }

    private func applyTeamRankedUITestState() {
        let accounts = [
            ContributionAccount(provider: .github, username: "anna"),
            ContributionAccount(provider: .gitlab, username: "bora", serverOrigin: "gitlab.example.com/team"),
            ContributionAccount(provider: .github, username: "chris", serverOrigin: "github.example.com")
        ]

        let rankedTeam = ContributionTeam(id: "fixture.team.ranked", name: "iOS Team", accountIDs: accounts.map(\.id))
        let store = ContributionTeamStore(
            version: ContributionTeamStore.currentVersion,
            selectedTeamID: rankedTeam.id,
            teams: [
                ContributionTeam.allFriends(accountIDs: accounts.map(\.id)),
                rankedTeam
            ],
            accounts: accounts
        ).normalized()

        let profiles = [
            Self.makeFixtureProfile(
                account: accounts[0],
                name: "Anna",
                bio: "Ranks first in the deterministic fixture",
                location: "Seoul",
                company: "GITGET",
                followers: 100,
                following: 12,
                dayOffsetsToCounts: [0: 7, -1: 6, -2: 5, -3: 4, -4: 3, -5: 2, -6: 1, -20: 8]
            ),
            Self.makeFixtureProfile(
                account: accounts[1],
                name: "Bora",
                bio: "Ranks second in the deterministic fixture",
                location: "Busan",
                company: "GITGET",
                followers: 80,
                following: 10,
                dayOffsetsToCounts: [0: 5, -1: 4, -2: 4, -3: 3, -4: 2, -5: 1, -6: 1, -10: 4]
            ),
            Self.makeFixtureProfile(
                account: accounts[2],
                name: "Chris",
                bio: "Ranks third in the deterministic fixture",
                location: "Tokyo",
                company: "GITGET",
                followers: 55,
                following: 8,
                dayOffsetsToCounts: [0: 2, -1: 2, -2: 1, -8: 1, -15: 2]
            )
        ]

        applyFixtureState(store: store, profiles: profiles)
    }

    private func applyTeamPartialFailureUITestState() {
        let accounts = [
            ContributionAccount(provider: .github, username: "alex"),
            ContributionAccount(provider: .gitlab, username: "bella"),
            ContributionAccount(provider: .github, username: "casey", serverOrigin: "github.example.com"),
            ContributionAccount(provider: .gitlab, username: "drew", serverOrigin: "gitlab.example.com/team")
        ]

        let partialTeam = ContributionTeam(id: "fixture.team.partial", name: "Platform Team", accountIDs: accounts.map(\.id))
        let store = ContributionTeamStore(
            version: ContributionTeamStore.currentVersion,
            selectedTeamID: partialTeam.id,
            teams: [
                ContributionTeam.allFriends(accountIDs: accounts.map(\.id)),
                partialTeam
            ],
            accounts: accounts
        ).normalized()

        let profiles = [
            Self.makeFixtureProfile(
                account: accounts[0],
                name: "Alex",
                bio: "Complete fixture member",
                location: "Seoul",
                company: "GITGET",
                followers: 45,
                following: 7,
                dayOffsetsToCounts: [0: 3, -1: 2, -2: 2, -6: 1, -14: 2]
            ),
            Self.makeFixtureProfile(
                account: accounts[1],
                name: "Bella",
                bio: "Profile only fixture member",
                location: "Incheon",
                company: "GITGET",
                followers: 33,
                following: 4,
                dayOffsetsToCounts: [:],
                errorMessage: "Could not load contribution graph.",
                hasResolvedUser: true,
                hasResolvedContributions: false
            ),
            Self.makeFixtureProfile(
                account: accounts[2],
                name: nil,
                bio: nil,
                location: nil,
                company: nil,
                followers: nil,
                following: nil,
                dayOffsetsToCounts: [0: 1, -1: 1, -3: 2, -12: 5],
                errorMessage: nil,
                hasResolvedUser: false,
                hasResolvedContributions: true
            ),
            Self.makeFixtureProfile(
                account: accounts[3],
                name: nil,
                bio: nil,
                location: nil,
                company: nil,
                followers: nil,
                following: nil,
                dayOffsetsToCounts: [:],
                errorMessage: "Account not found or currently unavailable.",
                hasResolvedUser: false,
                hasResolvedContributions: false
            )
        ]

        applyFixtureState(store: store, profiles: profiles)
    }

    private func applyFixtureState(store: ContributionTeamStore, profiles: [ContributionProfile]) {
        applyInitialUITestState()
        let normalizedStore = store.normalized()
        let preservedSelectionID = preservedSelectedTeamID(for: normalizedStore) ?? normalizedStore.selectedTeamID
        let resolvedStore = ContributionTeamStore(
            version: normalizedStore.version,
            selectedTeamID: preservedSelectionID,
            teams: normalizedStore.teams,
            accounts: normalizedStore.accounts
        ).normalized()
        let providedProfiles = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        currentTeamStore = resolvedStore
        teams = resolvedStore.teams
        selectedTeamID = resolvedStore.selectedTeamID
        profilesByAccountID = Dictionary(uniqueKeysWithValues: resolvedStore.accounts.map { account in
            (account.id, providedProfiles[account.id] ?? Self.placeholderProfile(for: account))
        })
        syncSelectedProfiles()
        persistTeamStore()
    }

    private func preservedSelectedTeamID(for store: ContributionTeamStore) -> String? {
        guard shouldPreserveUITestSelection,
              let data = userDefaults.data(forKey: Self.teamStoreKey),
              let persistedStore = try? JSONDecoder().decode(ContributionTeamStore.self, from: data) else {
            return nil
        }

        return store.teams.contains(where: { $0.id == persistedStore.selectedTeamID }) ? persistedStore.selectedTeamID : nil
    }

    private static func placeholderProfile(for account: ContributionAccount) -> ContributionProfile {
        ContributionProfile(
            account: account,
            user: nil,
            contributions: [],
            isLoading: true,
            errorMessage: nil,
            hasResolvedUser: false,
            hasResolvedContributions: false
        )
    }

    static func rankedComparisonInputs(
        from inputs: [ContributionComparisonInput],
        metric: ContributionComparisonMetric
    ) -> [ContributionComparisonInput] {
        inputs
            .filter(\.hasAvailableContributionGraph)
            .sorted { lhs, rhs in
                compareComparisonInputs(lhs, rhs, metric: metric)
            }
    }

    static func unavailableComparisonInputs(from inputs: [ContributionComparisonInput]) -> [ContributionComparisonInput] {
        inputs
            .filter { !$0.hasAvailableContributionGraph }
            .sorted(by: compareUnavailableComparisonInputs)
    }

    private static func makeInsight(
        _ kind: ContributionTeamInsightKind,
        from members: [ContributionTeamMemberState]
    ) -> ContributionTeamInsight {
        let availableMembers = members.filter { $0.comparisonInput.hasAvailableContributionGraph }

        switch kind {
        case .hottestToday:
            let rankedMembers = availableMembers.sorted { lhs, rhs in
                compareInsightMembers(lhs, rhs, primaryValue: { $0.comparisonInput.metrics.todayContributionCount })
            }
            guard let member = rankedMembers.first,
                  member.comparisonInput.metrics.todayContributionCount > 0 else {
                return fallbackInsight(kind, detail: "No team member has a contribution recorded for today.")
            }

            return ContributionTeamInsight(
                kind: kind,
                headline: member.comparisonInput.displayName,
                detail: "\(member.comparisonInput.metrics.todayContributionCount) contribution\(member.comparisonInput.metrics.todayContributionCount == 1 ? "" : "s") today",
                isFallback: false
            )

        case .streakLeader:
            let rankedMembers = availableMembers.sorted { lhs, rhs in
                compareInsightMembers(lhs, rhs, primaryValue: { $0.profile.activeStreakCount() })
            }
            guard let member = rankedMembers.first else {
                return fallbackInsight(kind, detail: "A contribution graph is required to calculate streaks.")
            }

            let streakCount = member.profile.activeStreakCount()
            guard streakCount > 0 else {
                return fallbackInsight(kind, detail: "No team member has an active streak in the last 7 days.")
            }

            return ContributionTeamInsight(
                kind: kind,
                headline: member.comparisonInput.displayName,
                detail: "\(streakCount) active day\(streakCount == 1 ? "" : "s") in a row",
                isFallback: false
            )

        case .biggest7DayMover:
            let rankedMembers = availableMembers.sorted { lhs, rhs in
                compareInsightMembers(
                    lhs,
                    rhs,
                    primaryValue: { $0.profile.sevenDayMomentum() ?? Int.min },
                    secondaryValue: { $0.comparisonInput.metrics.last7ActiveDayContributionCount }
                )
            }
            guard let member = rankedMembers.first,
                  let momentum = member.profile.sevenDayMomentum() else {
                return fallbackInsight(kind, detail: "Not enough recent contribution activity to compare two 7-day windows.")
            }

            let momentumPrefix = momentum > 0 ? "+" : ""
            return ContributionTeamInsight(
                kind: kind,
                headline: member.comparisonInput.displayName,
                detail: "\(momentumPrefix)\(momentum) vs previous 7 days",
                isFallback: false
            )

        case .mostActiveThisYear:
            let rankedMembers = availableMembers.sorted { lhs, rhs in
                compareInsightMembers(lhs, rhs, primaryValue: { $0.comparisonInput.metrics.currentYearContributionCount })
            }
            guard let member = rankedMembers.first,
                  member.comparisonInput.metrics.currentYearContributionCount > 0 else {
                return fallbackInsight(kind, detail: "No team member has enough yearly contribution history yet.")
            }

            return ContributionTeamInsight(
                kind: kind,
                headline: member.comparisonInput.displayName,
                detail: "\(member.comparisonInput.metrics.currentYearContributionCount) contribution\(member.comparisonInput.metrics.currentYearContributionCount == 1 ? "" : "s") this year",
                isFallback: false
            )
        }
    }

    private static func fallbackInsight(_ kind: ContributionTeamInsightKind, detail: String) -> ContributionTeamInsight {
        ContributionTeamInsight(
            kind: kind,
            headline: "Not enough data yet",
            detail: detail,
            isFallback: true
        )
    }

    private static func compareInsightMembers(
        _ lhs: ContributionTeamMemberState,
        _ rhs: ContributionTeamMemberState,
        primaryValue: (ContributionTeamMemberState) -> Int,
        secondaryValue: ((ContributionTeamMemberState) -> Int)? = nil
    ) -> Bool {
        let lhsPrimary = primaryValue(lhs)
        let rhsPrimary = primaryValue(rhs)
        if lhsPrimary != rhsPrimary {
            return lhsPrimary > rhsPrimary
        }

        if let secondaryValue {
            let lhsSecondary = secondaryValue(lhs)
            let rhsSecondary = secondaryValue(rhs)
            if lhsSecondary != rhsSecondary {
                return lhsSecondary > rhsSecondary
            }
        }

        if lhs.comparisonInput.metrics.todayContributionCount != rhs.comparisonInput.metrics.todayContributionCount {
            return lhs.comparisonInput.metrics.todayContributionCount > rhs.comparisonInput.metrics.todayContributionCount
        }

        if lhs.comparisonInput.providerNeutralRankingKey != rhs.comparisonInput.providerNeutralRankingKey {
            return lhs.comparisonInput.providerNeutralRankingKey < rhs.comparisonInput.providerNeutralRankingKey
        }

        return lhs.id.lowercased() < rhs.id.lowercased()
    }

    private static func compareComparisonInputs(
        _ lhs: ContributionComparisonInput,
        _ rhs: ContributionComparisonInput,
        metric: ContributionComparisonMetric
    ) -> Bool {
        let lhsMetricValue = metric.value(from: lhs.metrics)
        let rhsMetricValue = metric.value(from: rhs.metrics)
        if lhsMetricValue != rhsMetricValue {
            return lhsMetricValue > rhsMetricValue
        }

        if lhs.metrics.todayContributionCount != rhs.metrics.todayContributionCount {
            return lhs.metrics.todayContributionCount > rhs.metrics.todayContributionCount
        }

        if lhs.providerNeutralRankingKey != rhs.providerNeutralRankingKey {
            return lhs.providerNeutralRankingKey < rhs.providerNeutralRankingKey
        }

        return lhs.id.lowercased() < rhs.id.lowercased()
    }

    private static func compareUnavailableComparisonInputs(_ lhs: ContributionComparisonInput, _ rhs: ContributionComparisonInput) -> Bool {
        let lhsPriority = unavailablePriority(lhs.availability)
        let rhsPriority = unavailablePriority(rhs.availability)
        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }

        if lhs.providerNeutralRankingKey != rhs.providerNeutralRankingKey {
            return lhs.providerNeutralRankingKey < rhs.providerNeutralRankingKey
        }

        return lhs.id.lowercased() < rhs.id.lowercased()
    }

    private static func unavailablePriority(_ availability: ContributionMemberAvailability) -> Int {
        switch availability {
        case .profileOnly:
            return 0
        case .unavailable:
            return 1
        case .loading:
            return 2
        case .complete, .contributionsOnly:
            return 3
        }
    }

    private static func makeMockProfile() -> ContributionProfile {
        makeFixtureProfile(
            account: ContributionAccount(provider: .github, username: "octocat"),
            name: "The Octocat",
            bio: "GitHub contribution test fixture",
            location: "San Francisco",
            company: "GitHub",
            followers: 3939,
            following: 9,
            dayOffsetsToCounts: (0..<140).reduce(into: [Int: Int]()) { partialResult, offset in
                let dayOffset = offset - 139
                let levelRawValue = offset % Contribution.Level.allCases.count
                let count = levelRawValue == 0 ? 0 : levelRawValue * 3
                partialResult[dayOffset] = count
            }
        )
    }

    private static func makeFixtureProfile(
        account: ContributionAccount,
        name: String?,
        bio: String?,
        location: String?,
        company: String?,
        followers: Int?,
        following: Int?,
        dayOffsetsToCounts: [Int: Int],
        errorMessage: String? = nil,
        hasResolvedUser: Bool = true,
        hasResolvedContributions: Bool = true
    ) -> ContributionProfile {
        let user = hasResolvedUser
            ? User(
                login: account.username,
                name: name,
                profileImageURL: nil,
                bio: bio,
                location: location,
                company: company,
                followers: followers,
                following: following,
                createdAt: Contribution.date(from: "2020-01-01")
            )
            : (hasResolvedContributions
               ? User(
                    login: account.username,
                    name: account.username,
                    profileImageURL: nil,
                    bio: nil,
                    location: nil,
                    company: nil,
                    followers: nil,
                    following: nil,
                    createdAt: nil
                )
               : nil)

        return ContributionProfile(
            account: account,
            user: user,
            contributions: makeFixtureContributions(dayOffsetsToCounts),
            isLoading: false,
            errorMessage: errorMessage,
            hasResolvedUser: hasResolvedUser,
            hasResolvedContributions: hasResolvedContributions
        )
    }

    private static func makeFixtureContributions(_ dayOffsetsToCounts: [Int: Int]) -> [Contribution] {
        let calendar = Calendar.gitHubUTC
        let today = calendar.startOfDay(for: Date())

        return dayOffsetsToCounts
            .compactMap { dayOffset, count -> Contribution? in
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                    return nil
                }

                return Contribution(date: date, count: count, level: contributionLevel(for: count))
            }
            .sorted { $0.date < $1.date }
    }

    private static func contributionLevel(for count: Int) -> Contribution.Level {
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
