//
//  SettingViewController.swift
//  WidgetGithub
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

class SettingViewController: UIViewController {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var userNameTextLabel: UILabel!
    @IBOutlet weak var userLocationTextLabel: UILabel!
    @IBOutlet weak var userBioTextLabel: UILabel!
    @IBOutlet weak var todayContributionsCountLabel: UILabel!
    @IBOutlet weak var buttonBackgroundView: UIView!
    
    let currentUser:User? = Auth.auth().currentUser
    let accessToken:String? = UserDefaults.standard.object(forKey: "AccessToken") as? String
    
    var hexColorCodesArray:[String]?{
        didSet{
            guard let realHexColorCodes = hexColorCodesArray,
                let userDefaults = UserDefaults(suiteName: "group.fimuxd.TodayExtensionSharingDefaults") else {return}
            
            userDefaults.setValue(realHexColorCodes, forKey: "ContributionsDatas")
            userDefaults.synchronize()
        }
    }
    
    var dateArray:[String]?{
        didSet{
            guard let realDateArray = dateArray,
                let userDefaults = UserDefaults(suiteName: "group.fimuxd.TodayExtensionSharingDefaults") else {return}
            userDefaults.setValue(realDateArray, forKey: "ContributionsDates")
            userDefaults.synchronize()
        }
    }
    
    var dataCountArray:[String]?{
        didSet{
            guard let realDataCountArray = dataCountArray,
                let realCurrentUserUID = Auth.auth().currentUser?.uid else {return}
            
            self.todayContributionsCountLabel.text = realDataCountArray.last!
            Database.database().reference().child("UserInfo").child("\(realCurrentUserUID)").child("todayContributions").setValue(realDataCountArray.last!)
        }
    }
    
    var gitHubID:String?{
        didSet{
            guard let realGitHubID = gitHubID else {return}
            
            guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(realGitHubID)/contributions") else {return}
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
                        print(result)
                    }catch{
                        print("error")
                    }
                case .failure(let error):
                    print("///Alamofire.request - error: ", error)
                }
            }
        }
    }
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getGitHubUserInfo()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        if currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let logInViewController = storyboard.instantiateViewController(withIdentifier: "LogInViewController") as! LogInViewController
            self.present(logInViewController, animated: false, completion: nil)
        }
        
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
    
    func openMenuButtonActionSheet() {
        let alert:UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //In-App 별점
        let rateGitGet:UIAlertAction = UIAlertAction(title: "Rate GITGET", style: .default) { (action) in
            SKStoreReviewController.requestReview()
        }
        
        //GitHub 프로필 열기 (SFSafari)
        let openGitHubProfilePage:UIAlertAction = UIAlertAction(title: "Open Your GitHub Profile", style: .default) { (action) in
            Database.database().reference().child("UserInfo").child("\(self.currentUser!.uid)").child("gitHubID").observeSingleEvent(of: .value, with: { [unowned self] (snapshot) in
                let currentUserName:String = snapshot.value as! String
                print(currentUserName)
                self.openSafariViewOf(url: "https://github.com/\(currentUserName)")
            })
        }
        
        //개발자에게 메일보내기
        let sendEmailToDeveloper:UIAlertAction = UIAlertAction(title: "Send email to GITGET", style: .default) { (aciton) in
            let userSystemVersion = UIDevice.current.systemVersion
            let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            
            let mailComposeViewController = self.configuredMailComposeViewController(emailAddress: "fimuxd@gmail.com", systemVersion: userSystemVersion, appVersion: userAppVersion!)
            
            if MFMailComposeViewController.canSendMail() {
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
        }
        
        let signOut:UIAlertAction = UIAlertAction(title: "SignOut", style: .default) { (action) in
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
            
            //TODO:- GitHub API SignOut _ 이거 어케 함. 잉이잉
//            self.openSafariViewOf(url: "https://github.com/logout")
        }
        
        //취소
        let cancel:UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(rateGitGet)
        alert.addAction(openGitHubProfilePage)
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
    
    func getGitHubUserInfo() {
        guard let realAccessToken = self.accessToken,
            let getAuthenticatedUserUrl:URL = URL(string:"https://api.github.com/user"),
            let realCurrentUser = self.currentUser else {return}
        let headers:HTTPHeaders = ["authorization":"Bearer \(realAccessToken)"]
        
        Alamofire.request(getAuthenticatedUserUrl, method: .get, headers: headers).responseJSON { [unowned self] (response) in
            guard let data:Data = response.data else {return}
            let userInfoJson:JSON = JSON(data:data)
            let gitHubID = userInfoJson["login"].stringValue
            let name = userInfoJson["name"].stringValue
            let location = userInfoJson["location"].stringValue
            let email = userInfoJson["email"].stringValue
            let profileUrlString = userInfoJson["avatar_url"].stringValue
            let bio = userInfoJson["bio"].stringValue
            
            let userInfo = ["gitHubID":gitHubID,
                            "name":name,
                            "location":location,
                            "email":email,
                            "profileURL":profileUrlString,
                            "bio":bio]
            
            //가져온 정보를 Firebase에 저장
            Database.database().reference().child("UserInfo").child("\(realCurrentUser.uid)").setValue(userInfo)
            
            //GitHubID를 받아서 해당 유저의 Contributions를 수집하도록 함
            //TODO:- 추후에 로그인 계정이 User인지 Corp(Team) 인지 구별하여 별도 처리하도록 함.
            //       이유는, Contributions 가져오는 주소가 다른 것으로 알고 있음. (
            //       개인: https://github.com/users{/username}/contributions
            //       단체: 개인사이트 같은 별도 뷰는 없음. 비슷한 형태는, https://github.com{/organization_name}{/repository_name}/graphs/contributors
            self.gitHubID = gitHubID
            
            //가져온 정보를 UI에 뿌리기
            //profile_URL
            guard let profileUrl:URL = URL(string: profileUrlString),
                let imageData:Data = try? Data.init(contentsOf: profileUrl),
                let profileImage:UIImage = UIImage(data: imageData) else {return}
            
            self.userProfileImageView.image = profileImage
            self.userNameTextLabel.text = name
            self.userLocationTextLabel.text = location
            self.userBioTextLabel.text = bio
        }
        
        //이메일은 .get 주소가 달라서 별도로 수집
        Alamofire.request("https://api.github.com/user/emails", method: .get, headers: headers).responseJSON { [unowned self] (response) in
            guard let data:Data = response.data else {return}
            let userEmailsJson:JSON = JSON(data:data)
            let primaryEmail = userEmailsJson[0]["email"].stringValue
            print("여기여기여기: \(primaryEmail)")
            Database.database().reference().child("UserInfo").child("\(realCurrentUser.uid)").child("email").setValue(primaryEmail)
        }
    }
    
    func openSafariViewOf(url:String) {
        guard let realURL = URL(string:url) else {return}
        let safariViewController = SFSafariViewController(url: realURL)
        safariViewController.delegate = self
        self.present(safariViewController, animated: true, completion: nil)
    }
    
}

extension SettingViewController:SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SettingViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
