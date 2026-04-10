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

    private static func formattedCount(_ count: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: count)) ?? "0"
    }
}

@MainActor
final class ContributionViewModel: ObservableObject {
    @Published var enteredUserName: String = ""
    @Published var enteredServerOrigin: String = ""
    @Published var selectedProvider: ContributionProvider = .github
    @Published var selectedTheme: Theme = .default {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Self.themeKey)
        }
    }
    @Published private(set) var profiles: [ContributionProfile] = []

    private static let accountsKey = "savedContributionAccounts"
    private static let themeKey = "selectedTheme"

    init() {
        if let rawValue = UserDefaults.standard.object(forKey: Self.themeKey) as? Int,
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

        if profiles.contains(where: { $0.account.id == account.id }) {
            enteredUserName = ""
            enteredServerOrigin = ""
            refreshProfile(for: account)
            return
        }

        profiles.insert(
            ContributionProfile(
                account: account,
                user: nil,
                contributions: [],
                isLoading: true,
                errorMessage: nil
            ),
            at: 0
        )
        enteredUserName = ""
        enteredServerOrigin = ""
        persistAccounts()
        refreshProfile(for: account)
    }

    func removeProfiles(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        persistAccounts()
    }

    func removeProfile(_ profile: ContributionProfile) {
        profiles.removeAll { $0.id == profile.id }
        persistAccounts()
    }

    func refreshAll() {
        let accounts = profiles.map(\.account)
        for account in accounts {
            refreshProfile(for: account)
        }
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
        if let data = UserDefaults.standard.data(forKey: Self.accountsKey),
           let accounts = try? JSONDecoder().decode([ContributionAccount].self, from: data),
           !accounts.isEmpty {
            profiles = accounts.map {
                ContributionProfile(account: $0, user: nil, contributions: [], isLoading: true, errorMessage: nil)
            }
            refreshAll()
            return
        }

        let legacyUsername = UserDefaults.standard.string(forKey: "username")?.trimmed ?? ""
        guard !legacyUsername.isEmpty else { return }

        let account = ContributionAccount(provider: .github, username: legacyUsername)
        profiles = [ContributionProfile(account: account, user: nil, contributions: [], isLoading: true, errorMessage: nil)]
        persistAccounts()
        refreshProfile(for: account)
    }

    private func persistAccounts() {
        let accounts = profiles.map(\.account)
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: Self.accountsKey)
    }

    private func setLoading(_ isLoading: Bool, for id: String) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].isLoading = isLoading
        profiles[index].errorMessage = nil
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
                errorMessage: nil
            )

        case (.success(let user), .failure):
            return ContributionProfile(
                account: account,
                user: user,
                contributions: [],
                isLoading: false,
                errorMessage: "Could not load contribution graph."
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
                errorMessage: nil
            )

        case (.failure, .failure):
            return ContributionProfile(
                account: account,
                user: nil,
                contributions: [],
                isLoading: false,
                errorMessage: "Account not found or currently unavailable."
            )
        }
    }

    private func apply(_ profile: ContributionProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.insert(profile, at: 0)
            persistAccounts()
        }
    }
}
