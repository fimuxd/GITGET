//
//  UserAPI.swift
//  GITGET
//
//  Created by Bo-Young Park on 2024-10-07.
//

import Foundation
import Alamofire

enum UserAPI {
    private static let requestTimeout: TimeInterval = 8

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
        guard let urlRequest = try? Router.gitHubUserInfo(account).asURLRequest() else {
            return .failure(AFError.parameterEncodingFailed(reason: .missingURL))
        }

        let authorizedRequest = await GitLabRequestAuthorization.authorizedRequest(urlRequest, for: account)

        let response = await AF.request(authorizedRequest)
            .serializingData()
            .response

        switch response.result {
        case .failure(let error):
            return .failure(ContributionRequestError.from(error, endpoint: "GitHub profile"))
        case .success(let result):
            if let statusCode = response.response?.statusCode,
               !(200..<300).contains(statusCode) {
                return .failure(ContributionRequestError.httpStatus(endpoint: "GitHub profile", statusCode: statusCode))
            }

            do {
                let user = try JSONDecoder().decode(User.self, from: result)
                return .success(user)
            } catch {
                return .failure(ContributionRequestError.invalidResponse(endpoint: "GitHub profile"))
            }
        }
    }

    private static func gitLabUserInfo(of account: ContributionAccount) async -> Result<User, Error> {
        guard let searchRequest = try? Router.gitLabUsers(account).asURLRequest() else {
            return .failure(AFError.parameterEncodingFailed(reason: .missingURL))
        }

        let authorizedSearchRequest = await GitLabRequestAuthorization.authorizedRequest(searchRequest, for: account)

        let response = await AF.request(authorizedSearchRequest)
            .serializingData()
            .response

        switch response.result {
        case .failure(let error):
            return .failure(ContributionRequestError.from(error, endpoint: "GitLab profile"))
        case .success(let result):
            if let statusCode = response.response?.statusCode,
               !(200..<300).contains(statusCode) {
                return .failure(ContributionRequestError.httpStatus(endpoint: "GitLab profile", statusCode: statusCode))
            }

            do {
                let users = try JSONDecoder().decode([User].self, from: result)
                let normalizedUsername = account.username.lowercased()
                guard let user = users.first(where: { ($0.login ?? "").lowercased() == normalizedUsername }) else {
                    return .failure(ContributionRequestError.notFound(endpoint: "GitLab profile"))
                }

                guard let userID = user.id,
                      let detailRequest = try? Router.gitLabUserDetail(account, userID: userID).asURLRequest() else {
                    return .success(user)
                }

                let authorizedDetailRequest = await GitLabRequestAuthorization.authorizedRequest(detailRequest, for: account)
                let detailResponse = await AF.request(authorizedDetailRequest)
                    .serializingData()
                    .response

                switch detailResponse.result {
                case .failure:
                    return .success(user)
                case .success(let detailResult):
                    if let statusCode = detailResponse.response?.statusCode,
                       !(200..<300).contains(statusCode) {
                        return .success(user)
                    }

                    if let detailedUser = try? JSONDecoder().decode(User.self, from: detailResult) {
                        return .success(mergedGitLabUser(summary: user, detail: detailedUser))
                    }

                    return .success(user)
                }
            } catch {
                return .failure(ContributionRequestError.invalidResponse(endpoint: "GitLab profile"))
            }
        }
    }

    private static func mergedGitLabUser(summary: User, detail: User) -> User {
        User(
            login: detail.login ?? summary.login,
            id: detail.id ?? summary.id,
            name: detail.name ?? summary.name,
            profileImageURL: detail.profileImageURL ?? summary.profileImageURL,
            bio: detail.bio ?? summary.bio,
            location: detail.location ?? summary.location,
            company: detail.company ?? summary.company,
            followers: detail.followers ?? summary.followers,
            following: detail.following ?? summary.following,
            createdAt: detail.createdAt ?? summary.createdAt
        )
    }
}

extension UserAPI {
    enum Router: URLRequestConvertible {
        case gitHubUserInfo(_ account: ContributionAccount)
        case gitLabUsers(_ account: ContributionAccount)
        case gitLabUserDetail(_ account: ContributionAccount, userID: Int)

        var method: HTTPMethod { .get }

        var headers: HTTPHeaders {
            ["Content-Type": "application/json"]
        }

        func asURLRequest() throws -> URLRequest {
            switch self {
            case .gitHubUserInfo(let account):
                let url = URL.userAPI(account: account).appending(account.username) ?? URL.userAPI(account: account)
                var request = try URLRequest(url: url, method: method, headers: headers)
                request.timeoutInterval = requestTimeout
                return request

            case .gitLabUsers(let account):
                let url = URL.userAPI(account: account).appendingQuery(name: "username", value: account.username)
                var request = try URLRequest(url: url, method: method, headers: headers)
                request.timeoutInterval = requestTimeout
                return request

            case .gitLabUserDetail(let account, let userID):
                let url = URL.userAPI(account: account).appending(String(userID)) ?? URL.userAPI(account: account)
                var request = try URLRequest(url: url, method: method, headers: headers)
                request.timeoutInterval = requestTimeout
                return request
            }
        }
    }
}

enum ContributionRequestError: LocalizedError {
    case httpStatus(endpoint: String, statusCode: Int)
    case invalidResponse(endpoint: String)
    case notFound(endpoint: String)
    case transport(endpoint: String, code: URLError.Code)
    case generic(endpoint: String)

    static func from(_ error: Error, endpoint: String) -> ContributionRequestError {
        if let afError = error.asAFError,
           case .sessionTaskFailed(let underlyingError) = afError,
           let urlError = underlyingError as? URLError {
            return .transport(endpoint: endpoint, code: urlError.code)
        }

        if let urlError = error as? URLError {
            return .transport(endpoint: endpoint, code: urlError.code)
        }

        return .generic(endpoint: endpoint)
    }

    var errorDescription: String? {
        switch self {
        case .httpStatus(let endpoint, let statusCode):
            switch statusCode {
            case 401, 403:
                return "\(endpoint) requires GitLab sign-in inside the app (HTTP \(statusCode))."
            case 404:
                return "\(endpoint) endpoint was not found (HTTP 404)."
            default:
                return "\(endpoint) request failed with HTTP \(statusCode)."
            }

        case .invalidResponse(let endpoint):
            return "\(endpoint) returned an unexpected response. If this server requires app-side GitLab sign-in or a trusted company certificate, refresh your GitLab sign-in and try again."

        case .notFound(let endpoint):
            return "\(endpoint) did not return a matching account."

        case .transport(let endpoint, let code):
            switch code {
            case .timedOut:
                return "\(endpoint) request timed out."
            case .cannotFindHost, .dnsLookupFailed, .cannotConnectToHost:
                return "\(endpoint) could not reach the server host."
            case .notConnectedToInternet, .networkConnectionLost:
                return "\(endpoint) failed because the network connection is unavailable."
            case .secureConnectionFailed,
                 .serverCertificateHasBadDate,
                 .serverCertificateHasUnknownRoot,
                 .serverCertificateNotYetValid,
                 .serverCertificateUntrusted,
                 .clientCertificateRejected,
                 .clientCertificateRequired:
                return "\(endpoint) failed because this Mac does not trust the server certificate."
            default:
                return "\(endpoint) request failed (\(code.rawValue))."
            }

        case .generic(let endpoint):
            return "\(endpoint) is currently unavailable."
        }
    }
}
