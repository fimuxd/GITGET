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
