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

class LogInViewController: UIViewController {

    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var githubMarkButtonOutlet: UIButton!
    @IBOutlet weak var welcomeTextLabel: UILabel!
    @IBOutlet weak var signInButtonOutlet: UIButton!
    
    
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
        self.signInGithub()
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
    func signInGithub() {
//        var credential = GitHubAuthProvider.credential(withToken: "884fd950baf8ed6f9f645e50e268d474eaed95e8")
        guard let rootDomain:URL = URL(string: "https://github.com/login/oauth/authorize") else {return}
        Alamofire.request(rootDomain, method: .get, parameters: nil, headers: nil).responseJSON { [unowned self] (response) in
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
        self.dismiss(animated: true, completion: nil)
    }
}



