//
//  iOSSettingViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 2021/02/02.
//

import RxSwift
import RxCocoa

struct iOSSettingViewModel: iOSSettingViewBindable {
    let howToUserButtonTapped = PublishRelay<Void>()
    let presentTutorialView: Driver<TutorialViewBindable>
    
    init() {
        self.presentTutorialView = howToUserButtonTapped
            .map { _ in
                TutorialViewModel()
            }
            .asDriver(onErrorDriveWith: .empty())
    }
}
