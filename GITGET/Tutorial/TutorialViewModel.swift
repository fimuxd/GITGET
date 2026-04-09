//
//  TutorialViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import Foundation

struct TutorialViewModel {
    let steps: [TutorialStep]

    init(platform: TutorialPlatform = .current) {
        self.steps = platform.steps
    }
}
