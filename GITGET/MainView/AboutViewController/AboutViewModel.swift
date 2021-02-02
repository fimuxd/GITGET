//
//  AboutViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/19/21.
//

import RxSwift
import RxCocoa

enum SettingMenu {
    case rating
    case sendMail
    case gitHub
    case linkedin
    case instagram
}

struct AboutViewModel: AboutViewBindable {
    let buttonAction: Signal<SettingMenu>
    let buttonTapped = PublishRelay<SettingMenu>()
    
    init() {
        self.buttonAction = buttonTapped
            .asSignal(onErrorSignalWith: .empty())
    }
}
