//
//  MyFieldViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 9/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices
import MessageUI

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
    @IBOutlet weak var buttonBackgroundView: UIView!
    @IBOutlet weak var locationLogoImageView: UIImageView!
    @IBOutlet weak var mainActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshDataButtonOutlet: UIButton!
    
    let currentUser:User? = Auth.auth().currentUser
    let accessToken:String? = UserDefaults.standard.object(forKey: "AccessToken") as? String
    
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
    
    var dataCountArray:[String]?{
        didSet{
            guard let realDataCountArray = dataCountArray,
                let realCurrentUserUID = Auth.auth().currentUser?.uid,
                let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            
            guard let todayContribution = realDataCountArray.last else {return}
            self.todayContributionsCountLabel.text = todayContribution
            userDefaults.setValue(realDataCountArray.last!, forKey: "TodayContributions")
            userDefaults.synchronize()
            
            self.mainActivityIndicator.stopAnimating()
            self.refreshActivityIndicator.stopAnimating()
            self.refreshDataButtonOutlet.isHidden = false
        }
    }
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let realCurrentUserUid:String = self.currentUser?.uid else {
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            userDefaults.setValue(false, forKey: "isSigned")
            userDefaults.synchronize()
            return}
        
        guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
        userDefaults.setValue(true, forKey: "isSigned")
        userDefaults.synchronize()
        
        Database.database().reference().child("UserInfo").child(realCurrentUserUid).observeSingleEvent(of: .value) { [unowned self] (snapshot) in
            if let observeValue:[String:Any] = snapshot.value as? [String : Any] {
                Database.database().reference().child("UserInfo").child(realCurrentUserUid).observeSingleEvent(of: .value, with: { [unowned self] (snapshot) in
                    let observeValue:JSON = JSON.init(snapshot.value)
                    let gitHubID:String = observeValue["gitHubID"].stringValue
                    self.updateUserInfo(for: gitHubID)
                })
            }else{
                self.getGitHubUserInfoForNewbie()
            }
        }
        
        self.buttonBackgroundView.layer.cornerRadius = 22
        self.buttonBackgroundView.layer.shadowOpacity = 0.2
        self.buttonBackgroundView.layer.shadowRadius = 1
        self.buttonBackgroundView.layer.shadowOffset = CGSize(width: 1, height: 1)
        
        self.userProfileImageView.layer.cornerRadius = 10
        self.userProfileImageView.layer.shadowRadius = 1
        self.userProfileImageView.layer.shadowOpacity = 0.2
        self.userProfileImageView.layer.shadowOffset = CGSize(width: 1, height: 1)
        self.userProfileImageView.clipsToBounds = false
        
        self.refreshActivityIndicator.stopAnimating()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if currentUser == nil {
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            userDefaults.setValue(false, forKey: "isSigned")
            userDefaults.synchronize()
            
            let navigationController:UINavigationController = self.storyboard?.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
            self.present(navigationController, animated: false, completion: nil)
        }
        
        guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
        userDefaults.setValue(true, forKey: "isSigned")
        userDefaults.synchronize()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    @IBAction func menuButtonAction(_ sender: UIButton) {
        self.openMenuButtonActionSheet()
    }
    
    @IBAction func refreshDataButtonAction(_ sender: UIButton) {
        self.refreshDataButtonOutlet.isHidden = true
        self.refreshActivityIndicator.startAnimating()
        
        guard let realCurruntUserUid:String = self.currentUser?.uid else {return}
        Database.database().reference().child("UserInfo").child(realCurruntUserUid).observeSingleEvent(of: .value) { (snapshot) in
            guard let observeValue:[String:Any] = snapshot.value as? [String:Any],
                let gitHubID:String = observeValue["gitHubID"] as? String else {return}
            
            self.updateUserInfo(for: gitHubID)
        }
    }
    
    
    func openMenuButtonActionSheet() {
        let alert:UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //In-App 별점
        let rateGitGet:UIAlertAction = UIAlertAction(title: "Rate GITGET", style: .default) { (action) in
            SKStoreReviewController.requestReview()
        }
        
        //개발자에게 메일보내기
        let sendEmailToDeveloper:UIAlertAction = UIAlertAction(title: "Send email to GITGET", style: .default) { [unowned self] (aciton) in
            let userSystemVersion = UIDevice.current.systemVersion
            let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            
            let mailComposeViewController = self.configuredMailComposeViewController(emailAddress: "iosdeveloperkr@gmail.com", systemVersion: userSystemVersion, appVersion: userAppVersion!)
            
            if MFMailComposeViewController.canSendMail() {
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
        }
        
        let signOut:UIAlertAction = UIAlertAction(title: "Signout", style: .default) { [unowned self] (action) in
            //Firebase SignOut
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let logInViewController = storyboard.instantiateViewController(withIdentifier: "LogInViewController") as! LogInViewController
                self.present(logInViewController, animated: false, completion: nil)
                
            }catch let signOutError as Error {
                print("Error signing out: %@", signOutError)
            }
            
            //GitHub SignOut
            let sessionManager = Alamofire.SessionManager.default
            sessionManager.session.reset {
                UserDefaults.standard.setValue(nil, forKey: "GithubID")
                UserDefaults.standard.setValue(nil, forKey: "AccessToken")
                
                guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
                userDefaults.setValue(false, forKey: "isSigned")
                userDefaults.synchronize()
            }
            
        }
        
        //취소
        let cancel:UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(rateGitGet)
        alert.addAction(sendEmailToDeveloper)
        alert.addAction(signOut)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController(emailAddress:String, systemVersion:String, appVersion:String) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients([emailAddress])
        mailComposerVC.setSubject("[GITGET] Feedback for GITGET")
        mailComposerVC.setMessageBody("\nThanks for your feedback!\nKindly write your advise here. :)\n\n\n=====\niOS Version: \(systemVersion)\nApp Version: \(appVersion)\n=====", isHTML: false)
        
        return mailComposerVC
    }
    
    //최초 가입시 한번만 실행
    func getGitHubUserInfoForNewbie() {
        guard let realAccessToken = self.accessToken,
            let getAuthenticatedUserUrl:URL = URL(string:"https://api.github.com/user"),
            let realCurrentUser = self.currentUser else {return}
        let headers:HTTPHeaders = ["authorization":"Bearer \(realAccessToken)"]
        
        Alamofire.request(getAuthenticatedUserUrl, method: .get, headers: headers).responseJSON { [unowned self] (response) in
            guard let data:Data = response.data else {return}
            let userInfoJson:JSON = JSON(data:data)
            let gitHubID = userInfoJson["login"].stringValue
            
            let userInfo = ["gitHubID":gitHubID]
            
            //가져온 정보를 Firebase에 저장
            Database.database().reference().child("UserInfo").child("\(realCurrentUser.uid)").setValue(userInfo)
            
            //GitHubID를 받아서 해당 유저의 Contributions를 수집하도록 함
            //TODO:- 추후에 로그인 계정이 User인지 Corp(Team) 인지 구별하여 별도 처리하도록 함.
            //       이유는, Contributions 가져오는 주소가 다른 것으로 알고 있음. (
            //       개인: https://github.com/users{/username}/contributions
            //       단체: 개인사이트 같은 별도 뷰는 없음. 비슷한 형태는, https://github.com{/organization_name}{/repository_name}/graphs/contributors
            
            self.updateUserInfo(for: gitHubID)
        }
    }
    
    func updateUserInfo(for githubID:String) {
        guard let getUserDataURL:URL = URL(string:"https://api.github.com/users/\(githubID)") else {print("여기니")
            return}
        Alamofire.request(getUserDataURL, method: .get).responseJSON { [unowned self] (response) in
            guard let data:Data = response.data else {print("저기니 \(response.data)")
                return}
            let userInfoJson:JSON = JSON(data:data)
            let profileUrlString:String = userInfoJson["avatar_url"].stringValue
            let location:String = userInfoJson["location"].stringValue
            let bio:String = userInfoJson["bio"].stringValue
            let name:String = userInfoJson["name"].stringValue
            
            self.userProfileImageView.kf.setImage(with: URL(string:profileUrlString))
            
            if location != "" || location != nil {
                self.locationLogoImageView.isHidden = false
            }else{
                self.locationLogoImageView.isHidden = true
            }
            
            self.userLocationTextLabel.text = location
            
            self.userBioTextLabel.text = bio
            
            if name != "" || name != nil{
                self.userNameTextLabel.text = githubID
            }else{
                self.userNameTextLabel.text = name
            }
            
            self.updateContributionDatasOf(gitHubID: githubID)
        }
        
    }
    
    func updateContributionDatasOf(gitHubID:String) {
        guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(gitHubID)/contributions") else {return}
        Alamofire.request(getContributionsUrl, method: .get).responseString { [unowned self] (response) in
            switch response.result {
            case .success(let value):
                //https://github.com/users/\(username)/contributions 링크를 통해 가져온 HTML 내용 중, 필요한 정보만 추출하기
                do {
                    let htmlValue = value
                    guard let elements:Elements = try? SwiftSoup.parse(htmlValue).select("rect") else {return} //parse html_rect
                    var tempColorCodeArray:[String] = []
                    var tempDateArray:[String] = []
                    var tempDataCountArray:[String] = []
                    //color code 추출하기
                    for element:Element in elements.array() {
                        guard let hexColorCode:String = try? element.attr("fill") else {return}
                        tempColorCodeArray.append(hexColorCode)
                    }
                    self.hexColorCodesArray = tempColorCodeArray
                    
                    //date(날짜) 추출하기
                    for element:Element in elements.array() {
                        guard let date:String = try? element.attr("data-date") else {return}
                        tempDateArray.append(date)
                    }
                    self.dateArray = tempDateArray
                    
                    //data-count(contribution 수) 추출하기
                    for element:Element in elements.array() {
                        guard let dataCount:String = try? element.attr("data-count") else {return}
                        tempDataCountArray.append(dataCount)
                    }
                    self.dataCountArray = tempDataCountArray
                    
                }catch Exception.Error(let type, let result){
                    print(result, type)
                }catch{
                    print("error")
                }
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
        }
    }
    
    func openSafariViewOf(url:String) {
        guard let realURL = URL(string:url) else {return}
        let safariViewController = SFSafariViewController(url: realURL)
        safariViewController.delegate = self
        self.present(safariViewController, animated: true, completion: nil)
    }
    
}

extension MyFieldViewController:SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension MyFieldViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}



