//
//  TutorialViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import Foundation
import UIKit

struct TutorialViewModel: TutorialViewBindable {
    let stepOneViewModel: TutorialStepViewBindable
    let stepTwoViewModel: TutorialStepViewBindable
    let stepThreeViewModel: TutorialStepViewBindable
    let stepFourViewModel: TutorialStepViewBindable
    
    init() {
        #if targetEnvironment(macCatalyst)
        stepOneViewModel = MacOSTutorialStepViewModel(step: .one)
        stepTwoViewModel = MacOSTutorialStepViewModel(step: .two)
        stepThreeViewModel = MacOSTutorialStepViewModel(step: .three)
        stepFourViewModel = MacOSTutorialStepViewModel(step: .four)
        #else
        stepOneViewModel = iOSTutorialStepViewModel(step: .one)
        stepTwoViewModel = iOSTutorialStepViewModel(step: .two)
        stepThreeViewModel = iOSTutorialStepViewModel(step: .three)
        stepFourViewModel = iOSTutorialStepViewModel(step: .four)
        #endif
    }
}
