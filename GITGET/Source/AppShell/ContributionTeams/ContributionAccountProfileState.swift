import SwiftUI

struct ContributionAccountProfileState: Identifiable {
    let account: ContributionAccount
    var user: User?
    var contributions: [Contribution]
    var isLoading: Bool
    var errorMessage: String?
    var hasResolvedUser: Bool
    var hasResolvedContributions: Bool

    var id: String { account.id }

    private var metricsCalendar: Calendar {
        account.provider == .gitlab ? .autoupdatingCurrent : .gitHubUTC
    }

    private var contributionYear: Int {
        switch account.provider {
        case .github:
            return metricsCalendar.component(.year, from: Date())
        case .gitlab:
            if let createdAt = user?.createdAt {
                return metricsCalendar.component(.year, from: createdAt)
            }
            return metricsCalendar.component(.year, from: Date())
        }
    }

    var providerTitle: String { account.provider.title }
    var username: String { user?.login ?? account.username }
    var name: String { user?.name ?? account.username }
    var bio: String { user?.bio ?? "Keep Contributions Green".localized }
    var location: String { user?.location ?? "Anywhere" }
    var company: String { user?.company ?? "Independent" }
    var followers: String { Self.formattedCount(user?.followers ?? 0) }
    var following: String { Self.formattedCount(user?.following ?? 0) }
    var startYear: String {
        if let createdAt = user?.createdAt {
            return String(Calendar.gitHubUTC.component(.year, from: createdAt))
        }

        return String(Calendar.gitHubUTC.component(.year, from: Date()))
    }
    var contributionYearLabel: String { String(contributionYear) }
    var currentYearContributions: Int {
        let calendar = metricsCalendar
        return contributions
            .filter { calendar.component(.year, from: $0.date) == contributionYear }
            .map(\.count)
            .reduce(0, +)
    }
    var todayContributionCount: Int? {
        let calendar = metricsCalendar
        return contributions.last { calendar.isDate($0.date, inSameDayAs: Date()) }?.count
    }
    var hasContent: Bool {
        !contributions.isEmpty
    }

    var availability: ContributionMemberAvailability {
        if isLoading {
            return .loading
        }

        switch (hasResolvedUser, hasResolvedContributions) {
        case (true, true):
            return .complete
        case (true, false):
            return .profileOnly
        case (false, true):
            return .contributionsOnly
        case (false, false):
            return .unavailable
        }
    }

    var comparisonMetrics: ContributionComparisonMetrics {
        ContributionComparisonMetrics(contributions: contributions, calendar: metricsCalendar)
    }

    func activeStreakCount(referenceDate: Date = Date(), maxDays: Int = 7) -> Int {
        let calendar = metricsCalendar
        let today = calendar.startOfDay(for: referenceDate)
        let countsByDay = Dictionary(uniqueKeysWithValues: contributions.map {
            (calendar.startOfDay(for: $0.date), $0.count)
        })

        var streak = 0
        for dayOffset in 0..<maxDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                break
            }

            if (countsByDay[date] ?? 0) > 0 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }

    func sevenDayMomentum(referenceDate: Date = Date()) -> Int? {
        let calendar = metricsCalendar
        let today = calendar.startOfDay(for: referenceDate)
        let countsByDay = Dictionary(uniqueKeysWithValues: contributions.map {
            (calendar.startOfDay(for: $0.date), $0.count)
        })

        func contributionSum(dayOffsets: ClosedRange<Int>) -> Int {
            dayOffsets.reduce(0) { partialResult, dayOffset in
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                    return partialResult
                }

                return partialResult + (countsByDay[date] ?? 0)
            }
        }

        let currentWindowTotal = contributionSum(dayOffsets: 0...6)
        let previousWindowTotal = contributionSum(dayOffsets: 7...13)
        guard currentWindowTotal > 0 || previousWindowTotal > 0 else {
            return nil
        }

        return currentWindowTotal - previousWindowTotal
    }

    private static func formattedCount(_ count: Int) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: count)) ?? "0"
    }
}
