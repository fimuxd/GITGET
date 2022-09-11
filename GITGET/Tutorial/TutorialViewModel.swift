//
//  TutorialViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import RxCocoa

struct TutorialViewModel: TutorialViewBindable {
    let stepOneViewModel: TutorialStepViewBindable
    let stepTwoViewModel: TutorialStepViewBindable
    let stepThreeViewModel: TutorialStepViewBindable
    let stepFourViewModel: TutorialStepViewBindable
    let doneButtonTapped = PublishRelay<Void>()
    let dismiss: Signal<Void>
    
    init() {
        switch UIDevice.current.userInterfaceIdiom {
        case .mac:
            stepOneViewModel = MacOSTutorialStepViewModel(step: .one)
            stepTwoViewModel = MacOSTutorialStepViewModel(step: .two)
            stepThreeViewModel = MacOSTutorialStepViewModel(step: .three)
            stepFourViewModel = MacOSTutorialStepViewModel(step: .four)
        case .phone:
            stepOneViewModel = iOSTutorialStepViewModel(step: .one)
            stepTwoViewModel = iOSTutorialStepViewModel(step: .two)
            stepThreeViewModel = iOSTutorialStepViewModel(step: .three)
            stepFourViewModel = iOSTutorialStepViewModel(step: .four)
        case .pad:
            stepOneViewModel = iPadOSTutorialStepViewModel(step: .one)
            stepTwoViewModel = iPadOSTutorialStepViewModel(step: .two)
            stepThreeViewModel = iPadOSTutorialStepViewModel(step: .three)
            stepFourViewModel = iPadOSTutorialStepViewModel(step: .four)
        default:
            fatalError()
        }
        
        self.dismiss = doneButtonTapped
            .asSignal(onErrorSignalWith: .empty())
    }
}
