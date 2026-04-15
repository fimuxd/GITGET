struct ContributionTeamMemberState: Identifiable {
    let teamID: String
    let profile: ContributionAccountProfileState
    let comparisonInput: ContributionComparisonEntry

    var id: String { profile.id }
}
