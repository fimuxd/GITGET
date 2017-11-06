//
//  LogInViewController.swift
//  WidgetGithub
//
//  Created by Bo-Young PARK on 25/10/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import FirebaseAuth
import SafariServices
import Alamofire

private let clientID:String = "99961c715dc314b74401"
private let clientSecret:String = "7032c8432bd3a41e303a1c607d8643758316ca50"
private let callbackURLScheme = "https://widgetgithub.firebaseapp.com/__/auth/handler"

class LogInViewController: UIViewController {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var githubMarkButtonOutlet: UIButton!
    @IBOutlet weak var welcomeTextLabel: UILabel!
    @IBOutlet weak var signInButtonOutlet: UIButton!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private let oAuthLoginURL = URL(string: "https://github.com/login/oauth/authorize?client_id=\(clientID)&redirect_uri=\(callbackURLScheme)")
    private let requestLogInURL = URL(string: "https://github.com/login")
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.signInButtonOutlet.layer.cornerRadius = 5
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    @IBAction func githubMarkButtonAction(_ sender: UIButton) {
        self.openSafariViewOf(url: "https://github.com")
    }
    
    @IBAction func signInButtonAction(_ sender: UIButton) {
//        self.openSafariViewOf(url: "https://github.com/login")
        signInGithub()
    }
    
    @IBAction func createAnAccountButtonAction(_ sender: UIButton) {
        self.openSafariViewOf(url: "https://github.com/join?source=header-home")
    }
    
    //In-App WebView 정의
    func openSafariViewOf(url:String) {
        guard let realURL = URL(string:url) else {return}
        
        let safariViewController = SFSafariViewController(url: realURL)
        safariViewController.delegate = self
        self.present(safariViewController, animated: true, completion: nil)
    }
    
    //Github OAuth SignIn
    func redirectToRequestGitHubIdentify() {
        guard let realDomain:URL = oAuthLoginURL else {return}
        Alamofire.request(realDomain, method: .get, headers: nil).responseString { (response) in
            switch response.result {
            case .success(let value):
                print("///Alamofire.request - response: ", value)
                
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
            
        }
    }
    
    
    func signInGithub() {
        //        var credential = GitHubAuthProvider.credential(withToken: "884fd950baf8ed6f9f645e50e268d474eaed95e8")
        guard let rootDomain:URL = URL(string: "https://github.com/settings/connections/applications/\(clientID)") else {return}
        let headers = [
            "authorization": "Basic ZmltdXhkQGdtYWlsLmNvbTpIMzNzb28wOSE1",
            "cache-control": "no-cache",
            "postman-token": "7d212748-ae10-a1ed-ccc3-c82975eecc5f"
        ]
        
        Alamofire.request(rootDomain, method: .get, parameters: nil, headers: headers).responseString { (response) in
            switch response.result {
            case .success(let value):
                print("///Alamofire.request - response: ", value)
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
                
            }
        }
    }
    
}

extension LogInViewController:SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.redirectToRequestGitHubIdentify()
        self.signInGithub()
        self.dismiss(animated: true, completion: nil)
    }
}
