//
//  SettingViewController.swift
//  WidgetGithub
//
//  Created by Bo-Young PARK on 9/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import FirebaseAuth
import SafariServices
import Alamofire

class SettingViewController: UIViewController {

    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var welcomeTextLabel: UILabel!
    
    let currentUser:User? = Auth.auth().currentUser
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let logInViewController = storyboard.instantiateViewController(withIdentifier: "LogInViewController") as! LogInViewController
            self.present(logInViewController, animated: false, completion: nil)
            
        }catch let signOutError as Error {
            print("Error signing out: %@", signOutError)
        }
        
    }
    
}
