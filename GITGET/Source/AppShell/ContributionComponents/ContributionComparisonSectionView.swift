import SwiftUI

struct ContributionComparisonSectionView: View {
    let summary: ContributionTeamSummary
    let selectedMetric: ContributionComparisonMetric
    let theme: Theme
    let onSelectMetric: (ContributionComparisonMetric) -> Void

    private var rankedMembers: [ContributionComparisonEntry] {
        summary.rankedMembers(for: selectedMetric)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Team Comparison")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primaryText)

                Text(comparisonSubtitle)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
            }

            Picker("Comparison Metric", selection: Binding(
                get: { selectedMetric },
                set: onSelectMetric
            )) {
                ForEach(ContributionComparisonMetric.allCases) { metric in
                    Text(metric.shortTitle).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("friends.comparison.metricPicker")

            if rankedMembers.isEmpty {
                Text("No members have enough contribution graph data to rank yet.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
                    .accessibilityIdentifier("friends.comparison.empty")
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(rankedMembers.enumerated()), id: \.element.id) { index, input in
                        ContributionComparisonRowView(
                            rank: index + 1,
                            input: input,
                            metric: selectedMetric,
                            theme: theme
                        )
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.levelFourColor.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("friends.comparison.card")
    }

    private var comparisonSubtitle: String {
        let rankedCount = rankedMembers.count
        return "Ranking by \(selectedMetric.title.lowercased()) with today contributions and name as tiebreakers across \(rankedCount) available member\(rankedCount == 1 ? "" : "s")."
    }
}

struct ContributionComparisonRowView: View {
    let rank: Int
    let input: ContributionComparisonEntry
    let metric: ContributionComparisonMetric
    let theme: Theme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("#\(rank)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(theme.levelFourColor)
                .frame(width: 34, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(input.displayName)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primaryText)

                HStack(spacing: 8) {
                    Text(input.providerTitle)
                    Text("@\(input.username)")
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.secondaryText)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(metric.value(from: input.metrics))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(theme.levelFourColor)

                Text(metric.shortTitle)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
                    .textCase(.uppercase)

                Text("Today \(input.metrics.todayContributionCount)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.levelFourColor.opacity(0.08))
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("friends.comparison.row.\(input.id)")
    }
}

#Preview {
    ContributionComparisonRowView(rank: 0, input: .init(account: .init(provider: .github, username: "fimuxd"), displayName: "박보영", username: "fimuxd", providerTitle: "GitHub", metrics: .zero, availability: .complete, errorMessage: nil), metric: .currentYear, theme: .gitlab)
}
