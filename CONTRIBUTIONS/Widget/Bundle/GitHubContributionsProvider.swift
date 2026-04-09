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

    @Parameter(title: "username")
    var username: String?

    @Parameter(title: "theme", default: .default)
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
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let username = configuration.username?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""

        async let userResponse = UserAPI.userInfo(of: username)
        async let contributionResponse = ContributionAPI.contributions(of: username)
        let (userResult, contributionsResult) = await (userResponse, contributionResponse)

        let entry: Entry
        switch (userResult, contributionsResult) {
        case (.success(let user), .success(let contributions)):
            entry = Entry(contributions: contributions, configuration: configuration, user: user)
        case (.failure, .success(let contributions)):
            entry = Entry(contributions: contributions, configuration: configuration)
        case (.success(let user), .failure):
            entry = Entry(contributions: [], configuration: configuration, user: user)
        case (.failure, .failure):
            entry = Entry(contributions: [], configuration: configuration)
        }

        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}
