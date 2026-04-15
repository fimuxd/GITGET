struct ContributionTeamInsight: Identifiable, Equatable {
    let kind: ContributionTeamInsightKind
    let headline: String
    let detail: String
    let isFallback: Bool

    var id: String { kind.id }
    var title: String { kind.title }
}
