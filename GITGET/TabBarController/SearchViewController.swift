//
//  SearchViewController.swift
//  GITGET
//
//  Created by Bo-Young PARK on 24/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Kingfisher

class SearchViewController: UIViewController {
    
    /********************************************/
    //MARK:-      Variation | IBOutlet          //
    /********************************************/
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var githubIDSearchResults:[String] = []
    var userInfoResults:[[String:String]] = []
    
    /********************************************/
    //MARK:-            LifeCycle               //
    /********************************************/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBar.showsCancelButton = true
        self.resultTableView.isHidden = true
        self.activityIndicator.stopAnimating()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    
    /********************************************/
    //MARK:-       Methods | IBAction           //
    /********************************************/
    
    
    
}

extension SearchViewController:UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.activityIndicator.startAnimating()
        
        guard let realText:String = searchBar.text,
            let searchUsersURL:URL = URL(string:"https://api.github.com/search/users?q=\(realText)&client_id=99961c715dc314b74401&client_secret=7032c8432bd3a41e303a1c607d8643758316ca50") else {return}

        DispatchQueue.global(qos: .userInitiated).async {
            Alamofire.request(searchUsersURL, method: .get).responseJSON {[unowned self] (response) in
                guard let data:Data = response.data else {return}
                let resultJson:JSON = JSON(data:data)
                let resultItem:[JSON] = resultJson["items"].arrayValue
                
                for index in 0..<resultItem.count {
                    self.githubIDSearchResults.append(resultItem[index]["login"].stringValue)
                }
                
                for githubID in self.githubIDSearchResults {
                    guard let userInfoURL:URL = URL(string:"https://api.github.com/users/\(githubID)&client_id=99961c715dc314b74401&client_secret=7032c8432bd3a41e303a1c607d8643758316ca50") else {print("엉망")
                        return}
                    
                    Alamofire.request(userInfoURL, method: .get).responseJSON(completionHandler: { (response) in
                        guard let data:Data = response.data else {return}
                        let resultJson:JSON = JSON(data:data)
                        let gitHubID:String = resultJson["login"].stringValue
                        let profileUrl:String = resultJson["avatar_url"].stringValue
                        let bio:String = resultJson["bio"].stringValue
                        let tempDic:[String:String] = ["gitHubID":gitHubID,
                                                       "profileUrl":profileUrl,
                                                       "bio":bio]
                        
                        self.userInfoResults.append(tempDic)
                        print(resultJson)
                    })
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    print(self.userInfoResults)
                    self.resultTableView.reloadData()
                    self.activityIndicator.stopAnimating()
                    self.resultTableView.isHidden = false
                }
            }
            
        }
        
        
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.githubIDSearchResults = []
            self.userInfoResults = []
            
            self.resultTableView.reloadData()
        }
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.githubIDSearchResults = []
        self.userInfoResults = []
        
        self.resultTableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
}


extension SearchViewController:UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userInfoResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultTableViewCell", for: indexPath)
        
        if self.githubIDSearchResults.count == self.userInfoResults.count {
            guard let realProfileString:String = self.userInfoResults[indexPath.row]["profileUrl"],
                let profileUrl = URL(string:realProfileString) else {return cell}
            
            cell.imageView?.kf.indicatorType = .activity
            cell.imageView?.kf.indicator?.startAnimatingView()
            cell.imageView?.kf.setImage(with: profileUrl, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cache, url) in
                DispatchQueue.main.async {
                    cell.textLabel?.text = self.userInfoResults[indexPath.row]["gitHubID"]
                    cell.detailTextLabel?.text = self.userInfoResults[indexPath.row]["bio"]
                    cell.imageView?.kf.setImage(with: profileUrl, placeholder: #imageLiteral(resourceName: "GitHub-Octocat"))
                    cell.imageView?.kf.indicator?.stopAnimatingView()
                }
            })
        }
        
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

extension SearchViewController:UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
    
    
    
}
