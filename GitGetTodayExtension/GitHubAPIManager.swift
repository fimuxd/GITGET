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

enum ThemeName:Int {
    case gitHubOriginal
    case blackAndWhite
    case jejuOceanBlue
    case winterBurgundy
    case halloweenOrange
    case ginkgoYellow
    case freeStyle
    case christmasEdition
}

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
    func getContributionsColorCodeArray(gitHubID:String, theme:ThemeName?, completionHandler: @escaping(_ contributionsHexColorCodeArray: [String]) -> Void) {
        guard let getContributionsUrl:URL = URL(string: "https://github.com/users/\(gitHubID)/contributions") else {print("//API 가드"); return}
        print("//API 가드 통과")
        Alamofire.request(getContributionsUrl, method: .get).responseString {(response) in
            switch response.result {
            case .success(let value):
                print("//API success")
                do{
                    let htmlValue = value
                    guard let elements:Elements = try? SwiftSoup.parse(htmlValue).select("rect") else {return}
                    var tempArray:[String] = []
                    
                    for element:Element in elements.array() {
                        guard let contributionsHexColorCode:String = try? element.attr("fill") else {return}
                        tempArray.append(contributionsHexColorCode)
                    }
                    
                    let contributionsHexColorCodeArray:[String] = tempArray
        
                    guard let currentThemeName:ThemeName = theme else {
                        print("//API 테마가드")
                        completionHandler(contributionsHexColorCodeArray)
                        return}
                    
                    print("//API 테마가드\(currentThemeName)")
                    switch currentThemeName {
                    case .gitHubOriginal:
                        completionHandler(contributionsHexColorCodeArray)
                        
                    case .blackAndWhite:
                        let oceanColorArray = contributionsHexColorCodeArray.map({ (colorCode) -> String in
                            switch colorCode {
                            case "#c6e48b": //lv.1
                                return "AAAAAA"
                            case "#7bc96f": //lv.2
                                return "7A7A7A"
                            case "#239a3b": //lv.3
                                return "444444"
                            case "#196127": //lv.4
                                return "222222"
                            default: //"#ebedf0": //lv.0(Contributions 0)
                                return "#ebedf0"
                            }
                        })
                        
                        completionHandler(oceanColorArray)
                        
                    case .jejuOceanBlue:
                        let oceanColorArray = contributionsHexColorCodeArray.map({ (colorCode) -> String in
                            switch colorCode {
                            case "#c6e48b": //lv.1
                                return "B2DADA"
                            case "#7bc96f": //lv.2
                                return "84D0E4"
                            case "#239a3b": //lv.3
                                return "54A9DE"
                            case "#196127": //lv.4
                                return "294478"
                            default: //"#ebedf0": //lv.0(Contributions 0)
                                return "#ebedf0"
                            }
                        })
                        
                        completionHandler(oceanColorArray)
                        
                    case .winterBurgundy:
                        let winterColorArray = contributionsHexColorCodeArray.map({ (colorCode) -> String in
                            switch colorCode {
                            case "#c6e48b": //lv.1
                                return "DC9690"
                            case "#7bc96f": //lv.2
                                return "AC4748"
                            case "#239a3b": //lv.3
                                return "872A2B"
                            case "#196127": //lv.4
                                return "430704"
                            default: //"#ebedf0": //lv.0(Contributions 0)
                                return "#ebedf0"
                            }
                        })
                        
                        completionHandler(winterColorArray)
                        
                    case .halloweenOrange:
                        let halloweenColorArray = contributionsHexColorCodeArray.map({ (colorCode) -> String in
                            switch colorCode {
                            case "#c6e48b": //lv.1
                                return "DE8F6E"
                            case "#7bc96f": //lv.2
                                return "CD603D"
                            case "#239a3b": //lv.3
                                return "A7502A"
                            case "#196127": //lv.4
                                return "894022"
                            default: //"#ebedf0": //lv.0(Contributions 0)
                                return "#ebedf0"
                            }
                        })
                        
                        completionHandler(halloweenColorArray)
                        
                    case .ginkgoYellow:
                        let ginkgoColorArray = contributionsHexColorCodeArray.map({ (colorCode) -> String in
                            switch colorCode {
                            case "#c6e48b": //lv.1
                                return "DCC08F"
                            case "#7bc96f": //lv.2
                                return "F8D25E"
                            case "#239a3b": //lv.3
                                return "F0AD3C"
                            case "#196127": //lv.4
                                return "E17036"
                            default: //"#ebedf0": //lv.0(Contributions 0)
                                return "#ebedf0"
                            }
                        })
                        
                        completionHandler(ginkgoColorArray)
                        
                    case .freeStyle:
                        let freeStyleColorArray = contributionsHexColorCodeArray.map({ (colorCode) -> String in
                            switch colorCode {
                            case "#c6e48b": //lv.1
                                return "59645E"
                            case "#7bc96f": //lv.2
                                return "67D69F"
                            case "#239a3b": //lv.3
                                return "54A9DE"
                            case "#196127": //lv.4
                                return "CA4346"
                            default: //"#ebedf0": //lv.0(Contributions 0)
                                return "#ebedf0"
                            }
                        })
                        
                        completionHandler(freeStyleColorArray)
                        
                    case .christmasEdition:
                        let christmasColorArray = contributionsHexColorCodeArray.map({ (colorCode) -> String in
                            switch colorCode {
                            case "#c6e48b": //lv.1
                                return "F5EBCD"
                            case "#7bc96f": //lv.2
                                return "254E12"
                            case "#239a3b": //lv.3
                                return "811919"
                            case "#196127": //lv.4
                                return "CF9946"
                            default: //"#ebedf0": //lv.0(Contributions 0)
                                return "#ebedf0"
                            }
                        })
                        
                        completionHandler(christmasColorArray)
                    }
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
                        guard let contributionsDate:String = try? element.attr("data-date") else {return}
                        tempArray.append(contributionsDate)
                    }
                    
                    let contributionsDateArray:[String] = tempArray
                    
                    let date:Date = Date()
                    
                    completionHandler(contributionsDateArray)
                }
            case .failure(let error):
                print("///Alamofire.request - error: ", error)
            }
        }
    }
    
}


