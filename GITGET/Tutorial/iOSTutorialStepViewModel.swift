//
//  iOSTutorialStepViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import RxSwift
import RxCocoa

struct iOSTutorialStepViewModel: TutorialStepViewBindable {
    let step: Signal<TutorialStep>
    
    init(step: iOSStep) {
        self.step = Observable
            .just(step)
            .asSignal(onErrorSignalWith: .empty())
    }
}
