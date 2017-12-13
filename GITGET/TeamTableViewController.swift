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

class TeamTableViewController: UITableViewController {
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var addBarButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var refreshBarButtonOutlet: UIBarButtonItem!
    
    let sectionHeaderTitleData:[String] = ["My Contributions", "Team Contributions"]
    var myContributionsData:String? {
        didSet{
            guard let realMyContributionsData = myContributionsData else {return}
            self.myContributionsData = realMyContributionsData
            
            self.tableView.reloadData()
        }
    }
    
    var myColleagueContributionsDatas:[[String:String]] = []
    
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //내 Contributions 가져오기
        guard let currentGitHubID = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return}
        self.getContributions(of: currentGitHubID) { (htmlValue) in
            self.myContributionsData = htmlValue
        }
        

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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionHeaderTitleData[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return self.myColleagueContributionsDatas.count
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
            cell.contributionUserNameTextLabel.text = self.myColleagueContributionsDatas[indexPath.row]["GitHubID"]
            cell.contributionsWebView.loadHTMLString(self.myColleagueContributionsDatas[indexPath.row]["ContributionsHTML"]!, baseURL: nil)
            
            return cell
        }

        return cell
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
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0:
            return false
        default:
            return true
        }
    }

    
    // MARK: - Methods
    
    @IBAction func addBarButtonAction(_ sender: UIBarButtonItem) {
        self.addColleagueContributions()
    }
    
    @IBAction func refreshBarButtonAction(_ sender: UIBarButtonItem) {
        guard let currentGitHubID = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return}
        self.getContributions(of: currentGitHubID) { (htmlValue) in
            self.myContributionsData = htmlValue
        }
    }
    
    func addColleagueContributions() {
        let title = NSLocalizedString("Add Colleague", comment: "")
        let message = NSLocalizedString("Please enter your colleague's GitHub username.", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        let otherButtonTitle = NSLocalizedString("Done", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field for text entry.
        alertController.addTextField { textField in
            textField.placeholder = "GitHub username only"
            
            NotificationCenter.default.addObserver(self, selector: #selector(TeamTableViewController.handleTextFieldTextDidChangeNotification(_:)), name: NSNotification.Name.UITextFieldTextDidChange, object: textField)
        }
        
        let removeTextFieldObserver: () -> Void = {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UITextFieldTextDidChange, object: alertController.textFields!.first)
        }
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in
            removeTextFieldObserver()
        }
        
        let doneAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            removeTextFieldObserver()
            
            self.tableView.reloadData()
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    @objc func handleTextFieldTextDidChangeNotification(_ notification: Notification) {
        let textField = notification.object as! UITextField
        
        if let text = textField.text {
            //TODO:- Firebase DB에 추가하기
            
            self.getContributions(of: text, {[unowned self] (htmlValue) in
                let tempDic:[String:String] = ["GitHubID":text,
                                               "ContributionsHTML":htmlValue]
                
                self.myColleagueContributionsDatas.append(tempDic)
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

    func getTeamContribution() {
        
    }

}
