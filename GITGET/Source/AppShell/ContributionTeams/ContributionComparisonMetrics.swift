import SwiftUI

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
        self.init(contributions: contributions, referenceDate: referenceDate, calendar: .gitHubUTC)
    }

    init(contributions: [Contribution], referenceDate: Date = Date(), calendar: Calendar) {
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
