//
//  SettingTableViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 30/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import Alamofire
import Kingfisher

class SettingTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.register(UINib.init(nibName: "ProfileTableViewCell", bundle: nil), forCellReuseIdentifier: "profileCell")
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: "detailCell")
        awakeFromNib()
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "My GitHub Account"
        case 1:
            return "About GITGET"
        case 2:
            return "Signout"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let profileCell:ProfileTableViewCell = tableView.dequeueReusableCell(withIdentifier: "profileCell") as! ProfileTableViewCell
        let detailCell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "detailCell") as! UITableViewCell
        
        switch indexPath.section {
        case 0: //My GitHub Account
            GitHubAPIManager.sharedInstance.getCurrentUserDatas(completionHandler: { (userData) in
                guard let profileUrlString = userData["profileImageUrl"],
                    let name = userData["name"] else {return}
                profileCell.profileImageView.kf.setImage(with: URL(string:profileUrlString), completionHandler: { (image, error, cache, url) in
                    DispatchQueue.main.async {
                        profileCell.titleLabel.text = name
                        profileCell.setNeedsLayout()
                    }
                })
            })
            return profileCell
            
        case 1:
            let titleList:[String] = ["Tutorial", "Rate GITGET", "Send email to GITGET"]
            detailCell.textLabel?.text = titleList[indexPath.row]
    
            return detailCell
        case 2:
            detailCell.textLabel?.text = "Signout"
            detailCell.textLabel?.textColor = .red
            return detailCell
        default:
            return detailCell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return 44
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

}
