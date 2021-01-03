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
    
    var title: String {
        switch self {
        case .howToUse: return "시작하기"
        case .rating: return "별점주기"
        case .sendMail: return "문의하기"
        case .gitHub, .linkedin, .instagram: return ""
        }
    }
    
    var iconImage: UIImage {
        switch self {
        case .howToUse, .rating, .sendMail: return UIImage()
        case .gitHub: return #imageLiteral(resourceName: "logo_github")
        case .linkedin: return #imageLiteral(resourceName: "logo_linkedin")
        case .instagram: return #imageLiteral(resourceName: "logo_instagram")
        }
    }
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
