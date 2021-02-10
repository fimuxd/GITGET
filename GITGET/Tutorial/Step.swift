//
//  Step.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/14/21.
//

import UIKit

protocol TutorialStep {
    var title: String { get }
    var description: String { get }
    var image: UIImage { get }
}

enum iOSStep: TutorialStep {
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
        case .one: return "From the Home Screen, touch and hold a widget or an empty area until the apps jiggle. Then tap the Add Button in the upper-left corner.".localized
        case .two: return "Select or find GitGet, and tap Add Widget.".localized
        case .three: return "Tap GitGet, then fill GitHub username. In this moment, GitGet should be in active(jiggle). If not, hold a GitGet then tap 'edit widget'".localized
        case .four: return "Tap Done. You can also add your collegue’s username. Don’t forget various themes are prepared.".localized
        }
    }
    
    var image: UIImage {
        switch self {
        case .one: return #imageLiteral(resourceName: "step_one_ios")
        case .two: return #imageLiteral(resourceName: "step_two_ios")
        case .three: return #imageLiteral(resourceName: "step_three_ios")
        case .four: return #imageLiteral(resourceName: "step_four_ios")
        }
    }
}

enum MacOSStep: TutorialStep {
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
        case .one: return "Click the date and time in the menu bar, or swipe left with two fingers from the right edge of the trackpad.".localized
        case .two: return "Click Edit Widgets at the bottom. Then in the widget preview, move the pointer over the widget in the preview, then click the Add button. The widget’s added to the active widgets on the right.".localized
        case .three: return "In the active widgets, move the pointer over the widget (Edit Widget appears below its name), then click anywhere in the widget. The widget flips to reveal settings you can update username and theme for GitHub contributions. When you’re ready, click Done.".localized
        case .four: return "You can also add your collegue’s username. Don’t forget various themes are prepared.".localized
        }
    }
    
    var image: UIImage {
        switch self {
        case .one: return #imageLiteral(resourceName: "step_one_mac")
        case .two: return #imageLiteral(resourceName: "step_two_mac")
        case .three: return #imageLiteral(resourceName: "step_three_mac")
        case .four: return #imageLiteral(resourceName: "step_four_mac")
        }
    }
}

enum iPadOSStep: TutorialStep {
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
        case .one: return "From the Today View, touch and hold a widget or an empty area until the widgets jiggle. Then tap the Add Button in the upper-left corner.".localized
        case .two: return "Select or find GitGet, and tap Add Widget.".localized
        case .three: return "Tap GitGet, then fill GitHub username. In this moment, GitGet should be in active(jiggle). If not, hold a GitGet then tap 'edit widget'".localized
        case .four: return "Tap Done. You can also add your collegue’s username. Don’t forget various themes are prepared.".localized
        }
    }
    
    var image: UIImage {
        switch self {
        case .one: return #imageLiteral(resourceName: "step_one_ipad")
        case .two: return #imageLiteral(resourceName: "step_two_ipad")
        case .three: return #imageLiteral(resourceName: "step_three_ipad")
        case .four: return #imageLiteral(resourceName: "step_four_ipad")
        }
    }
}
