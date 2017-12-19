//
//  TeamTableViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 13/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import Firebase
import Alamofire
import SwiftyJSON
import RealmSwift

class TeamTableViewController: UITableViewController {
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var addBarButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var refreshBarButtonOutlet: UIBarButtonItem!
    
    var realm: Realm!
    var colleagueObjects:Results<Colleague>!
    var notificationToken: NotificationToken!
    
    let sectionHeaderTitles:[String] = ["My Contributions".localized, "Team Contributions".localized]
    var myContributionsData:String? {
        didSet{
            guard let realMyContributionsData = myContributionsData else {return}
            self.myContributionsData = realMyContributionsData
            
            self.tableView.reloadData()
        }
    }
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK:- Realm_Init
        do {
            realm = try Realm()
        }catch{
            print("///Error: Realm \(error)")
        }
        
        
        ////MARK:- Realm_Notification 셋팅하기
        self.notificationToken = colleagueObjects?.observe({ (change) in
            print("노티가 들어옴 \(self.colleagueObjects)")
            self.tableView.reloadData()
        })
        
        //내 Contributions 가져오기
        guard let currentGitHubID = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return}
        self.getContributions(of: currentGitHubID) { (htmlValue) in
            self.myContributionsData = htmlValue
        }
        
        ////MARK:- Realm_동료 Contributions 가져오기
        self.colleagueObjects = realm.objects(Colleague.self).sorted(byKeyPath: "gitHubUserName", ascending: true)
        print(self.colleagueObjects)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionHeaderTitles.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionHeaderTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            guard let realColleague = self.colleagueObjects else {return 0}
            return realColleague.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "contributionsCell") as! CustomTableViewCell
        
        if indexPath.section == 0 {
            guard let currentGitHubID = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return cell}
            cell.contributionUserNameTextLabel.text = currentGitHubID
            
            guard let realMyContributionsData = self.myContributionsData else {return cell}
            cell.contributionsWebView.loadHTMLString(realMyContributionsData, baseURL: nil)
            
            return cell
        }else{
            guard let realColleague = self.colleagueObjects else {return cell}
            let object = realColleague[indexPath.row]
            cell.contributionUserNameTextLabel.text = object.gitHubUserName
            cell.contributionsWebView.loadHTMLString(object.htmlValue, baseURL: nil)
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0:
            return false
        default:
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do {
                try realm.write {
                    guard let realColleague = self.colleagueObjects else {return}
                    realm.delete(realColleague[indexPath.row])
                    self.tableView.reloadData()
                }
            }catch{
                print("///Error: Realm_\(error)")
            }
        }
    }
    
    
    // MARK: - Methods
    
    @IBAction func addBarButtonAction(_ sender: UIBarButtonItem) {
        self.alertForColleagueContributions(contributionToBeUpdated: nil)
    }
    
    @IBAction func refreshBarButtonAction(_ sender: UIBarButtonItem) {
        self.refreshContributions()
    }
    
    func alertForColleagueContributions(contributionToBeUpdated: Colleague?) {
        let title = "Add Colleague".localized
        let message = "Please enter your colleague's GitHub username.".localized
        let cancelButtonTitle = "Cancel".localized
        let otherButtonTitle = "Done".localized
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field for text entry.
        alertController.addTextField { textField in
            if contributionToBeUpdated != nil {
                textField.placeholder = "GitHub username only".localized
                textField.text = contributionToBeUpdated?.gitHubUserName
            }
            
        }
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil)
        
        let doneAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            let inputUserName = alertController.textFields?.first?.text
            
            self.getContributions(of: inputUserName!, { (html) in
                if contributionToBeUpdated != nil {
                    do {
                        try self.realm.write {
                            contributionToBeUpdated?.gitHubUserName = inputUserName!
                            contributionToBeUpdated?.htmlValue = html
                            print("첫번째: \(self.colleagueObjects)")
                            self.tableView.reloadData()
                        }
                    } catch {
                        print("///Error: Realm_\(error)")
                    }
                } else {
                    let newColleague = Colleague()
                    newColleague.gitHubUserName = inputUserName!
                    newColleague.htmlValue = html
                    do {
                        try self.realm.write {
                            self.realm.add(newColleague)
                            print("두번째: \(self.colleagueObjects)")
                            self.tableView.reloadData()
                        }
                    } catch {
                        print("///Error: Realm_\(error)")
                    }
                }
            })
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func refreshContributions() {
        //My Contributions 갱신
        
        guard let currentGitHubID = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return}
        self.getContributions(of: currentGitHubID) { (htmlValue) in
            self.myContributionsData = htmlValue
        }
        
        //Colleague Contributions 갱신
        for colleague in self.colleagueObjects {
            self.getContributions(of: colleague.gitHubUserName, { (html) in
                do {
                    try self.realm.write {
                        colleague.htmlValue = html
                        self.tableView.reloadData()
                    }
                } catch {
                    print("///Error: Realm_\(error)")
                }
            })
        }
    }
    
    func getContributions(of gitHubID:String, _ completionHandler: @escaping(_ htmlValue:String) -> Void) {
        guard let getMyContributionsUrl:URL = URL(string:"https://github.com/users/\(gitHubID)/contributions") else {return}
        Alamofire.request(getMyContributionsUrl, method: .get).responseString { (response) in
            switch response.result{
            case .success(let value):
                completionHandler(value)
            case .failure(let error):
                print("//에러가 발생했습니다. \(error)")
            }
        }
    }
}
