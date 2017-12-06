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
    
    func isFirstLogInForUpdate(completionHandler: @escaping(_ bool:Bool) -> Void) {
        guard let currentUserUid:String = Auth.auth().currentUser?.uid else {return (completionHandler(true))}
        Database.database().reference().child("UserInfo").child("\(currentUserUid)").child("gitHubID").observeSingleEvent(of: .value) { (snapshot) in
            guard let realGitHubID:String = snapshot.value as? String else {return completionHandler(true)}
           
            completionHandler(false)
        }
    }
    
    //GitHub API를 통해 데이터 불러오기
    //1. 현재 유저의 GitHubID
    func getCurrentGitHubID(completionHandler: @escaping (_ gitHubID:String) -> Void) {
        guard let currentUserUid:String = Auth.auth().currentUser?.uid else {print("//해당 UID에 해당하는 유저가 없습니다."); return}
        Database.database().reference().child("UserInfo").child("\(currentUserUid)").child("gitHubID").observeSingleEvent(of: .value) { (snapshot) in
            guard let realGitHubID:String = snapshot.value as? String,
                let userDefault = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {print("//해당 UID에 해당하는 유저가 없습니다."); return}
            
            userDefault.setValue(realGitHubID, forKey: "GitHubID")
            completionHandler(realGitHubID)
        }
    }
    
    //2.1 새 userData 저장
    func getGitHubIDForNewbie(with AccessToken:String, by currentUserUid:String, completionHandler: @escaping (_ gitHubID:String) -> Void) {
        guard let getAuthenticatedUserUrl:URL = URL(string:"https://api.github.com/user") else {return}
        let headers:HTTPHeaders = ["authorization":"Bearer \(AccessToken)"]
        
        Alamofire.request(getAuthenticatedUserUrl, method: .get, headers: headers).responseJSON { [unowned self] (response) in
            guard let data:Data = response.data else {return}
            let userInfoJson:JSON = JSON(data:data)
            let gitHubID = userInfoJson["login"].stringValue
            
            let userInfo = ["gitHubID":gitHubID]
            
            //가져온 정보를 Firebase에 저장
            Database.database().reference().child("UserInfo").child("\(currentUserUid)").setValue(userInfo)
            
            //GitHubID를 받아서 해당 유저의 Contributions를 수집하도록 함
            //TODO:- 추후에 로그인 계정이 User인지 Corp(Team) 인지 구별하여 별도 처리하도록 함.
            //       이유는, Contributions 가져오는 주소가 다른 것으로 알고 있음. (
            //       개인: https://github.com/users{/username}/contributions
            //       단체: 개인사이트 같은 별도 뷰는 없음. 비슷한 형태는, https://github.com{/organization_name}{/repository_name}/graphs/contributors
            
            guard let userDefaults = UserDefaults(suiteName: "group.devfimuxd.TodayExtensionSharingDefaults") else {return}
            userDefaults.setValue(gitHubID, forKey: "GitHubID")
            userDefaults.synchronize()
            
            completionHandler(gitHubID)
        }
    }
    
    //2.2 기본 userProfile 데이터
    func getCurrentUserDatas(completionHandler: @escaping (_ userDatas:[String:String]) -> Void) {
        self.getCurrentGitHubID { (realID) in
            guard let getCurrentUserDataUrl:URL = URL(string: "https://api.github.com/users/\(realID)"),
                let accessToken:String = UserDefaults.standard.value(forKey: "AccessToken") as? String else {return}
            
            let parameter:Parameters = ["Authorization":"Bearer \(accessToken)"]
            Alamofire.request(getCurrentUserDataUrl, method: .get, parameters:parameter).responseJSON(completionHandler: { (response) in
                guard let data:Data = response.data else {return}
                let json:JSON = JSON(data:data)
                
                let email:String = (Auth.auth().currentUser?.email)!
                let name:String = json["name"].stringValue
                let bio:String = json["bio"].stringValue
                let url:String = json["blog"].stringValue
                let company:String = json["company"].stringValue
                let location:String = json["location"].stringValue
                let profileImageUrl:String = json["avatar_url"].stringValue
                
                let userDatas:[String:String] = ["githubID":realID,
                                                 "name":name,
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
    func getTodayContributionsCount(completionHandler: @escaping(_ todayContributionsCount: String) -> Void) {
        self.getCurrentGitHubID { (realID) in
            guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(realID)/contributions") else {return}
            
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

                    completionHandler(contributionsDateArray)
                }
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
        }
    }
    
    //6. Repositories Data Array
    func getStaredRepositoriesDataArray(completionHandler: @escaping(_ repositoryDataArray:[[String:Any]]) -> Void) {
        self.getCurrentGitHubID { (realID) in
            guard let getRepositoriesUrl:URL = URL(string: "https://api.github.com/users/\(realID)/starred") else {return}
            
            Alamofire.request(getRepositoriesUrl, method: .get).responseJSON(completionHandler: { (response) in
                guard let data:Data = response.data else {return}
                let json:JSON = JSON(data:data)
                let jsonArray:[JSON] = json.arrayValue
                let tempArray:[[String:Any]] = jsonArray.map({ (json) -> [String:Any] in
                    let name:String = json["name"].stringValue
                    let fullName:String = json["full_name"].stringValue
                    let owner:String = json["owner"]["login"].stringValue
                    let description:String? = json["description"].string
                    let language:String = json["language"].stringValue
                    let mappedDic:[String:Any] = ["name":name,
                                                  "fullName":fullName,
                                                  "owner":owner,
                                                  "description":description ?? "",
                                                  "language":language]
                    return mappedDic
                })
                
                completionHandler(tempArray)
            })
        }
    }
    
}
