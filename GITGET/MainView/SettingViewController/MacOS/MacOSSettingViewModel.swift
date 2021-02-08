//
//  MacOSSettingViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 2021/02/02.
//

import RxSwift
import RxCocoa

struct MacOSSettingViewModel: MacOSSettingViewBindable {
    let howToUseButtonTapped = PublishRelay<Void>()
    let presentTutorialView: Driver<TutorialViewBindable>
    let buttonAction: Signal<SettingMenu>
    let buttonTapped = PublishRelay<SettingMenu>()
    
    init() {
        self.presentTutorialView = howToUseButtonTapped
            .map { _ in
                TutorialViewModel()
            }
            .asDriver(onErrorDriveWith: .empty())
        
        self.buttonAction = buttonTapped
            .asSignal(onErrorSignalWith: .empty())
    }
}

