//
//  MyFieldViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 9/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit

import FirebaseAuth
import FirebaseDatabase

import Alamofire
import SwiftyJSON
import SwiftSoup
import Kingfisher

class MyFieldViewController: UIViewController {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var userNameTextLabel: UILabel!
    @IBOutlet weak var userLocationTextLabel: UILabel!
    @IBOutlet weak var userBioTextLabel: UILabel!
    @IBOutlet weak var todayContributionsCountLabel: UILabel!
    @IBOutlet weak var locationLogoImageView: UIImageView!
    @IBOutlet weak var mainActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshDataButtonOutlet: UIButton!
    
    var ref: DatabaseReference!
    
    let currentUser:User? = Auth.auth().currentUser
    let accessToken:String? = UserDefaults.standard.object(forKey: "AccessToken") as? String
    let currentGitHubID:String? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String
//    var isPassOAuth:Bool? = UserDefaults.standard.value(forKey: "isPassOAuth2") as? Bool
    let themeRawValue:Int? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "ThemeNameRawValue") as? Int
    
    var hexColorCodesArray:[String]?{
        didSet{
            guard let realHexColorCodes = hexColorCodesArray,
                let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            
            userDefaults.setValue(realHexColorCodes, forKey: "ContributionsDatas")
            userDefaults.synchronize()
        }
    }
    
    var dateArray:[String]?{
        didSet{
            guard let realDateArray = dateArray,
                let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            userDefaults.setValue(realDateArray, forKey: "ContributionsDates")
            userDefaults.synchronize()
        }
    }
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        /** Version Control Using Firebase */
        ref = Database.database().reference()
        
        ref = Database.database().reference()
        
        ref.child("GitgetVersion").observeSingleEvent(of: .value, with: { snapShot in
            let dic = snapShot.value as? Dictionary<String, AnyObject>
            let vData = GitgetVersion()
            
            vData.force_update_message = dic!["force_update_message"] as! String
            vData.optional_update_message = dic!["optional_update_message"] as! String
            vData.lastest_version_code = dic!["lastest_version_code"] as! String
            vData.lastest_version_name = dic!["lastest_version_name"] as! String
            vData.minimum_version_code = dic!["minimum_version_code"] as! String
            vData.minimum_version_name = dic!["minimum_version_name"] as! String
            
            self.checkUpdateVersion(dbdata: vData)
        })

        guard let realCurrentUserUid:String = self.currentUser?.uid,
            let realAccessToken = self.accessToken,
            let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
        
        userDefaults.setValue(true, forKey: "isSigned")
        userDefaults.synchronize()
        
        GitHubAPIManager.sharedInstance.isNewbie(uid: realCurrentUserUid, completionHandler: { (bool) in
            switch bool {
            case true: //신입이라면
                GitHubAPIManager.sharedInstance.getGitHubIDForNewbie(with: realAccessToken, by: realCurrentUserUid, completionHandler: { (gitHubID) in
                    self.updateUserInfo()
                    
                    guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
                    userDefaults.setValue(gitHubID, forKey: "GitHubID")
                    userDefaults.synchronize()
                })
            case false: //신입이 아니라면
                GitHubAPIManager.sharedInstance.getCurrentGitHubID(completionHandler: { (gitHubID) in
                    self.updateUserInfo()
                    
                    guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
                    userDefaults.setValue(gitHubID, forKey: "GitHubID")
                    userDefaults.synchronize()
                })
            }
        })
        
        guard let realGitHubID = self.currentGitHubID else {return}
        self.updateContributionDatasOf(gitHubID: realGitHubID)
            
            userProfileImageView.layer.cornerRadius = 10
            userProfileImageView.layer.shadowRadius = 1
            userProfileImageView.layer.shadowOpacity = 0.2
            userProfileImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
            userProfileImageView.clipsToBounds = false
            
            self.refreshActivityIndicator.stopAnimating()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
        
        if currentUser == nil {
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            userDefaults.setValue(false, forKey: "isSigned")
            userDefaults.setValue(nil, forKey: "GitHubID")
            userDefaults.synchronize()
            
            let navigationController:UINavigationController = self.storyboard?.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
            self.present(navigationController, animated: false, completion: nil)
        }else{
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            userDefaults.setValue(true, forKey: "isSigned")
            userDefaults.synchronize()
            
            guard let realGitHubID = self.currentGitHubID else {return}
            self.updateContributionDatasOf(gitHubID: realGitHubID)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    @IBAction func refreshDataButtonAction(_ sender: UIButton) {
        self.refreshDataButtonOutlet.isHidden = true
        self.refreshActivityIndicator.startAnimating()

        self.updateUserInfo()
    }
 
    func updateUserInfo() {
        GitHubAPIManager.sharedInstance.getCurrentUserDatas { (userData) in
            guard let profileUrlString = userData["profileImageUrl"],
                let location = userData["location"],
                let bio = userData["bio"],
                let name = userData["name"],
                let githubID = userData["githubID"]
            else {return}
            
            self.userProfileImageView.kf.indicatorType = .activity
            self.userProfileImageView.kf.indicator?.startAnimatingView()
            self.userProfileImageView.kf.setImage(with: URL(string:profileUrlString), options: [.forceRefresh], completionHandler: { [unowned self] (image, error, cache, url) in
                self.userProfileImageView.kf.indicator?.stopAnimatingView()
            })
            
            if location != "" && location != nil {
                self.locationLogoImageView.isHidden = false
            }else{
                self.locationLogoImageView.isHidden = true
            }
            self.userLocationTextLabel.text = location
            self.userBioTextLabel.text = bio
            
            if name != "" && name != nil {
                self.userNameTextLabel.text = name
            }else{
                self.userNameTextLabel.text = githubID
            }

            self.refreshActivityIndicator.stopAnimating()
            self.refreshDataButtonOutlet.isHidden = false
            self.mainActivityIndicator.stopAnimating()
        }
        
        GitHubAPIManager.sharedInstance.getTodayContributionsCount { (todayContributions) in
            self.todayContributionsCountLabel.text = todayContributions
        }
        
    }
    
    func updateContributionDatasOf(gitHubID:String) {
        GitHubAPIManager.sharedInstance.getContributionsColorCodeArray(gitHubID: gitHubID, theme: ThemeName(rawValue: self.themeRawValue ?? 0)) { (contributionsColorCodeArray) in
            self.hexColorCodesArray = contributionsColorCodeArray
        }
        
        GitHubAPIManager.sharedInstance.getContributionsDateArray(gitHubID: gitHubID) { (contributionsDateArray) in
            self.dateArray = contributionsDateArray
        }
    }
    
    func checkUpdateVersion(dbdata:GitgetVersion) {
        let appLastestVersion = dbdata.lastest_version_code as String
        let appMinimumVersion = dbdata.minimum_version_code as String
        
        let infoDic         = Bundle.main.infoDictionary!
        let appBuildVersion = infoDic["CFBundleVersion"] as? String
        
        if (Int(appBuildVersion!)! < Int(appMinimumVersion)!) {
            //강제업데이트
            forceUdpateAlert(message: dbdata.force_update_message)
        }else if(Int(appBuildVersion!)! < Int(appLastestVersion)!) {
            //선택업데이트
            optionalUpdateAlert(message: dbdata.optional_update_message, version: Int(dbdata.lastest_version_code)!)
        }
    }
    
    func forceUdpateAlert(message:String) {
        
        let refreshAlert = UIAlertController(title: "UPDATE", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            print("Go to AppStore")
            // AppStore 로 가도록 연결시켜 주면 됩니다.
            if let url = URL(string: "itms-apps://itunes.apple.com/us/app/gitget/id1317170245?mt=8"),
                UIApplication.shared.canOpenURL(url)
            {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }))
        
        self.present(refreshAlert, animated: true, completion: nil)
        
    }
    
    func optionalUpdateAlert(message:String, version:Int) {
        
        let refreshAlert = UIAlertController(title: "UPDATE", message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action: UIAlertAction!) in
            print("Go to AppStore")
            
            if let url = URL(string: "itms-apps://itunes.apple.com/us/app/gitget/id1317170245?mt=8"),
                UIApplication.shared.canOpenURL(url)
            {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            print("Close Alert")
        }))
        
        self.present(refreshAlert, animated: true, completion: nil)
        
    }
}

extension String {
    var localized:String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedWithComment(comment:String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}




