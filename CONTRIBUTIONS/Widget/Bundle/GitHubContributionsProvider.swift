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
    
    private var timelineCancellable: AnyCancellable?
    private let queue = DispatchQueue(label: "fimuxd.gitget.network")
    
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
        
        timelineCancellable = GitHubNetwork().getContributions(of: username)
            .combineLatest(GitHubNetwork().getUser(of: username))
            .map { Timeline(entries: [Entry(contributions: $0.0, configuration: configuration, user: $0.1)], policy: .after(refreshDate)) }
            .replaceError(with: Timeline(entries: [Entry(contributions: [], configuration: configuration)], policy: .after(refreshDate)))
            .subscribe(on: queue)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: completion)
    }
}
