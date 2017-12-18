//
//  AppDelegate.swift
//  GITGET
//
//  Created by Bo-Young PARK on 24/10/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import UserNotifications
import Firebase
import FirebaseAuth
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
//    override init() {
//        DispatchQueue.main.async {
//            FirebaseApp.configure()
//        }
//    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        print("//applicationDidFinishLaunchingWithOptions")
        FirebaseApp.configure()

        //MARK:- 로그인설정: 접속한 사용자가 신규가입자인지 기존가입자인지에 따라 rootViewController를 다르게 설정
        let currentUserUid = Auth.auth().currentUser?.uid
        let accessToken:String? = UserDefaults.standard.object(forKey: "AccessToken") as? String
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.tintColor = UIColor(red: 0.137, green: 0.604, blue: 0.231, alpha: 1)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
    
        guard let _ = accessToken, let _ = currentUserUid else {
            self.signOut()
            let navigationController:UINavigationController = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
            self.window?.rootViewController = navigationController
            self.window?.makeKeyAndVisible()
            
            return true
        }
        let tabBarController:UITabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        self.window?.rootViewController = tabBarController
        self.window?.makeKeyAndVisible()
        
//        self.setNotification(application: application)
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
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
    
    func signOut() {
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
    
    
}

//MARK:- Notification 설정
extension AppDelegate:UNUserNotificationCenterDelegate {
    
    func setNotification(application:UIApplication) {
        if #available(iOS 10.0, *) {
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.delegate = self
            
            notificationCenter.requestAuthorization(options: [.alert,.sound], completionHandler: { (granted, error) in
                if granted { //알림 On
                    
                    GitHubAPIManager.sharedInstance.getTodayContributionsCount(completionHandler: { (todayContributions) in
                        
                        let notificationContent = UNMutableNotificationContent()
                        notificationContent.sound = UNNotificationSound.default()
                        notificationContent.title = "Check Your Today Contributions".localized
                        
                        switch Int(todayContributions)! {
                        case 0:
                            notificationContent.body = "😔 Oh no. You don't have any commits today.".localized
                        case 1...5:
                            notificationContent.body = String(format:NSLocalizedString("👍 Good. %@ contributions today!", comment: ""),todayContributions)
                        case 6...19:
                            notificationContent.body = String(format:NSLocalizedString("👏 Well done. %@ contributions today!", comment: ""),todayContributions)
                        default:
                            notificationContent.body = String(format:NSLocalizedString("🔥 Burned out! %@ contributions today!", comment: ""),todayContributions)
                        }
                        
                        var notificationDateComponents = DateComponents()
                        notificationDateComponents.hour = 22
                        notificationDateComponents.minute = 00
                        
                        let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: notificationDateComponents, repeats: true)
                        let nightRequest:UNNotificationRequest = UNNotificationRequest(identifier: "GitGet", content: notificationContent, trigger: notificationTrigger)
                        
                        UNUserNotificationCenter.current().add(nightRequest, withCompletionHandler: { (_) in
                            UNUserNotificationCenter.current().getPendingNotificationRequests { (notificationRequests) in
                                print("///// notificationRequests.count- 8923: \n", notificationRequests.count)
                                print("///// notificationRequests detail- 8923: \n", notificationRequests)
                            }
                        })
                    })
                    
                    UserDefaults.standard.set(true, forKey: "settingAlarmOnOff")
                    
                }else{ //알림 Off
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["GitGet"])
                    UserDefaults.standard.set(false, forKey: "settingAlarmOnOff")
                }
            })

            application.registerForRemoteNotifications()
        }else{ //iOS10 미만일 경우 미지원
            //TODO:- 추후 10 이하 버전시 로컬 노티 하는 방법 알아볼 것
        }
    }
}

