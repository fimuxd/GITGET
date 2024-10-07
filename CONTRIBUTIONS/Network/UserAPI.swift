//
//  UserAPI.swift
//  GITGET
//
//  Created by Bo-Young Park on 2024-10-07.
//

import SwiftUI
import Alamofire

/**
 GitHub 에서 제공하는 user 정보 API
 */
enum UserAPI {
    static func userInfo(of username: String) async -> Result<User, Error> {
        let urlRequest = try! Router.userInfo(username).asURLRequest()
        
        let response = await AF.request(urlRequest)
            .serializingData()
            .response
        
        switch response.result {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            do {
                let user = try JSONDecoder().decode(User.self, from: result)
                return .success(user)
            } catch {
                return .failure(error)
            }
        }
    }
}

extension UserAPI {
    enum Router: URLRequestConvertible {
        case userInfo(_ username: String)
        
        var baseURL: URL { .userAPI }
        
        var method: HTTPMethod {
            switch self {
            case .userInfo:
                return .get
            }
        }
        
        var headers: HTTPHeaders {
            return ["Content-Type": "application/json"]
        }
        
        func asURLRequest() throws -> URLRequest {
            var url = baseURL
            
            switch self {
            case .userInfo(let username):
                url = url.appending(username)!
                return try URLRequest(url: url, method: method, headers: headers)
            }
        }
    }
}
