//
//  GitHubAPIManager.swift
//  GitGetTodayExtension
//
//  Created by Bo-Young PARK on 01/12/2017.
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
    
    //1. Today Contributions Count
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
    
    //2. Contributions HexColorCode Array
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
    
    //3. Contributions Date Array
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
    
}


