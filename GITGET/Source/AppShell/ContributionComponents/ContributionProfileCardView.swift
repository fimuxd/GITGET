import SwiftUI

struct ContributionProfileCardView: View {
    let profile: ContributionAccountProfileState
    let theme: Theme
    let cellColors: [[Color]]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if profile.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else if let errorMessage = profile.errorMessage {
                Text(errorMessage)
                    .modifier(NoticeTextStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                graph
                Divider()
                details
            }
        }
        .padding(18)
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
                    .foregroundColor(Color.primaryText)
                    .accessibilityIdentifier("friends.profileName.\(profile.id)")

                HStack(spacing: 8) {
                    providerBadge
                    Text("@\(profile.username)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.secondaryText)
                        .accessibilityIdentifier("friends.profileUsername.\(profile.id)")
                }
            }

            Spacer()

            if let todayContributionCount = profile.todayContributionCount {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(todayContributionCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.levelFourColor)
                    Text("today")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.secondaryText)
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
    }

    private var graph: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(verbatim: "Contributions in \(Date().gitHubYearString)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
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
                .foregroundColor(Color.primaryText)
                .accessibilityIdentifier("friends.profileBio.\(profile.id)")

            labelRow(icon: "location.circle", text: profile.location)
            labelRow(icon: "building", text: profile.company)

            HStack(spacing: 6) {
                Image(systemName: "person.2")
                    .frame(width: 12, height: 12)
                    .foregroundColor(Color.primaryText)
                Text(profile.followers)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primaryText)
                Text("followers")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
                Text("|")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
                Text(profile.following)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primaryText)
                Text("following")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
            }

            HStack {
                Spacer()
                Text(verbatim: "develop since \(profile.startYear)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
            }
        }
    }

    private func labelRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 12, height: 12)
                .foregroundColor(Color.primaryText)
            Text(" " + text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color.primaryText)
        }
    }
}
