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
        
        guard let currentUserURL:URL = URL(string:"https://api.github.com/user") else {return}
        Alamofire.request(currentUserURL, method: .get).responseString { (response) in
            print(response.value)
        }
        
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
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    @IBAction func createAnAccountButtonAction(_ sender: UIButton) {
        self.openSafariViewOf(url: "https://github.com/join?source=header-home")
    }
    
    //SFSafari를 이용
    func openSafariViewOf(url:String) {
        guard let realURL = URL(string:url) else {return}
        let safariViewController = SFSafariViewController(url: realURL)
        safariViewController.delegate = self
        self.present(safariViewController, animated: true, completion: nil)
    }
}

extension LogInViewController:SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}
