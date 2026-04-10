//
//  ContributionView.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI

struct ContributionView: View {
    let profile: ContributionProfile
    let theme: Theme
    let cellColors: [[Color]]
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if UITestSupport.isEnabled {
                Text(profile.uiIdentifier)
                    .font(.system(size: 1))
                    .foregroundColor(.clear)
                    .accessibilityIdentifier("profile-marker-\(profile.uiIdentifier)")
            }

            if profile.isLoading {
                VStack(spacing: 8) {
                    if UITestSupport.isEnabled {
                        Text("@\(profile.username)")
                            .font(.system(size: 1))
                            .foregroundColor(.clear)
                            .accessibilityIdentifier("profile-username-\(profile.uiIdentifier)")
                    }
                    ProgressView(UITestSupport.isEnabled ? "Loading profile" : "")
                    if UITestSupport.isEnabled {
                        Text("Loading profile")
                            .font(.system(size: 14, design: .monospaced))
                            .accessibilityIdentifier("loading-profile-label")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Loading profile")
                .accessibilityIdentifier("profile-loading-\(profile.uiIdentifier)")
            } else if let errorMessage = profile.errorMessage {
                VStack(spacing: 8) {
                    if UITestSupport.isEnabled {
                        Text("@\(profile.username)")
                            .font(.system(size: 1))
                            .foregroundColor(.clear)
                            .accessibilityIdentifier("profile-username-\(profile.uiIdentifier)")
                    }
                    Text(errorMessage)
                        .modifier(NoticeTextStyle())
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(errorMessage)
                .accessibilityIdentifier("profile-error-\(profile.uiIdentifier)")
            } else {
                if UITestSupport.isEnabled {
                    Text("@\(profile.username)")
                        .font(.system(size: 1))
                        .foregroundColor(.clear)
                        .accessibilityIdentifier("profile-username-\(profile.uiIdentifier)")
                }
                graph
                Divider()
                details

                if UITestSupport.isEnabled {
                    Button("Delete") {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("profile-delete-\(profile.uiIdentifier)")
                }
            }
        }
        .padding(18)
        .accessibilityIdentifier("profile-card-\(profile.uiIdentifier)")
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.levelFourColor.opacity(0.18), lineWidth: 1)
        )
        .accessibilityIdentifier("friends.profileCard.\(profile.id)")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(profile.name)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.blackAndWhite4)
                    .accessibilityIdentifier("profile-name-\(profile.uiIdentifier)")

                HStack(spacing: 8) {
                    providerBadge
                    Text("@\(profile.username)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.blackAndWhite3)
                        .accessibilityIdentifier("friends.profileUsername.\(profile.id)")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("@\(profile.username)")
                .accessibilityIdentifier("profile-username-\(profile.uiIdentifier)")
            }

            Spacer()

            if let todayContributionCount = profile.todayContributionCount {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(todayContributionCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.levelFourColor)
                    Text("today")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.blackAndWhite3)
                        .textCase(.uppercase)
                }
            }
        }
    }

    private var providerBadge: some View {
        Text(profile.providerTitle)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(theme.levelFourColor)
            )
            .accessibilityIdentifier("provider-badge-\(profile.uiIdentifier)")
    }

    private var graph: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Contributions in \(Date().gitHubYear)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
                Spacer()
                Text("\(profile.currentYearContributions)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.levelFourColor)
            }

            CalendarChart(columns: 20, spacing: 3.0) { row, column in
                if let color = cellColors.element(at: row)?.element(at: column) {
                    color.modifier(CalendarChartCell())
                } else {
                    Color.clear
                }
            }
            .frame(height: 110)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(profile.bio)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.blackAndWhite4)
                .accessibilityIdentifier("friends.profileBio.\(profile.id)")

            labelRow(icon: "location.circle", text: profile.location)
            labelRow(icon: "building", text: profile.company)

            HStack(spacing: 6) {
                Image(systemName: "person.2")
                    .frame(width: 12, height: 12)
                    .foregroundColor(.blackAndWhite4)
                Text(profile.followers)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.blackAndWhite4)
                Text("followers")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
                Text("|")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
                Text(profile.following)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.blackAndWhite4)
                Text("following")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
            }

            HStack {
                Spacer()
                Text("develop since \(profile.startYear)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
            }
        }
    }

    private func labelRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 12, height: 12)
                .foregroundColor(.blackAndWhite4)
            Text(" " + text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.blackAndWhite4)
        }
    }
}

struct ContributionComparisonSectionView: View {
    let summary: ContributionTeamSummary
    let selectedMetric: ContributionComparisonMetric
    let theme: Theme
    let onSelectMetric: (ContributionComparisonMetric) -> Void

    private var rankedMembers: [ContributionComparisonInput] {
        summary.rankedMembers(for: selectedMetric)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Team Comparison")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.blackAndWhite4)

                Text(comparisonSubtitle)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
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
                    .foregroundColor(.blackAndWhite3)
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

struct ContributionInsightSectionView: View {
    let summary: ContributionTeamSummary
    let theme: Theme

    private let columns = [
        GridItem(.flexible(), spacing: 10, alignment: .top),
        GridItem(.flexible(), spacing: 10, alignment: .top)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Team Insights")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.blackAndWhite4)

                Text("Four quick reads built only from the contribution and profile data already loaded for this team.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
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
                .foregroundColor(.blackAndWhite3)
                .textCase(.uppercase)
                .accessibilityIdentifier("friends.insights.title.\(insight.id)")

            Text(insight.headline)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(insight.isFallback ? .blackAndWhite3 : .blackAndWhite4)
                .accessibilityIdentifier("friends.insights.headline.\(insight.id)")

            Text(insight.detail)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.blackAndWhite3)
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

struct ContributionComparisonRowView: View {
    let rank: Int
    let input: ContributionComparisonInput
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
                    .foregroundColor(.blackAndWhite4)

                HStack(spacing: 8) {
                    Text(input.providerTitle)
                    Text("@\(input.username)")
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.blackAndWhite3)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(metric.value(from: input.metrics))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(theme.levelFourColor)

                Text(metric.shortTitle)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
                    .textCase(.uppercase)

                Text("Today \(input.metrics.todayContributionCount)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
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

struct ContributionUnavailableSectionView: View {
    let members: [ContributionComparisonInput]
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Unavailable Members")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.blackAndWhite4)

                Text("These members stay out of ranking until their contribution graph data is available.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.blackAndWhite3)
            }

            VStack(spacing: 10) {
                ForEach(members) { input in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(input.displayName)
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blackAndWhite4)

                                HStack(spacing: 8) {
                                    Text(input.providerTitle)
                                    Text("@\(input.username)")
                                }
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.blackAndWhite3)
                            }

                            Spacer(minLength: 12)

                            Text(input.unavailableReasonLabel)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.levelFourColor)
                                .multilineTextAlignment(.trailing)
                        }

                        if let errorMessage = input.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.blackAndWhite3)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(theme.levelFourColor.opacity(0.08))
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("friends.unavailable.row.\(input.id)")
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
        .accessibilityIdentifier("friends.unavailable.card")
    }
}
