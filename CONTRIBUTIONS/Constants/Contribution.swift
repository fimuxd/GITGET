//
//  Contribution.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import Foundation

struct Contribution {
    enum Level: Int, CaseIterable {
        case zero, one, two, three, four
    }
    
    let date: Date
    let count: Int
    let level: Level
    
    init(date: Date, count: Int, level: Level) {
        self.date = date
        self.count = count
        self.level = level
    }
}

extension Contribution.Level {

    static func random() -> Self {
        Self.allCases.randomElement()!
    }
}
