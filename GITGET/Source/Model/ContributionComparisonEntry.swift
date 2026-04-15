struct ContributionComparisonEntry: Identifiable {
    let account: ContributionAccount
    let displayName: String
    let username: String
    let providerTitle: String
    let metrics: ContributionComparisonMetrics
    let availability: ContributionMemberAvailability
    let errorMessage: String?

    var id: String { account.id }

    var hasAvailableContributionGraph: Bool {
        availability == .complete || availability == .contributionsOnly
    }

    var providerNeutralRankingKey: String {
        "\(account.provider.rawValue.lowercased()):\(username.lowercased())"
    }

    var unavailableReasonLabel: String {
        switch availability {
        case .profileOnly:
            return "Contribution graph unavailable"
        case .unavailable:
            return "Profile and contribution graph unavailable"
        case .loading:
            return "Refreshing contribution graph"
        case .complete, .contributionsOnly:
            return "Contribution graph available"
        }
    }
}
