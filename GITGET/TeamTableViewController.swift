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
//import SwiftReorder
import Toaster

class TeamTableViewController: UITableViewController {
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    @IBOutlet weak var addBarButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var editBarButtonOutlet: UIBarButtonItem!
    
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
        
        //MARK:- Realm_Notification 셋팅하기
        self.notificationToken = colleagueObjects?.observe({ (change) in
            self.tableView.reloadData()
        })
        
        //내 Contributions 가져오기
        guard let currentGitHubID = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return}
        self.getContributions(of: currentGitHubID) { (htmlValue) in
            self.myContributionsData = htmlValue
        }
        
        ////MARK:- Realm_동료 Contributions 가져오기
        self.colleagueObjects = realm.objects(Colleague.self)
//        sorted(byKeyPath: "gitHubUserName", ascending: true)
        
        //스크롤 다운 하면 리프레시
        self.refreshControl?.addTarget(self, action: #selector(TeamTableViewController.refreshContributions(_:)), for: .valueChanged)
        
        //TODO:- Drag&Drop(LongPressGesture)로 셀 위치 옮기는 module 사용을 위한 delegate 설정
//        self.tableView.reorder.delegate = self
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    // MARK: - Table view data source
    
    //섹션개수 설정
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionHeaderTitles.count
    }
    
    //섹션헤더 설정
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionHeaderTitles[section]
    }
    
    //섹션별 로우개수 설정
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
    
    //각 로우별 셀에 대한 설정
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:CustomTableViewCell = tableView.dequeueReusableCell(withIdentifier: "contributionsCell") as! CustomTableViewCell
        
        
        if indexPath.section == 0 {
            guard let currentGitHubID = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults")?.value(forKey: "GitHubID") as? String else {return cell}
            cell.contributionUserNameTextLabel.text = currentGitHubID
            
            guard let realMyContributionsData = self.myContributionsData else {return cell}
            cell.contributionsWebView.loadHTMLString(realMyContributionsData, baseURL: nil)
            cell.contributionNicknameTextLabel.isHidden = true
            cell.contributionEditNicknameButtonOutlet.isHidden = true
            
            return cell
        }else{
            //TODO:- Reodering Cells
//            if let spacer = tableView.reorder.spacerCell(for: indexPath) {
//                return spacer
//            }

            cell.delegate = self
            
            guard let realColleague = self.colleagueObjects else {return cell}
            let object = realColleague[indexPath.row]
            cell.contributionUserNameTextLabel.text = object.gitHubUserName
            cell.contributionNicknameTextLabel.text = object.nickname
            cell.contributionsWebView.loadHTMLString(object.htmlValue, baseURL: nil)
            cell.indexPathRow = indexPath.row
            cell.contributionNicknameTextLabel.isHidden = false
            cell.contributionEditNicknameButtonOutlet.isHidden = false
            
            return cell
        }
    }
    
    //셀의 높이 설정
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
    //셀 삭제/수정 가능여부 설정
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0:
            return false
        default:
            return true
        }
    }
    
    //셀 삭제/수정시 데이터 핸들링
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
    
    //셀 수정할 동안 들여쓰기? 여부 설정
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - Methods
    
    //IBAction 을 통한 수정/추가
    @IBAction func editBarButtonAction(_ sender: UIBarButtonItem) {
        self.tableView.isEditing = true
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(TeamTableViewController.editingCancelled(_:)))
    }
    
    @IBAction func addBarButtonAction(_ sender: UIBarButtonItem) {
        self.alertForAddColleagueContributions(contributionToBeUpdated: nil)
    }
    
    //Selector 를 통한 수정/수정취소/추가
    @objc func editColleagues(_ sender: UIBarButtonItem) {
        self.tableView.isEditing = true
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(TeamTableViewController.editingCancelled(_:)))
    }
    
    @objc func editingCancelled(_ sender: UIBarButtonItem) {
        self.tableView.isEditing = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit".localized, style: .plain, target: self, action: #selector(TeamTableViewController.editColleagues(_:)))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(TeamTableViewController.addColleagues(_:)))
    }
    
    @objc func addColleagues(_ sender: UIBarButtonItem) {
        self.alertForAddColleagueContributions(contributionToBeUpdated: nil)
    }
    
    //추가 시 Alert
    func alertForAddColleagueContributions(contributionToBeUpdated: Colleague?) {
        let title = "Add Colleague".localized
        let message = "Please enter your colleague's GitHub username.".localized
        let cancelButtonTitle = "Cancel".localized
        let otherButtonTitle = "Done".localized
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field for text entry.
        alertController.addTextField { textField in
            textField.placeholder = "GitHub username only".localized
        }
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil)
        
        let doneAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            guard let inputUserName = alertController.textFields?.first?.text else {return}
            let checkExistColleague = self.colleagueObjects.map({ (colleagueData) -> String in
                return colleagueData.gitHubUserName
            }).sorted()
            
            if !checkExistColleague.contains(inputUserName) {
                self.getContributions(of: inputUserName, { (html) in
                    switch html.contains("Not Found") {
                    case true:
                        Toast.init(text: String(format:NSLocalizedString("'%@' is invalid username.", comment: ""),inputUserName)).show()
                    case false:
                        if contributionToBeUpdated != nil {
                            do {
                                try self.realm.write {
                                    contributionToBeUpdated?.gitHubUserName = inputUserName
                                    contributionToBeUpdated?.htmlValue = html
                                    
                                    self.tableView.reloadData()
                                }
                            } catch {
                                print("///Error: Realm_\(error)")
                            }
                        } else {
                            let newColleague = Colleague()
                            newColleague.gitHubUserName = inputUserName
                            newColleague.htmlValue = html
                            do {
                                try self.realm.write {
                                    self.realm.add(newColleague)
                                    self.tableView.reloadData()
                                }
                            } catch {
                                print("///Error: Realm_\(error)")
                            }
                        }
                        Toast.init(text: String(format:NSLocalizedString("'%@' is added.", comment: ""),inputUserName)).show()
                    }
                })
            }else{
                Toast.init(text: String(format:NSLocalizedString("'%@' is already exist.", comment: ""),inputUserName)).show()
            }
        }
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func refreshContributions(_ sender:UIRefreshControl) {
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
                        self.refreshControl?.endRefreshing()
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

//MARK:- CustomTableViewCellDelegate
extension TeamTableViewController:CustomTableViewCellDelegate {
    func contributionEditNicknameButtonTapped(at indexPathRow: Int) {
        self.alertForEditColleagueNickname(indexPathRow)
    }
    
    func alertForEditColleagueNickname(_ indexPathRow:Int) {
        let title = "Edit colleague's name".localized
        let message = "Please enter your colleague's nickname.".localized
        let cancelButtonTitle = "Cancel".localized
        let otherButtonTitle = "Done".localized
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // Add the text field for text entry.
        alertController.addTextField { textField in
            if self.colleagueObjects[indexPathRow].nickname != "" {
                textField.text = self.colleagueObjects[indexPathRow].nickname
            }
            textField.placeholder = "Colleague's nickname".localized
        }
        
        // Create the actions.
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel, handler: nil)
        
        let doneAction = UIAlertAction(title: otherButtonTitle, style: .default) { _ in
            let inputNickname = alertController.textFields?.first?.text
            do {
                try self.realm.write {
                    self.colleagueObjects[indexPathRow].nickname = inputNickname ?? ""
                    self.tableView.reloadData()
                }
            } catch {
                print("///Error: Realm_\(error)")
            }
            
        }
        
        
        // Add the actions.
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }
}

//TODO:- Drag&Drop(LongPressGesture)를 이용한 Cell 위치 이동
//extension TeamTableViewController:TableViewReorderDelegate {
//    func tableView(_ tableView: UITableView, reorderRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//
//    }
//}

