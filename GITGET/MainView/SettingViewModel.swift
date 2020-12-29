//
//  SettingViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import RxSwift
import RxCocoa
import RxDataSources

enum SettingMenu: Int {
    case howToUse
    case rating
    case sendMail
    case version
    
    var title: String {
        switch self {
        case .howToUse: return "사용법"
        case .rating: return "별점주기"
        case .sendMail: return "문의하기"
        case .version: return "버전 정보"
        }
    }
    
    var description: String {
        switch self {
        case .howToUse: return "홈스크린에 나만의 깃젯을 설정해주세요⚙️"
        case .rating: return "여러분의 응원은 개발자에게 큰 힘이 됩니다🧑🏻‍💻"
        case .sendMail: return "문제가 있으신가요? 메일로 알려주세요💌"
        case .version: return "최신 버전으로 유지해주세요✅"
        }
    }
    
    var iconImage: UIImage {
        switch self {
        case .howToUse: return #imageLiteral(resourceName: "IconHowToUse").withTintColor(.systemBlue)
        default: return UIImage()
        }
    }
}

struct SettingViewModel: SettingViewBindable {
    let disposeBag = DisposeBag()
    
    let cellData: Driver<[SettingMenu]>
    let requestRating: Signal<Void>
    let sendEmail: Signal<Void>
    let selectedRow = PublishRelay<Int>()
    
    init() {
        self.cellData = Observable
            .just([.howToUse, .rating, .sendMail, .version])
            .asDriver(onErrorJustReturn: [])
        
        self.requestRating = selectedRow
            .filter { $0 == SettingMenu.rating.rawValue }
            .map { _ in Void() }
            .asSignal(onErrorSignalWith: .empty())
            
        self.sendEmail = selectedRow
            .filter { $0 == SettingMenu.sendMail.rawValue }
            .map { _ in Void() }
            .asSignal(onErrorSignalWith: .empty())
    }
}
