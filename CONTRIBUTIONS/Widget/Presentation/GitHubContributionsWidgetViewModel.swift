//
//  GitHubContributionsWidgetViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import WidgetKit
import SwiftUI

struct GitHubContributionsWidgetViewModel {
    let contributions: [Contribution]
    let configuration: GitHubContributionsWidgetIntent
    var user: User? = nil
    
    var theme: GitHubWidgetTheme {
        configuration.theme
    }
    
    var username: String? {
        let trimmedUsername = configuration.username?.trimmed
        return trimmedUsername?.isEmpty == false ? trimmedUsername : nil
    }
    
    var todayContributionCount: Int? {
        return contributions.last { $0.date.isGitHubToday }?.count
    }
    
    func cellColorSet(columnsCount: Int) -> [[Color]] {
        guard let lastDate = contributions.last?.date else {
            return []
        }
        
        let rows = 7
        let columns = columnsCount
        
        let cellCount = rows * columns - (rows - Calendar.current.component(.weekday, from: lastDate))
        let levels = contributions.suffix(cellCount).map(\.level).chunked(into: rows)
        return levels.map { $0.map { theme.supplyColor(by: $0)} }
    }
    
    var isInitial: Bool {
        contributions.isEmpty
    }
    
    var invalidUsername: Bool {
        guard let username, !username.trimmed.isEmpty else {
            return false
        }

        return user == nil && contributions.isEmpty
    }
    
    //for large
    var currentYearContributions: Int {
        return contributions
            .filter { $0.date.gitHubYear == Date().gitHubYear }
            .map { $0.count }.reduce(0, +)
    }
    
    var displayUsername: String {
        if let login = user?.login?.trimmed, !login.isEmpty {
            return login
        }

        if let username {
            return username
        }

        if let name = user?.name?.trimmed, !name.isEmpty {
            return name
        }

        return "Anonymous"
    }
    
    //FIXME
//    var profileImageURL: Source {
//        .network(ImageResource(downloadURL: URL(string: user?.profileImageURL ?? "")!, cacheKey: imageKey))
//    }
    
    var bio: String {
        user?.bio ?? "Keep GitHub Contributions Green 🟩".localized
    }
    
    var location: String {
        user?.location ?? "Anywhere"
    }
    
    var company: String {
        user?.company ?? "🔦🔍👀"
    }
    
    var followers: String {
        let count = user?.followers ?? 0
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedCount = numberFormatter.string(from: NSNumber(value: count)) ?? ""
        return formattedCount
    }
    
    var following: String {
        let count = user?.following ?? 0
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedCount = numberFormatter.string(from: NSNumber(value: count)) ?? ""
        return formattedCount
    }
    
    var startYear: String {
        user?.createdAt?.gitHubYearString ?? Date().gitHubYearString
    }
}

extension GitHubContributionsWidgetViewModel: TimelineEntry {
    var date: Date {
        contributions.last?.date ?? Date()
    }
}
