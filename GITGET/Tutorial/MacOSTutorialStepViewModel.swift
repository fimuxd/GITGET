//
//  MacOSTutorialStepViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/14/21.
//

import RxSwift
import RxCocoa

struct MacOSTutorialStepViewModel: TutorialStepViewBindable {
    let step: Signal<TutorialStep>
    
    init(step: MacOSStep) {
        self.step = Observable
            .just(step)
            .asSignal(onErrorSignalWith: .empty())
    }
}
