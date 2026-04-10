import Foundation

enum UITestSupport {
    static let launchArgument = "-ui-testing"
    private static let scenarioKey = "UITEST_SCENARIO"

    enum Scenario: String {
        case none
        case loadingFriend
        case friendStates
        case greenFriend
    }

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var isPreviewingExternalFlows: Bool {
        isEnabled
    }

    static var scenario: Scenario {
        guard isEnabled else { return .none }
        let rawValue = ProcessInfo.processInfo.environment[scenarioKey] ?? Scenario.none.rawValue
        return Scenario(rawValue: rawValue) ?? .none
    }

    static func seededProfiles() -> [ContributionProfile] {
        switch scenario {
        case .none:
            return []
        case .loadingFriend:
            return [makeProfile(for: ContributionAccount(provider: .github, username: "loading-friend"))]
        case .friendStates:
            return [
                makeProfile(for: ContributionAccount(provider: .github, username: "error-friend")),
                makeProfile(for: ContributionAccount(provider: .github, username: "graph-error-friend")),
                makeProfile(for: ContributionAccount(provider: .github, username: "green-friend")),
            ]
        case .greenFriend:
            return [makeProfile(for: ContributionAccount(provider: .github, username: "green-friend"))]
        }
    }

    static func makeProfile(for account: ContributionAccount) -> ContributionProfile {
        switch normalizedUsername(from: account) {
        case "loading-friend":
            return ContributionProfile(
                account: account,
                user: nil,
                contributions: [],
                isLoading: true,
                errorMessage: nil
            )

        case "error-friend":
            return ContributionProfile(
                account: account,
                user: nil,
                contributions: [],
                isLoading: false,
                errorMessage: "Account not found or currently unavailable."
            )

        case "graph-error-friend":
            return ContributionProfile(
                account: account,
                user: mockUser(for: account, normalizedUsername: normalizedUsername(from: account)),
                contributions: [],
                isLoading: false,
                errorMessage: "Could not load contribution graph."
            )

        default:
            return ContributionProfile(
                account: account,
                user: mockUser(for: account, normalizedUsername: normalizedUsername(from: account)),
                contributions: mockContributions(),
                isLoading: false,
                errorMessage: nil
            )
        }
    }

    private static func mockUser(for account: ContributionAccount, normalizedUsername: String) -> User {
        let displayName = normalizedUsername
            .split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")

        return User(
            login: normalizedUsername,
            name: displayName.isEmpty ? account.username : displayName,
            profileImageURL: nil,
            bio: "UI test profile for \(account.provider.title)",
            location: account.provider == .github ? "Seoul" : "Tokyo",
            company: account.serverOrigin ?? account.provider.title,
            followers: 128,
            following: 32,
            createdAt: Calendar.current.date(from: DateComponents(year: 2021, month: 4, day: 10))
        )
    }

    private static func mockContributions() -> [Contribution] {
        let calendar = Calendar.gitHubUTC
        let today = calendar.startOfDay(for: Date())
        let counts = [0, 1, 4, 2, 0, 3, 5, 1, 0, 2, 4, 0, 3, 1]

        return counts.enumerated().compactMap { index, count in
            guard let date = calendar.date(byAdding: .day, value: -(counts.count - index - 1), to: today) else {
                return nil
            }

            return Contribution(
                date: date,
                count: count,
                level: level(for: count)
            )
        }
    }

    private static func level(for count: Int) -> Contribution.Level {
        switch count {
        case ..<1:
            return .zero
        case 1:
            return .one
        case 2 ... 3:
            return .two
        case 4:
            return .three
        default:
            return .four
        }
    }

    private static func normalizedUsername(from account: ContributionAccount) -> String {
        account.username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

enum UITestPreviewSheet: Identifiable {
    case review
    case mail
    case browser(title: String, url: String)

    var id: String {
        switch self {
        case .review:
            return "review"
        case .mail:
            return "mail"
        case .browser(let title, _):
            return "browser-\(title)"
        }
    }

    var title: String {
        switch self {
        case .review:
            return "Review Request"
        case .mail:
            return "Mail Composer"
        case .browser(let title, _):
            return title
        }
    }

    var message: String {
        switch self {
        case .review:
            return "The App Store review prompt would be requested here."
        case .mail:
            return "The support mail composer would be presented here."
        case .browser(_, let url):
            return url
        }
    }
}
