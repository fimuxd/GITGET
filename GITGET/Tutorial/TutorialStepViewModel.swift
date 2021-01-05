//
//  TutorialStepViewModel.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/4/21.
//

import RxSwift
import RxCocoa

enum Step {
    case one
    case two
    case three
    case four
    
    var title: String {
        switch self {
        case .one: return "Step 01"
        case .two: return "Step 02"
        case .three: return "Step 03"
        case .four: return "Step 04"
        }
    }
    
    var description: String {
        switch self {
        case .one: return "From the Home Screen, touch and hold a widget or an empty area until the apps jiggle. Then tap the Add Button in the upper-left corner."
        case .two: return "Select or find GitGet, and tap Add Widget."
        case .three: return "Tap GitGet, then fill GitHub username."
        case .four: return "Tap Done. You can also add your collegue’s username. Don’t forget various themes are prepared."
        }
    }
    
    var image: UIImage {
        switch self {
        case .one: return #imageLiteral(resourceName: "step_one")
        case .two: return #imageLiteral(resourceName: "step_two")
        case .three: return #imageLiteral(resourceName: "step_three")
        case .four: return #imageLiteral(resourceName: "step_four")
        }
    }
}

struct TutorialStepViewModel: TutorialStepViewBindable {
    let step: Signal<Step>
    
    init(step: Step) {
        self.step = Observable
            .just(step)
            .asSignal(onErrorSignalWith: .empty())
    }
}
