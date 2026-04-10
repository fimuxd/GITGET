//
//  URL+Extensions.swift
//  GITGET
//
//  Created by Bo-Young Park on 2024-10-07.
//

import Foundation

extension URL {
    static var kinestBaseURL: String = "https://typescript.nestjs.kinest1997.com"
    static var gitHubBaseURL: String = "https://api.github.com"
    static var gitHubWebBaseURL: String = "https://github.com"
    static var gitLabBaseURL: String = "https://gitlab.com/api/v4"
    static var gitLabWebBaseURL: String = "https://gitlab.com"
    
    static var kinestGitHubAPI: URL {
        return URL(string: kinestBaseURL + "/github")!
    }
    
    static var userAPI: URL {
        return URL(string: gitHubBaseURL + "/users")!
    }

    static var gitHubContributionsAPI: URL {
        return URL(string: gitHubWebBaseURL + "/users")!
    }

    static var gitLabUsersAPI: URL {
        return URL(string: gitLabBaseURL + "/users")!
    }

    static var gitLabContributionsAPI: URL {
        return URL(string: gitLabWebBaseURL + "/users")!
    }

    static func userAPI(account: ContributionAccount) -> URL {
        account.provider.apiBaseURL(serverOrigin: account.serverOrigin).appending("users")
            ?? account.provider.apiBaseURL(serverOrigin: account.serverOrigin)
    }

    static func userAPI(provider: ContributionProvider, serverOrigin: String?) -> URL {
        provider.apiBaseURL(serverOrigin: serverOrigin).appending("users") ?? provider.apiBaseURL(serverOrigin: serverOrigin)
    }

    static func contributionsAPI(account: ContributionAccount) -> URL {
        account.provider.webBaseURL(serverOrigin: account.serverOrigin).appending("users")
            ?? account.provider.webBaseURL(serverOrigin: account.serverOrigin)
    }

    static func contributionsAPI(provider: ContributionProvider, serverOrigin: String?) -> URL {
        provider.webBaseURL(serverOrigin: serverOrigin).appending("users") ?? provider.webBaseURL(serverOrigin: serverOrigin)
    }
}

extension URL {
    /// 기존 URL에 문자열을 추가합니다. 추가하는 문자열이 path 요소라고 판단될 경우, 기존 URL과 추가하는 문자열 사이에 path separator(/)가 추가로 붙을 수 있습니다.
    func appending(_ string: String) -> URL? {
        if string.isEmpty { return self }
        
        let specialCharactors = ["/", "?", "#", "&"]
        let isPathSeparatorNeeded = !(specialCharactors.contains(String(string.first!)))
        
        // persent encoding 된 문자열이 존재할 경우, urlComponents.url이 반환하는 url이 percent encoding을 중복으로 처리하게 되므로, 기존에 존재하는 percent encoding은 제거해줍니다.
        guard let urlString = [absoluteString, string]
            .joined(separator: (isPathSeparatorNeeded ? "/" : ""))
            .removingPercentEncoding
        else {
            return self
        }
        
        // URLComponent.url을 사용하여 urlString을 URL로 변환할 경우,
        // urlString의 path 부분에 존재하는 값이 자동으로 percentEncoding 된다는 장점이 있으나,
        // iOS 16에서부터 정상 작동하는 문제가 있습니다. (iOS 15에서는 nil 반환함)
        // return URLComponents(string: uirlString)?.url?.removingDuplicatedPathSeparator()
        return urlString.encodedURL()?.removingDuplicatePathSeparator()
    }
    
    func appendingQuery(name: String, value: String?) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        
        let queryItem = URLQueryItem(name: name, value: value)
        queryItems.append(queryItem)
        urlComponents.queryItems = queryItems
        
        return urlComponents.url!
    }
    
    /// URL의 host 이후 부분에 연속적으로 중복된 "/" 문자를 하나만 남기도록 변경합니다.
    func removingDuplicatePathSeparator() -> URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        
        var path = urlComponents.path
        while path.contains("//") {
            path = path.replacingOccurrences(of: "//", with: "/")
        }
        
        urlComponents.path = path
        return urlComponents.url!
    }
}
