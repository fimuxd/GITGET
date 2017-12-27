//
//  SettingTableViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 30/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import StoreKit
import SafariServices
import MessageUI

import Alamofire
import Kingfisher
import Firebase
import FirebaseAuth
import Toaster

class SettingTableViewController: UITableViewController {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    let sectionHeaderTitleData:[String] = ["My GitHub Account".localized, "Preferrences".localized, "About GitGet".localized, "Exit".localized]
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionHeaderTitleData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 4
        case 3:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionHeaderTitleData[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profileCell:CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "profileCell") as! CustomTableViewCell
        let detailCell:CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "detailCell") as! CustomTableViewCell
        
        if indexPath.section == 0 {
            GitHubAPIManager.sharedInstance.getCurrentUserDatas(completionHandler: { (userData) in
                guard let profileUrlString = userData["profileImageUrl"],
                    let gitHubID = userData["githubID"] else {return}
                
                profileCell.profileImageView.kf.setImage(with: URL(string:profileUrlString), completionHandler: { (image, error, cache, url) in
                    DispatchQueue.main.async {
                        
                        profileCell.profileImageView.layer.cornerRadius = profileCell.profileImageView.frame.size.height / 2
                        profileCell.profileImageView.layer.masksToBounds = true
                        
                        profileCell.profileTitleLabel.text = gitHubID
                        profileCell.setNeedsLayout()
                    }
                })
            })
            return profileCell
        }else{
            let titleList:[[String]] = [[""], ["Theme".localized], ["Tutorial".localized, "Rate GITGET".localized, "Version".localized, "Send email to GITGET".localized], ["Signout".localized]]
            detailCell.detailTitleLabel.text = titleList[indexPath.section][indexPath.row]
            detailCell.detailSubTitleLabel.text = ""
            if indexPath.section == 2 && indexPath.row == 2 {
                guard let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                    let appBuildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {return detailCell}
                Database.database().reference().child("GitgetVersion").child("lastest_version_code").observeSingleEvent(of: .value, with: { (snapshot) in
                    guard let lastestVersionCode = snapshot.value as? String else {return}
                    DispatchQueue.main.async {
                        if Int(lastestVersionCode)! > Int(appBuildVersion)! {
                            detailCell.detailSubTitleLabel.text = userAppVersion + "(Update Available)".localized
                        }else{
                            detailCell.detailSubTitleLabel.text = userAppVersion + "(The Latest Ver.)".localized
                        }
                        detailCell.setNeedsLayout()
                    }
                })
            } else if indexPath.section == 3 && indexPath.row == 0 {
                detailCell.detailTitleLabel.textColor = .red
                detailCell.accessoryType = .none
            }
            return detailCell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return 44
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let gitHubAccountSettingTableViewController:GitHubAccountSettingTableViewController = storyboard.instantiateViewController(withIdentifier: "GitHubAccountSettingTableViewController") as! GitHubAccountSettingTableViewController
            navigationController?.pushViewController(gitHubAccountSettingTableViewController, animated: true)
        case 1:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let themeTableViewController:ThemeTableViewController = storyboard.instantiateViewController(withIdentifier: "ThemeTableViewController") as! ThemeTableViewController
            navigationController?.pushViewController(themeTableViewController, animated: true)
            
        case 2:
            if indexPath.row == 0 {
                self.openTutorial()
            }else if indexPath.row == 1 {
                self.rateGitGet()
            }else if indexPath.row == 2{
                Database.database().reference().child("GitgetVersion").observeSingleEvent(of: .value, with: { snapShot in
                    guard let dic = snapShot.value as? Dictionary<String, AnyObject>,
                        let forceUpdateMessage = dic["force_update_message"] as? String,
                        let optionalUpdateMessage = dic["optional_update_message"] as? String,
                        let lastestVersionCode = dic["lastest_version_code"] as? String,
                        let lastestVersionName = dic["lastest_version_name"] as? String,
                        let minimumVersionCode = dic["minimum_version_code"] as? String,
                        let minimumVersionName = dic["minimum_version_name"] as? String else {return}
                    
                    let vData = GitgetVersion()
                    
                    vData.force_update_message = forceUpdateMessage
                    vData.optional_update_message = optionalUpdateMessage
                    vData.lastest_version_code = lastestVersionCode
                    vData.lastest_version_name = lastestVersionName
                    vData.minimum_version_code = minimumVersionCode
                    vData.minimum_version_name = minimumVersionName
                    
                    self.checkUpdateVersion(dbdata: vData)
                })
            }else if indexPath.row == 3 {
                self.sendEmailToGitGet()
            }
        case 3:
            self.signOutAction()
        default:
            break
        }
    }
    
    // MARK: - Methods
    func openTutorial() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let pageViewController:TutorialPageViewController = storyboard.instantiateViewController(withIdentifier: "TutorialPageViewController") as! TutorialPageViewController
        self.present(pageViewController, animated: true, completion: nil)
    }
    
    func rateGitGet() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }else{
            let rateGitGetUrl = URL(string: "itms-apps://itunes.apple.com/app/id1317170245?action=write-review")
            UIApplication.shared.open(rateGitGetUrl!, options: [:], completionHandler: nil)
            UIApplication.shared.canOpenURL(rateGitGetUrl!)
        }
    }
    
    func sendEmailToGitGet() {
        let userSystemVersion = UIDevice.current.systemVersion
        let userAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        let mailComposeViewController = self.configuredMailComposeViewController(emailAddress: "iosdeveloperkr@gmail.com", systemVersion: userSystemVersion, appVersion: userAppVersion!)
        
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        }
    }
    
    func signOutAction() {
        let alert:UIAlertController = UIAlertController(title: "Signout".localized, message: "Are you sure you want to Log out?".localized, preferredStyle: .alert)
        let signOut:UIAlertAction = UIAlertAction(title: "Signout".localized, style: .default) { (action) in
            //Firebase SignOut
            let firebaseAuth = Auth.auth()
            do {
                try firebaseAuth.signOut()
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let navigationViewController:UINavigationController = storyboard.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
                self.present(navigationViewController, animated: true, completion: nil)
                
            }catch let signOutError as Error {
                print("Error signing out: %@", signOutError)
            }
            
            //GitHub API SignOut
            let sessionManager = Alamofire.SessionManager.default
            sessionManager.session.reset {
                UserDefaults.standard.setValue(nil, forKey: "AccessToken")
                
                guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
                userDefaults.setValue(false, forKey: "isSigned")
                userDefaults.setValue(nil, forKey: "GitHubID")
                userDefaults.synchronize()
            }
        }
        
        //취소
        let cancel:UIAlertAction = UIAlertAction(title: "Cancel".localized, style: .cancel, handler: nil)
        
        alert.addAction(signOut)
        alert.addAction(cancel)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController(emailAddress:String, systemVersion:String, appVersion:String) -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients([emailAddress])
        mailComposerVC.setSubject("[GITGET] Feedback for GITGET")
        mailComposerVC.setMessageBody(String(format:NSLocalizedString("\nThanks for your feedback!\nKindly write your advise here. :)\n\n\n=====\niOS Version: %@\nApp Version: %@\n=====", comment: ""),systemVersion,appVersion), isHTML: false)
        
        return mailComposerVC
    }
    
    func checkUpdateVersion(dbdata:GitgetVersion) {
        let appLastestVersion = dbdata.lastest_version_code as String
        let appMinimumVersion = dbdata.minimum_version_code as String
        
        let infoDic         = Bundle.main.infoDictionary!
        let appBuildVersion = infoDic["CFBundleVersion"] as? String
        
        if (Int(appBuildVersion!)! < Int(appMinimumVersion)!) {
            //강제업데이트
            forceUdpateAlert(message: dbdata.force_update_message)
        }else if(Int(appBuildVersion!)! < Int(appLastestVersion)!) {
            //선택업데이트
            optionalUpdateAlert(message: dbdata.optional_update_message, version: Int(dbdata.lastest_version_code)!)
        }else{
            //최신버전입니다.
            Toast.init(text: "This is the latest version.".localized).show()
        }
    }
    
    func forceUdpateAlert(message:String) {
        
        let refreshAlert = UIAlertController(title: "Update Available".localized, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (action: UIAlertAction!) in
            print("Go to AppStore")
            // AppStore 로 가도록 연결시켜 주면 됩니다.
            if let url = URL(string: "itms-apps://itunes.apple.com/us/app/gitget/id1317170245?mt=8"),
                UIApplication.shared.canOpenURL(url)
            {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }))
        
        self.present(refreshAlert, animated: true, completion: nil)
        
    }
    
    func optionalUpdateAlert(message:String, version:Int) {
        
        let refreshAlert = UIAlertController(title: "Update Available".localized, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Update".localized, style: .default, handler: { (action: UIAlertAction!) in
            print("Go to AppStore")
            UserDefaults.standard.setValue(false, forKey: "isNotNowTapped")
            if let url = URL(string: "itms-apps://itunes.apple.com/us/app/gitget/id1317170245?mt=8"),
                UIApplication.shared.canOpenURL(url)
            {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
            
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Not Now".localized, style: .cancel, handler: { (action: UIAlertAction!) in
            print("Close Alert")
            Toast.init(text: "It is recommended that you update the GitGet to the latest version.".localized).show()
        }))
        
        self.present(refreshAlert, animated: true, completion: nil)
    }
}

extension SettingTableViewController:SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension SettingTableViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

