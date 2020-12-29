//
//  ThemeExtension.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI
import UIKit

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
        case .classic: return .classic4
        case .blackAndWhite: return .blackAndWhite4
        case .jejuOcean: return .jejuOcean4
        case .halloween: return .halloween4
        case .warm: return .warm4
        case .fall: return .fall4
        case .freestyle: return .freestyle3
        case .christmas: return .christmas4
        default: return .white
        }
    }
}
