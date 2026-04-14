//
//  ThemeExtension.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import AppIntents
import SwiftUI

enum Theme: Int, CaseIterable {
    case unknown = 0
    case `default` = 1
    case classic = 2
    case blackAndWhite = 3
    case jejuOcean = 4
    case halloween = 5
    case warm = 6
    case fall = 7
    case freestyle = 8
    case christmas = 9
    case gitlab = 10
}

extension Theme {
    static var selectableCases: [Theme] {
        [.default, .gitlab, .classic, .blackAndWhite, .jejuOcean, .halloween, .warm, .fall, .freestyle, .christmas]
    }

    var displayName: String {
        switch self {
        case .default: return "GitHub"
        case .gitlab: return "GitLab"
        case .classic: return "Classic"
        case .blackAndWhite: return "Go"
        case .jejuOcean: return "Ocean"
        case .halloween: return "Halloween"
        case .warm: return "Warm"
        case .fall: return "Ginkgo"
        case .freestyle: return "Freestyle"
        case .christmas: return "Christmas"
        case .unknown: return "Unknown"
        }
    }
}

enum GitHubWidgetTheme: String, AppEnum {
    case `default`
    case classic
    case blackAndWhite
    case jejuOcean
    case halloween
    case warm
    case fall
    case freestyle
    case christmas

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Theme")

    static var caseDisplayRepresentations: [GitHubWidgetTheme: DisplayRepresentation] = [
        .default: "GitHub",
        .classic: "Classic",
        .blackAndWhite: "Go",
        .jejuOcean: "Ocean",
        .halloween: "Halloween",
        .warm: "Warm",
        .fall: "Ginkgo",
        .freestyle: "Freestyle",
        .christmas: "Christmas"
    ]
}

extension Theme {
    func supplyColor(by level: Contribution.Level) -> Color {
        switch level {
        case .zero: return .level0
        case .one: return levelOneColor
        case .two: return levelTwoColor
        case .three: return levelThreeColor
        case .four: return levelFourColor
        }
    }

    var levelOneColor: Color {
        switch self {
        case .default: return .default1
        case .gitlab: return .gitlab1
        case .classic: return .classic1
        case .blackAndWhite: return .blackAndWhite1
        case .jejuOcean: return .jejuOcean1
        case .halloween: return .halloween1
        case .warm: return .warm1
        case .fall: return .fall1
        case .freestyle: return .freestyle1
        case .christmas: return .christmas1
        default: return .white
        }
    }

    var levelTwoColor: Color {
        switch self {
        case .default: return .default2
        case .gitlab: return .gitlab2
        case .classic: return .classic2
        case .blackAndWhite: return .blackAndWhite2
        case .jejuOcean: return .jejuOcean2
        case .halloween: return .halloween2
        case .warm: return .warm2
        case .fall: return .fall2
        case .freestyle: return .freestyle2
        case .christmas: return .christmas2
        default: return .white
        }
    }

    var levelThreeColor: Color {
        switch self {
        case .default: return .default3
        case .gitlab: return .gitlab3
        case .classic: return .classic3
        case .blackAndWhite: return .blackAndWhite3
        case .jejuOcean: return .jejuOcean3
        case .halloween: return .halloween3
        case .warm: return .warm3
        case .fall: return .fall3
        case .freestyle: return .freestyle3
        case .christmas: return .christmas3
        default: return .white
        }
    }

    var levelFourColor: Color {
        switch self {
        case .default: return .default4
        case .gitlab: return .gitlab4
        case .classic: return .classic4
        case .blackAndWhite: return .blackAndWhite4
        case .jejuOcean: return .jejuOcean4
        case .halloween: return .halloween4
        case .warm: return .warm4
        case .fall: return .fall4
        case .freestyle: return .freestyle4
        case .christmas: return .christmas4
        default: return .white
        }
    }
}

extension GitHubWidgetTheme {
    func supplyColor(by level: Contribution.Level) -> Color {
        switch level {
        case .zero: return .level0
        case .one: return levelOneColor
        case .two: return levelTwoColor
        case .three: return levelThreeColor
        case .four: return levelFourColor
        }
    }

    var levelOneColor: Color {
        switch self {
        case .default: return .default1
        case .classic: return .classic1
        case .blackAndWhite: return .blackAndWhite1
        case .jejuOcean: return .jejuOcean1
        case .halloween: return .halloween1
        case .warm: return .warm1
        case .fall: return .fall1
        case .freestyle: return .freestyle1
        case .christmas: return .christmas1
        }
    }

    var levelTwoColor: Color {
        switch self {
        case .default: return .default2
        case .classic: return .classic2
        case .blackAndWhite: return .blackAndWhite2
        case .jejuOcean: return .jejuOcean2
        case .halloween: return .halloween2
        case .warm: return .warm2
        case .fall: return .fall2
        case .freestyle: return .freestyle2
        case .christmas: return .christmas2
        }
    }

    var levelThreeColor: Color {
        switch self {
        case .default: return .default3
        case .classic: return .classic3
        case .blackAndWhite: return .blackAndWhite3
        case .jejuOcean: return .jejuOcean3
        case .halloween: return .halloween3
        case .warm: return .warm3
        case .fall: return .fall3
        case .freestyle: return .freestyle3
        case .christmas: return .christmas3
        }
    }

    var levelFourColor: Color {
        switch self {
        case .default: return .default4
        case .classic: return .classic4
        case .blackAndWhite: return .blackAndWhite4
        case .jejuOcean: return .jejuOcean4
        case .halloween: return .halloween4
        case .warm: return .warm4
        case .fall: return .fall4
        case .freestyle: return .freestyle4
        case .christmas: return .christmas4
        }
    }
}
