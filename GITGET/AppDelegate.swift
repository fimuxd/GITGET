//
//  AppDelegate.swift
//  GITGET
//
//  Created by Bo-Young PARK on 24/10/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    override init() {
        FirebaseApp.configure()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("//applicationDidFinishLaunchingWithOptions")
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.tintColor = UIColor(red: 0.137, green: 0.604, blue: 0.231, alpha: 1)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController:UITabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        let navigationController:UINavigationController = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        let isPassOAuth:Bool = UserDefaults.standard.value(forKey: "isPassOAuth2") as? Bool ?? false
        
        if UserDefaults.standard.value(forKey: "isPassOAuth") != nil {
            UserDefaults.standard.removeObject(forKey: "isPassOAuth")
            UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.removeObject(forKey: "ContributionsDatas")
            UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.synchronize()
            //Firebase SignOut
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                
            }catch let signOutError as Error {
                print("Error signing out: %@", signOutError)
            }
            
            //GitHub API SignOut
            let sessionManager = Alamofire.SessionManager.default
            sessionManager.session.reset {
                UserDefaults.standard.setValue(nil, forKey: "AccessToken")
                
                guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
                userDefaults.setValue(false, forKey: "isSigned")
                userDefaults.setValue(nil, forKey: "GitHubID")
                userDefaults.synchronize()
            }
        }
        
        if Auth.auth().currentUser?.uid != nil && isPassOAuth == true{
            self.window?.rootViewController = tabBarController
            self.window?.makeKeyAndVisible()
        }else{
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
        }

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("//applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("//applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("//applicationWillEnterForeground")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("//applicationDidBecomeActive")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("//applicationWillTerminate")
    }
    
    
}

