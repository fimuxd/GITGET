//
//  GitHubContributionsProvider.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import Foundation
import AppIntents
import WidgetKit

struct GitHubContributionsWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "CONTRIBUTIONS"
    static var description = IntentDescription("GitHub contributions")

    @Parameter(title: "Username")
    var username: String?

    @Parameter(title: "Theme", default: .default)
    var theme: GitHubWidgetTheme

    init() {
        username = nil
        theme = .default
    }

    init(username: String? = nil, theme: GitHubWidgetTheme = .default) {
        self.username = username
        self.theme = theme
    }
}

struct GitHubContributionsProvider: AppIntentTimelineProvider {
    typealias Entry = GitHubContributionsWidgetViewModel
    typealias Intent = GitHubContributionsWidgetIntent

    private let refreshIntervalMinutes = 5

    static func gitHubAccount(for username: String) -> ContributionAccount {
        ContributionAccount(provider: .github, username: username)
    }
    
    func placeholder(in context: Context) -> Entry {
        let currentDate = Date()
        let dateRange = Calendar.current.date(byAdding: .year, value: -1, to: currentDate)?.range(to: currentDate) ?? []
        let contributions = dateRange.map { Contribution(date: $0, count: 0, level: .zero) }
        return Entry(contributions: contributions, configuration: Intent())
    }

    func snapshot(for configuration: Intent, in context: Context) async -> Entry {
        let currentDate = Date()
        let dateRange = Calendar.current.date(byAdding: .year, value: -1, to: currentDate)?.range(to: currentDate) ?? []
        let contributions = dateRange.map { Contribution(date: $0, count: .random(in: 0...20), level: .random()) }
        return Entry(contributions: contributions, configuration: configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<Entry> {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: refreshIntervalMinutes, to: currentDate) ?? currentDate.addingTimeInterval(TimeInterval(refreshIntervalMinutes * 60))
        let username = configuration.username?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""

        guard !username.isEmpty else {
            let entry = Entry(contributions: [], configuration: configuration)
            return Timeline(entries: [entry], policy: .after(refreshDate))
        }

        let account = Self.gitHubAccount(for: username)
        async let contributionResponse = ContributionAPI.contributions(of: account)
        let userResult: Result<User, Error>?

        if shouldFetchUserProfile(for: context.family) {
            userResult = await UserAPI.userInfo(of: account)
        } else {
            userResult = nil
        }

        let contributionsResult = await contributionResponse

        let entry = makeEntry(
            configuration: configuration,
            userResult: userResult,
            contributionsResult: contributionsResult
        )

        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    private func shouldFetchUserProfile(for family: WidgetFamily) -> Bool {
        family == .systemLarge
    }

    private func makeEntry(
        configuration: Intent,
        userResult: Result<User, Error>?,
        contributionsResult: Result<[Contribution], Error>
    ) -> Entry {
        let contributions: [Contribution]
        switch contributionsResult {
        case .success(let loadedContributions):
            contributions = loadedContributions
        case .failure:
            contributions = []
        }

        switch userResult {
        case .success(let user):
            return Entry(contributions: contributions, configuration: configuration, user: user)
        case .failure, .none:
            return Entry(contributions: contributions, configuration: configuration)
        }
    }
}
