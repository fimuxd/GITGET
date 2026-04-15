import SwiftUI

struct ContributionUnavailableSectionView: View {
    let members: [ContributionComparisonEntry]
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Unavailable Members")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.primaryText)

                Text("These members stay out of ranking until their contribution graph data is available.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color.secondaryText)
            }

            VStack(spacing: 10) {
                ForEach(members) { input in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
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

                            Text(input.unavailableReasonLabel)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(theme.levelFourColor)
                                .multilineTextAlignment(.trailing)
                        }

                        if let errorMessage = input.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 11, design: .monospaced))
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
