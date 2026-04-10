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
