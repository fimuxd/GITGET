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

class SettingViewController: UIViewController {

    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var welcomeTextLabel: UILabel!
    
    let currentUser:User? = Auth.auth().currentUser
    let accessToken:String? = UserDefaults.standard.object(forKey: "AccessToken") as? String
    
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
            print("여기")
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
        Alamofire.request(getAuthenticatedUserUrl, method: .get, headers: headers).responseJSON { (response) in
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
        }
        
        Alamofire.request("https://api.github.com/user/emails", method: .get, headers: headers).responseJSON { (response) in
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
