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
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    //MARK:- (주석처리)Firebase configure가 간헐적으로 작동하지 않을 때가 있어서 사용했던 코드.
//    override init() {
//        DispatchQueue.main.async {
//            FirebaseApp.configure()
//        }
//    }
    
    //MARK:- Realm SchemaVersion 관리
    //Realm의 DB를 사용할 때, 애초부터 변경이 없다면 상관이 없지만, App Release 후 모델의 구조가 변경되었다면, SchemaVersion 관리를 해주어야 한다.
    //참고: 마이그레이션이란 Realm 데이터베이스 스키마에 변화가 생겼을 때 디스크에 쓰인 데이터와 새로운 스키마의 차이를 맞추는 작업입니다. 사실 아직 릴리즈 이전의 개발 중이라면 시간 절약상 굳이 사용하지 않고 앱을 지웠다가 다시 설치하는 것을 추천합니다. 단 이미 릴리즈돼서 설치된 앱의 스키마가 변경된다면 마이그레이션이 필요합니다. 스키마 변경을 한 단계 올리고 마이그레이션 내에서 어떤 작업을 할지 지정하면 됩니다. - 출처: https://academy.realm.io/kr/posts/realm-swift-live-coding-beginner/
    
    /* schemaVersion 0
     @objc dynamic var gitHubUserName:String = ""
     @objc dynamic var htmlValue:String = ""
     @objc dynamic var uuid:String = UUID().uuidString
     */
    
    /* schemaVersion 1
     @objc dynamic var gitHubUserName:String = ""
     @objc dynamic var htmlValue:String = ""
     //add nickname
     @objc dynamic var nickname:String = ""
     @objc dynamic var uuid:String = UUID().uuidString
     */
    
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
        
        //FIXME:- 하단의 noti 함수 수정 후 실행할 것
//        self.setNotification(application: application)
        
        //MARK:- Realm migration
        let migrationBlock:MigrationBlock = { (migration, oldSchemaVersion) in
            migration.enumerateObjects(ofType: Colleague.className(), { (oldObject, newObject) in
                if oldSchemaVersion < 1 {
                    newObject?["nickname"] = ""
                }
            })
            print("Migration complete.")
        }
        
        Realm.Configuration.defaultConfiguration = Realm.Configuration(schemaVersion: 1, migrationBlock: migrationBlock)
        
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

//FIXME:- Notification 설정
//(수정사항): 설정한 Noti 시간에 작동은 잘 되지만, 해당 시간에 API와 통신하여 값을 가져와야 하는데, 지금은 앱이 실행될 때 통신한 후 기다렸다가 정해진 시간에 그 데이터를 쏘는 상황
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

