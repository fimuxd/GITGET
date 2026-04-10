//
//  UserAPI.swift
//  GITGET
//
//  Created by Bo-Young Park on 2024-10-07.
//

import Foundation
import Alamofire

enum UserAPI {
    static func userInfo(of account: ContributionAccount) async -> Result<User, Error> {
        switch account.provider {
        case .github:
            return await gitHubUserInfo(of: account)
        case .gitlab:
            return await gitLabUserInfo(of: account)
        }
    }

    static func userInfo(of username: String, provider: ContributionProvider, serverOrigin: String? = nil) async -> Result<User, Error> {
        await userInfo(of: ContributionAccount(provider: provider, username: username, serverOrigin: serverOrigin))
    }

    private static func gitHubUserInfo(of account: ContributionAccount) async -> Result<User, Error> {
        let urlRequest = try! Router.gitHubUserInfo(account).asURLRequest()

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

    private static func gitLabUserInfo(of account: ContributionAccount) async -> Result<User, Error> {
        let urlRequest = try! Router.gitLabUsers(account).asURLRequest()

        let response = await AF.request(urlRequest)
            .serializingData()
            .response

        switch response.result {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            do {
                let users = try JSONDecoder().decode([User].self, from: result)
                guard let user = users.first else {
                    return .failure(AFError.responseValidationFailed(reason: .dataFileNil))
                }
                return .success(user)
            } catch {
                return .failure(error)
            }
        }
    }
}

extension UserAPI {
    enum Router: URLRequestConvertible {
        case gitHubUserInfo(_ account: ContributionAccount)
        case gitLabUsers(_ account: ContributionAccount)

        var method: HTTPMethod { .get }

        var headers: HTTPHeaders {
            ["Content-Type": "application/json"]
        }

        func asURLRequest() throws -> URLRequest {
            switch self {
            case .gitHubUserInfo(let account):
                let url = URL.userAPI(account: account).appending(account.username)!
                return try URLRequest(url: url, method: method, headers: headers)

            case .gitLabUsers(let account):
                let url = URL.userAPI(account: account).appendingQuery(name: "username", value: account.username)
                return try URLRequest(url: url, method: method, headers: headers)
            }
        }
    }
}
