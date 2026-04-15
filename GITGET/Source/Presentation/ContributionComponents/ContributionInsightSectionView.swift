import SwiftUI

struct ContributionInsightSectionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let summary: ContributionTeamSummary
    let theme: Theme

    private var columns: [GridItem] {
        let columnCount = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: columnCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Team Insights")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primaryText)

                Text("Four quick reads built only from the contribution and profile data already loaded for this team.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
                ForEach(summary.insights) { insight in
                    ContributionInsightCardView(insight: insight, theme: theme)
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
        .accessibilityIdentifier("friends.insights.card")
    }
}

struct ContributionInsightCardView: View {
    let insight: ContributionTeamInsight
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(insight.title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Color.secondaryText)
                .textCase(.uppercase)
                .accessibilityIdentifier("friends.insights.title.\(insight.id)")

            Text(insight.headline)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(insight.isFallback ? Color.secondaryText : Color.primaryText)
                .accessibilityIdentifier("friends.insights.headline.\(insight.id)")

            Text(insight.detail)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("friends.insights.detail.\(insight.id)")
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.levelFourColor.opacity(insight.isFallback ? 0.05 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.levelFourColor.opacity(insight.isFallback ? 0.12 : 0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("friends.insights.item.\(insight.id)")
    }
}
