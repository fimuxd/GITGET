//
//  GitHubContributionsProvider.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import WidgetKit
import Combine

class GitHubContributionsProvider: IntentTimelineProvider {
    typealias Entry = GitHubContributionsWidgetViewModel
    typealias Intent = ConfigurationIntent
    
    func placeholder(in context: Context) -> Entry {
        let currentDate = Date()
        let dateRange = Calendar.current.date(byAdding: .year, value: -1, to: currentDate)?.range(to: currentDate) ?? []
        let contributions = dateRange.map { Contribution(date: $0, count: 0, level: .zero) }
        return Entry(contributions: contributions, configuration: Intent())
    }

    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        let currentDate = Date()
        let dateRange = Calendar.current.date(byAdding: .year, value: -1, to: currentDate)?.range(to: currentDate) ?? []
        let contributions = dateRange.map { Contribution(date: $0, count: .random(in: 0...20), level: .random()) }
        completion(Entry(contributions: contributions, configuration: configuration))
    }

    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let username = configuration.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        Task {
            async let userResponse = UserAPI.userInfo(of: username)
            async let contributionResponse = ContributionAPI.contributions(of: username)
            let (userResult, contributionsResult) = await (userResponse, contributionResponse)
            
            await MainActor.run {
                switch (userResult, contributionsResult) {
                case (.success(let user), .success(let contributions)):
                    let entry = Entry(contributions: contributions, configuration: configuration, user: user)
                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                    completion(timeline)
                case (.failure, .success(let contributions)):
                    let entry = Entry(contributions: contributions, configuration: configuration)
                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                    completion(timeline)
                case (.success(let user), .failure):
                    let entry = Entry(contributions: [], configuration: configuration, user: user)
                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                    completion(timeline)
                case (.failure, .failure):
                    let entry = Entry(contributions: [], configuration: configuration)
                    let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
                    completion(timeline)
                }
            }
        }
    }
}
