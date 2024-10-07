//
//  ContributionAPI.swift
//  GITGET
//
//  Created by Bo-Young Park on 2024-10-07.
//

import SwiftUI
import Alamofire

/**
 GitHub 의 특정 username의 contribution을 확인하는 API
 - note: GitHub에서 제공하는 API가 아니며 `kinest1997`이 자체적으로 커스텀하여 제공하는 API 입니다.
 */
enum ContributionAPI {
    static func contributions(of username: String) async -> Result<[Contribution], Error> {
        let urlRequest = try! Router.contributions(username).asURLRequest()
        
        let response = await AF.request(urlRequest)
            .serializingData()
            .response
        
        switch response.result {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            do {
                let response = try JSONDecoder().decode(ContributionResponse.self, from: result)
                let contributions = response.contributions
                return .success(contributions)
            } catch {
                return .failure(error)
            }
        }
    }
}

extension ContributionAPI {
    enum Router: URLRequestConvertible {
        case contributions(_ username: String)
        
        var baseURL: URL { .kinestGitHubAPI }
        
        var method: HTTPMethod {
            switch self {
            case .contributions:
                return .get
            }
        }
        
        var path: String {
            switch self {
            case .contributions:
                return "/contributions"
            }
        }
        
        var headers: HTTPHeaders {
            return ["Content-Type": "application/json"]
        }
        
        func asURLRequest() throws -> URLRequest {
            var url = baseURL.appending(path)!
            
            switch self {
            case .contributions(let username):
                url = url.appendingQuery(name: "username", value: username)
                url = url.appendingQuery(name: "years", value: "last")
                return try URLRequest(url: url, method: method, headers: headers)
            }
        }
    }
}
