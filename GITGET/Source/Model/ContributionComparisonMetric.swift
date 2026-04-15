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
