//
//  WidgetSetupGuideModels.swift
//  GITGET
//
//  Created by Bo-Young PARK on 1/14/21.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

struct WidgetSetupGuideStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let imageName: String
}

enum WidgetSetupGuidePlatform {
    case iOS
    case iPadOS
    case macOS

    static var current: WidgetSetupGuidePlatform {
#if os(macOS)
        return .macOS
#elseif canImport(UIKit)
        switch UIDevice.current.userInterfaceIdiom {
        case .mac:
            return .macOS
        case .pad:
            return .iPadOS
        default:
            return .iOS
        }
#else
        return .iOS
#endif
    }

    var steps: [WidgetSetupGuideStep] {
        switch self {
        case .iOS:
            return [
                WidgetSetupGuideStep(
                    id: 1,
                    title: "Step 01",
                    description: "From the Home Screen, touch and hold a widget or an empty area until the apps jiggle. Then tap the Add Button in the upper-left corner.".localized,
                    imageName: "step_one_ios"
                ),
                WidgetSetupGuideStep(
                    id: 2,
                    title: "Step 02",
                    description: "Select or find GitGet, and tap Add Widget.".localized,
                    imageName: "step_two_ios"
                ),
                WidgetSetupGuideStep(
                    id: 3,
                    title: "Step 03",
                    description: "Tap GitGet, then fill GitHub username. In this moment, GitGet should be in active(jiggle). If not, hold a GitGet then tap 'edit widget'".localized,
                    imageName: "step_three_ios"
                ),
                WidgetSetupGuideStep(
                    id: 4,
                    title: "Step 04",
                    description: "Tap Done. You can also add your collegue’s username. Don’t forget various themes are prepared.".localized,
                    imageName: "step_four_ios"
                )
            ]
        case .iPadOS:
            return [
                WidgetSetupGuideStep(
                    id: 1,
                    title: "Step 01",
                    description: "From the Today View, touch and hold a widget or an empty area until the widgets jiggle. Then tap the Add Button in the upper-left corner.".localized,
                    imageName: "step_one_ipad"
                ),
                WidgetSetupGuideStep(
                    id: 2,
                    title: "Step 02",
                    description: "Select or find GitGet, and tap Add Widget.".localized,
                    imageName: "step_two_ipad"
                ),
                WidgetSetupGuideStep(
                    id: 3,
                    title: "Step 03",
                    description: "Tap GitGet, then fill GitHub username. In this moment, GitGet should be in active(jiggle). If not, hold a GitGet then tap 'edit widget'".localized,
                    imageName: "step_three_ipad"
                ),
                WidgetSetupGuideStep(
                    id: 4,
                    title: "Step 04",
                    description: "Tap Done. You can also add your collegue’s username. Don’t forget various themes are prepared.".localized,
                    imageName: "step_four_ipad"
                )
            ]
        case .macOS:
            return [
                WidgetSetupGuideStep(
                    id: 1,
                    title: "Step 01",
                    description: "Click the date and time in the menu bar, or swipe left with two fingers from the right edge of the trackpad.".localized,
                    imageName: "step_one_mac"
                ),
                WidgetSetupGuideStep(
                    id: 2,
                    title: "Step 02",
                    description: "Click Edit Widgets at the bottom. Then in the widget preview, move the pointer over the widget in the preview, then click the Add button. The widget’s added to the active widgets on the right.".localized,
                    imageName: "step_two_mac"
                ),
                WidgetSetupGuideStep(
                    id: 3,
                    title: "Step 03",
                    description: "In the active widgets, move the pointer over the widget (Edit Widget appears below its name), then click anywhere in the widget. The widget flips to reveal settings you can update username and theme for GitHub contributions. When you’re ready, click Done.".localized,
                    imageName: "step_three_mac"
                ),
                WidgetSetupGuideStep(
                    id: 4,
                    title: "Step 04",
                    description: "You can also add your collegue’s username. Don’t forget various themes are prepared.".localized,
                    imageName: "step_four_mac"
                )
            ]
        }
    }
}
