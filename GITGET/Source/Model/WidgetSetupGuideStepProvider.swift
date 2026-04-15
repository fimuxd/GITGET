//
//  WidgetSetupGuideStepProvider.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import Foundation

struct WidgetSetupGuideStepProvider {
    let steps: [WidgetSetupGuideStep]

    init(platform: WidgetSetupGuidePlatform = .current) {
        self.steps = platform.steps
    }
}
