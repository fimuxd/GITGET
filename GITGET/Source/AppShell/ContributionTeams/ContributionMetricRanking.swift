struct ContributionMetricRanking: Identifiable {
    let metric: ContributionComparisonMetric
    let members: [ContributionComparisonEntry]

    var id: String { metric.id }
}
