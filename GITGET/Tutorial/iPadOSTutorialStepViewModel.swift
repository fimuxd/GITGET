//
//  iPadOSTutorialStepViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 2021/02/10.
//

import RxSwift
import RxCocoa

struct iPadOSTutorialStepViewModel: TutorialStepViewBindable {
    let step: Signal<TutorialStep>
    
    init(step: iPadOSStep) {
        self.step = Observable
            .just(step)
            .asSignal(onErrorSignalWith: .empty())
    }
}

