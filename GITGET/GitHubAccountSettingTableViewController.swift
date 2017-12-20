//
//  GitHubAccountSettingTableViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 04/12/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit

class GitHubAccountSettingTableViewController: UITableViewController {
    
    let sectionHeadTitleData:[String] = ["Profile".localized, "Starred Repositories".localized]
    var repositoriesDatas:[[String:Any]]? {
        didSet{
            guard let realRepositoriesDatas = repositoriesDatas else {return}
            repositoriesDatas = realRepositoriesDatas
            
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        GitHubAPIManager.sharedInstance.getStaredRepositoriesDataArray { (repositoryData) in
            self.repositoriesDatas = repositoryData
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionHeadTitleData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 6
        case 1:
            guard let realRepositoriesDatas = repositoriesDatas else {return 0}
            return realRepositoriesDatas.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionHeadTitleData[section]
    }
    
//    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        return "Modified contents will be synced with GitHub except Email."
//    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let modifiableCell:CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "modifiableCell") as! CustomTableViewCell
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        switch indexPath.section {
        case 0:
            let cellTitles:[String] = ["Name".localized, "Email".localized, "Bio".localized, "URL".localized, "Company".localized, "Location".localized]
            modifiableCell.modifiableTitleLabel.text = cellTitles[indexPath.row]
            
            GitHubAPIManager.sharedInstance.getCurrentUserDatas(completionHandler: { (userDatas) in
                let name:String? = userDatas["name"]
                let email:String? = userDatas["email"]
                let bio:String? = userDatas["bio"]
                let url:String? = userDatas["url"]
                let company:String? = userDatas["company"]
                let location:String? = userDatas["location"]
                var tempUserDataArray:[String?] = [name, email, bio, url, company, location]
                
                DispatchQueue.main.async {
                    modifiableCell.modifiableTextField.text = tempUserDataArray[indexPath.row]
                }
                
//                if indexPath.row == 1 { //이메일 셀은 내용 수정 불가
                    modifiableCell.modifiableTextField.isUserInteractionEnabled = false
//                }
            })
            
            return modifiableCell
        case 1:
            guard let realRepositoriesDatas = repositoriesDatas,
                let currentGitHubID:String? = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return cell}
            
            let repositoryName = realRepositoriesDatas[indexPath.row]["name"] as? String ?? ""
            let repositoryDescription = realRepositoriesDatas[indexPath.row]["description"] as? String ?? ""
            let repositoryFullName = realRepositoriesDatas[indexPath.row]["fullName"] as? String ?? ""
            let repositoryowner = realRepositoriesDatas[indexPath.row]["owner"] as? String ?? ""
            
            if currentGitHubID != repositoryowner {
                cell.textLabel?.text = repositoryFullName
            }else{
                cell.textLabel?.text = realRepositoriesDatas[indexPath.row]["name"] as? String ?? ""
            }
            
            cell.detailTextLabel?.text = realRepositoriesDatas[indexPath.row]["description"] as? String ?? ""
            
            return cell
        default:
            return cell
        }
        
    }
    
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
//    @IBAction func doneButtonAction(_ sender: UIBarButtonItem) {
//        //키보드 내려가는 것 실행 (delegate)
//        self.view.endEditing(true)
//
//        //TODO:- 텍스트 필드상의 내용을 GitHub API 에 POST
//
//    }
    
    
}

extension GitHubAccountSettingTableViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        <#code#>
//    }
}

