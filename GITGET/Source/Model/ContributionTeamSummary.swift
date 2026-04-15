struct ContributionTeamSummary: Identifiable {
    let team: ContributionTeam
    let members: [ContributionTeamMemberState]
    let rankings: [ContributionMetricRanking]
    let insights: [ContributionTeamInsight]
    let unavailableMembers: [ContributionComparisonEntry]
    let aggregateMetrics: ContributionComparisonMetrics
    let partialFailureCount: Int

    var id: String { team.id }

    func rankedMembers(for metric: ContributionComparisonMetric) -> [ContributionComparisonEntry] {
        rankings.first(where: { $0.metric == metric })?.members ?? []
    }

    var rankedMembers: [ContributionComparisonEntry] {
        rankings.first?.members ?? []
    }

    func insight(for kind: ContributionTeamInsightKind) -> ContributionTeamInsight? {
        insights.first { $0.kind == kind }
    }
}
