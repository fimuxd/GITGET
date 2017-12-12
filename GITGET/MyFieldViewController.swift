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
    
    let currentUser:User? = Auth.auth().currentUser
    let accessToken:String? = UserDefaults.standard.object(forKey: "AccessToken") as? String
    let currentGitHubID:String? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String
    var isPassOAuth:Bool? = UserDefaults.standard.value(forKey: "isPassOAuth2") as? Bool
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
    
}

extension String {
    var localized:String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedWithComment(comment:String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}




