//
//  GitHubAPIManager.swift
//  GITGET
//
//  Created by Bo-Young PARK on 30/11/2017.
//  Copyright © 2017 Bo-Young PARK. All rights reserved.
//

import Foundation
import Firebase
import Alamofire
import SwiftyJSON
import SwiftSoup

class GitHubAPIManager {
    static let sharedInstance = GitHubAPIManager()
    
    //OAuth 관련 데이터들 plist에서 불러오기
    //OAuth 관련 GITGET App의 clientID 및 secret 등은 노출되어선 안되므로, plist 파일에 별도 저장하고 .gitIgnore 하는 방식으로 처리한다.
    func loadOauthDatas() -> [String:String] {
        guard let path = Bundle.main.path(forResource: "OAuthClientDatas", ofType: "plist"),
            let oAuthDatas = NSDictionary(contentsOfFile: path) as? [String:String] else {return [:]}
        
        return oAuthDatas
    }
    
    func isNewbie(_ uid:String?) -> Bool {
        guard let currentUserUid:String = Auth.auth().currentUser?.uid else {return true}
        if currentUserUid == uid {
            return false
        }else{
            return true
        }
    }
    
    //GitHub API를 통해 데이터 불러오기
    //1. 현재 유저의 GitHubID
    func getCurrentGitHubID(completionHandler: @escaping (_ gitHubID:String) -> Void) {
        guard let currentUserUid:String = Auth.auth().currentUser?.uid else {print("//해당 UID에 해당하는 유저가 없습니다."); return}
        Database.database().reference().child("UserInfo").child("\(currentUserUid)").child("gitHubID").observeSingleEvent(of: .value) { (snapshot) in
            guard let realGitHubID:String = snapshot.value as? String else {print("//해당 UID에 해당하는 유저가 없습니다."); return}
            
            UserDefaults.standard.setValue(realGitHubID, forKey: "GitHubID")
            completionHandler(realGitHubID)
        }
    }
    
    //2. 기본 userProfile 데이터
    func getCurrentUserDatas(completionHandler: @escaping (_ userDatas:[String:String]) -> Void) {
        self.getCurrentGitHubID { (realID) in
            guard let getCurrentUserDataUrl:URL = URL(string: "https://api.github.com/users/\(realID)"),
                let accessToken:String = UserDefaults.standard.value(forKey: "AccessToken") as? String else {return}
            
            let parameter:Parameters = ["Authorization":"Bearer \(accessToken)"]
            Alamofire.request(getCurrentUserDataUrl, method: .get, parameters:parameter).responseJSON(completionHandler: { (response) in
                guard let data:Data = response.data else {return}
                let json:JSON = JSON(data:data)
                
                let name:String = json["name"].stringValue
                let email:String = json["email"].stringValue
                let bio:String = json["bio"].stringValue
                let url:String = json["blog"].stringValue
                let company:String = json["company"].stringValue
                let location:String = json["location"].stringValue
                let profileImageUrl:String = json["avatar_url"].stringValue
                
                let userDatas:[String:String] = ["name":name,
                                               "email":email,
                                               "bio":bio,
                                               "url":url,
                                               "company":company,
                                               "location":location,
                                               "profileImageUrl":profileImageUrl]
                completionHandler(userDatas)
            })
        }
    }
    
    //3. Today Contributions Count
    func getTodayContributionsCount(gitHubID:String, completionHandler: @escaping(_ todayContributionsCount: String) -> Void) {
        guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(gitHubID)/contributions") else {return}
        
        Alamofire.request(getContributionsUrl, method: .get).responseString {(response) in
            switch response.result {
            case .success(let value):
                do{
                    let htmlValue = value
                    guard let elements:Elements = try? SwiftSoup.parse(htmlValue).select("rect") else {return}
                    var tempArray:[String] = []
                    
                    for element:Element in elements.array() {
                        guard let dataCount:String = try? element.attr("data-count") else {return}
                        tempArray.append(dataCount)
                    }
                    
                    guard let todayContributionsCount:String = tempArray.last else {return}
                    
                    completionHandler(todayContributionsCount)
                }
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
        }
    }
    
    //4. Contributions HexColorCode Array
    func getContributionsColorCodeArray(gitHubID:String, completionHandler: @escaping(_ contributionsHexColorCodeArray: [String]) -> Void) {
        guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(gitHubID)/contributions") else {return}
        
        Alamofire.request(getContributionsUrl, method: .get).responseString {(response) in
            switch response.result {
            case .success(let value):
                do{
                    let htmlValue = value
                    guard let elements:Elements = try? SwiftSoup.parse(htmlValue).select("rect") else {return}
                    var tempArray:[String] = []
                    
                    for element:Element in elements.array() {
                        guard let contributionsHexColorCode:String = try? element.attr("fill") else {return}
                        tempArray.append(contributionsHexColorCode)
                    }
                    
                    let contributionsHexColorCodeArray:[String] = tempArray
                    
                    print("//GitHubAPIManager: \(contributionsHexColorCodeArray)")
                    completionHandler(contributionsHexColorCodeArray)
                }
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
        }
    }
    
    //5. Contributions Date Array
    func getContributionsDateArray(gitHubID:String, completionHandler: @escaping(_ contributionsDateArray: [String]) -> Void) {
        guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(gitHubID)/contributions") else {return}
        
        Alamofire.request(getContributionsUrl, method: .get).responseString {(response) in
            switch response.result {
            case .success(let value):
                do{
                    let htmlValue = value
                    guard let elements:Elements = try? SwiftSoup.parse(htmlValue).select("rect") else {return}
                    var tempArray:[String] = []
                    
                    for element:Element in elements.array() {
                        guard let contributionsDate:String = try? element.attr("data-count") else {return}
                        tempArray.append(contributionsDate)
                    }
                    
                    let contributionsDateArray:[String] = tempArray
                    
                    print("//GitHubAPIManager: \(contributionsDateArray)")
                    completionHandler(contributionsDateArray)
                }
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
        }
    }
    
}
