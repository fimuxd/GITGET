//
//  SceneDelegate.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    let iOSViewModel = iOSSettingViewModel()
    let macOSViewModel = MacOSSettingViewModel()
    let viewModel = ContributionViewModel()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let iOS = UIDevice.current.userInterfaceIdiom == .phone
//        let iOSViewController = iOSSettingViewController()
//        let macViewController = MacOSSettingViewController()
//
//        if iOS {
//            iOSViewController.bind(iOSViewModel)
//        } else {
//            macViewController.bind(macOSViewModel)
//        }
//
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
//        window?.rootViewController = UINavigationController(rootViewController: iOS ? iOSViewController : macViewController)
        let contentView = SettingView(viewModel: viewModel)
        window?.rootViewController = UIHostingController(rootView: contentView)
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
}

