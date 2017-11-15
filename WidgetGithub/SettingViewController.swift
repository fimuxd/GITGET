//
//  SettingViewController.swift
//  WidgetGithub
//
//  Created by Bo-Young PARK on 9/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SafariServices
import Alamofire
import SwiftyJSON
import SwiftSoup

class SettingViewController: UIViewController {

    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var welcomeTextLabel: UILabel!
    @IBOutlet weak var userContributionsWebView: UIWebView!
    
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
    
    @IBAction func signOutButtonAction(_ sender: UIButton) {
        self.signOutAction()
    }
    
    func signOutAction() {
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
        self.openSafariViewOf(url: "https://github.com/logout")
        
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
            
            let userInfo = ["gitHubID":gitHubID,
                            "name":name,
                            "location":location,
                            "email":email,
                            "accessToken":realAccessToken]
            
            Database.database().reference().child("UserInfo").child("\(realCurrentUser.uid)").setValue(userInfo)
            
            UserDefaults.standard.setValue(gitHubID, forKey: "CurruntGitHubID")
            self.gitHubID = gitHubID
        }
        
        Alamofire.request("https://api.github.com/user/emails", method: .get, headers: headers).responseJSON { [unowned self] (response) in
            guard let data:Data = response.data else {return}
            let userEmailsJson:JSON = JSON(data:data)
            let primaryEmail = userEmailsJson[0]["email"].stringValue
            print("여기여기여기: \(primaryEmail)")
            Database.database().reference().child("UserInfo").child("\(realCurrentUser.uid)").child("email").setValue(primaryEmail)
        }
        }
    
    var gitHubID:String?{
        didSet{
            guard let realGitHubID = gitHubID else {return}
            self.welcomeTextLabel.text = ("\(realGitHubID)님 반갑습니다!")
            
            guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(realGitHubID)/contributions") else {return}
            Alamofire.request(getContributionsUrl, method: .get).responseString { [unowned self] (response) in
                switch response.result {
                case .success(let value):
                    self.userContributionsWebView.loadHTMLString(value, baseURL: URL(string:"https://github.com"))
                   
                    //https://github.com/users/\(username)/contributions 링크를 통해 가져온 HTML 내용 중, 필요한 정보만 추출하기
                    do {
                        let htmlValue = value
                        guard let elements:Elements = try? SwiftSoup.parse(htmlValue).select("rect") else {return} //parse html_rect
                        var tempColorCodeArray:[String] = []
                        var tempDateArray:[String] = []
                        //color code 추출하기
                        for element:Element in elements.array() {
                            guard let hexColorCode:String = try? element.attr("fill") else {return}
                            tempColorCodeArray.append(hexColorCode)
                        }
                        self.hexColorCodesArray = tempColorCodeArray
                        
                        //date 추출하기
                        for element:Element in elements.array() {
                            guard let date:String = try? element.attr("data-date") else {return}
                            tempDateArray.append(date)
                        }
                        self.dateArray = tempDateArray
                    
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
