//
//  GitHubContributionsWidgetViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import WidgetKit
import SwiftUI
import SwiftDate

struct GitHubContributionsWidgetViewModel {
    private let contributions: [Contribution]
    private let configuration: ConfigurationIntent
    
    var theme: Theme {
        configuration.theme
    }
    
    var profileImage: UIImage = UIImage()
    
    var username: String? {
        configuration.username
    }
    
    var todayContributionCount: Int? {
        return contributions.filter { $0.date.isToday }.first?.count
    }
    
    var cellColorSet: [[Color]] {
        guard let lastDate = contributions.last?.date else {
            return []
        }
        
        let rows = 7
        let columns = 20
        
        let cellCount = rows * columns - (rows - Calendar.current.component(.weekday, from: lastDate))
        let levels = contributions.suffix(cellCount).map(\.level).chunked(into: rows)
        return levels.map { $0.map { theme.supplyColor(by: $0)} }
    }
    
    var isInitial: Bool {
        contributions.isEmpty
    }
    
    var invalidUsername: Bool {
        username != .none && contributions.isEmpty
    }
    
    init(contributions: [Contribution], configuration: ConfigurationIntent) {
        self.contributions = contributions
        self.configuration = configuration
    }
}

extension GitHubContributionsWidgetViewModel: TimelineEntry {
    var date: Date {
        contributions.last?.date ?? Date()
    }
}
