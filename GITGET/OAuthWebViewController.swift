//
//  OAuthWebViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 9/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SafariServices
import Alamofire



class OAuthWebViewController: UIViewController {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    private let clientID:String = "99961c715dc314b74401"
    private let clientSecret:String = "7032c8432bd3a41e303a1c607d8643758316ca50"
    private let callbackURL = "https://widgetgithub.firebaseapp.com/__/auth/handler"
    
    private var accessToken:String?
    
    @IBOutlet weak var authorizationWebView: UIWebView!
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInGithub()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    func signInGithub() {
        guard let redirectURLToRequestGitHubIdentity:URL = URL(string: "https://github.com/login/oauth/authorize") else {print("왜그래")
            return}
        let parameters:Parameters = ["client_id":clientID,
                                     "client_secret":clientSecret,
                                     "redirect_uri":callbackURL,
                                     "scope":"user",
                                     "allow_signup":"false"]
        
        Alamofire.request(redirectURLToRequestGitHubIdentity, method: .get, parameters: parameters, headers: nil).responseString { [unowned self] (response) in
            switch response.result {
            case .success(let value):
                if Auth.auth().currentUser != nil {
                    self.dismiss(animated: true, completion: nil)
                }else{
                    self.authorizationWebView.loadHTMLString(value, baseURL: URL(string:"https://github.com"))
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            case .failure(let error):
                self.navigationController?.dismiss(animated: true, completion: nil)
                print("///Alamofire.request - error: ", error)
            }
        }
    }
}


extension OAuthWebViewController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked{
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            guard let realURL = request.url else {return true}
            let safariViewController = SFSafariViewController(url: realURL)
            safariViewController.delegate = self
            self.present(safariViewController, animated: true, completion: {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            })
            return false
        }
        
        guard let realURL = request.url else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            return true}
        
        //MARK:- CallbackURL(Firebase) 로 연결되었을 때 - code 추출
        if String(describing: request).contains(callbackURL) {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let callbackUrlWithCode:String = realURL.absoluteString
            guard let queryItemsForCode = URLComponents(string:callbackUrlWithCode)?.queryItems,
                let code = queryItemsForCode.filter({$0.name == "code"}).first?.value,
                let redirectURLToGetAccessToken:URL = URL(string: "https://github.com/login/oauth/access_token") else {return true}
            let parameters:Parameters = ["client_id":clientID,
                                         "client_secret":clientSecret,
                                         "code":code,
                                         "redirect_uri":callbackURL]
            
            //MARK:- 받은 code를 access_token 형태로 받기 위해 POST
            Alamofire.request(redirectURLToGetAccessToken, method: .post, parameters: parameters).responseString { [unowned self] (response) in
                switch response.result {
                case .success(let value):
                    let responseUrl:String = "https://github.com?\(value)"
                    guard let queryItemsForAccessToken = URLComponents(string:responseUrl)?.queryItems,
                        let access_Token = queryItemsForAccessToken.filter({$0.name == "access_token"}).first?.value else {return}
                    
                    //생성된 토큰을 UserDefault에 저장
                    UserDefaults.standard.set(access_Token, forKey: "AccessToken")
                    
                    //MARK:- Firebase 연동
                    let credential = GitHubAuthProvider.credential(withToken: access_Token)
                    Auth.auth().signIn(with: credential, completion: { [unowned self] (user, error) in
                        if let error = error {
                            return print("///Firebase Auth Error: \(error.localizedDescription)")
                        }
                        
                        guard let realCurrentUser = Auth.auth().currentUser else {return}
                        //기존 가입자라면 Database 덮어쓰기 없이 MyField로 바로 이동
                        Database.database().reference().queryOrdered(byChild: "UserInfo").queryEqual(toValue: "\(realCurrentUser.uid)").observeSingleEvent(of: .value, with: { (snapshot) in
                            let observeValue = snapshot.value
                            
                            if observeValue == nil {
                                let tempDic:[String:String] = ["email":"\(realCurrentUser.providerData[0].email ?? "")",
                                    "firebaseUID":"\(realCurrentUser.uid)"]
                                Database.database().reference().child("UserInfo").child("\(realCurrentUser.uid)").setValue(tempDic)
                            }
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let myFieldViewController:MyFieldViewController = storyboard.instantiateViewController(withIdentifier: "MyFieldViewController") as! MyFieldViewController
                            self.present(myFieldViewController, animated: true, completion: {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                            })
                        })
                    })
                    
                case .failure(let error):
                    print("///Alamofire.request - error: ", error)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
            }
        }
        return true
    }
}


extension OAuthWebViewController:SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}
