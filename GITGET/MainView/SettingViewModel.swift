//
//  SettingViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import RxSwift
import RxCocoa
import RxDataSources

enum SettingMenu {
    case howToUse
    case rating
    case sendMail
    case gitHub
    case linkedin
    case instagram
}

struct SettingViewModel: SettingViewBindable {
    let disposeBag = DisposeBag()
    
    let buttonAction: Signal<SettingMenu>
    let buttonTapped = PublishRelay<SettingMenu>()
    init() {
        buttonAction = buttonTapped
            .asSignal(onErrorSignalWith: .empty())
    }
}
