//
//  TutorialViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

struct TutorialViewModel: TutorialViewBindable {
    let stepOneViewModel: TutorialStepViewBindable
    let stepTwoViewModel: TutorialStepViewBindable
    let stepThreeViewModel: TutorialStepViewBindable
    let stepFourViewModel: TutorialStepViewBindable
    
    init() {
        stepOneViewModel = TutorialStepViewModel(step: .one)
        stepTwoViewModel = TutorialStepViewModel(step: .two)
        stepThreeViewModel = TutorialStepViewModel(step: .three)
        stepFourViewModel = TutorialStepViewModel(step: .four)
    }
}
