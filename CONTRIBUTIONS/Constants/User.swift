//
//  User.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/29/20.
//

import Foundation
import Security

enum ContributionProvider: String, CaseIterable, Codable, Identifiable {
    case github
    case gitlab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .github: return "GitHub"
        case .gitlab: return "GitLab"
        }
    }

    var serverOriginPlaceholder: String {
        switch self {
        case .github:
            return "https://github.example.com"
        case .gitlab:
            return "https://gitlab.example.com"
        }
    }

    var defaultWebOrigin: URL {
        switch self {
        case .github:
            return URL(string: "https://github.com")!
        case .gitlab:
            return URL(string: "https://gitlab.com")!
        }
    }

    var defaultAPIBaseURL: URL {
        switch self {
        case .github:
            return URL(string: "https://api.github.com")!
        case .gitlab:
            return URL(string: "https://gitlab.com/api/v4")!
        }
    }

    func normalizedServerOrigin(_ serverOrigin: String?) -> String? {
        let trimmedServerOrigin = serverOrigin?.trimmed ?? ""
        guard !trimmedServerOrigin.isEmpty else {
            return nil
        }

        let candidate = trimmedServerOrigin.contains("://")
            ? trimmedServerOrigin
            : "https://\(trimmedServerOrigin)"

        guard var components = URLComponents(string: candidate) else {
            return nil
        }

        components.scheme = "https"

        guard components.host != nil else {
            return nil
        }

        components.user = nil
        components.password = nil
        components.path = ""
        components.query = nil
        components.fragment = nil

        guard let origin = components.url?.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) else {
            return nil
        }

        let normalizedHost = components.host?.lowercased()

        switch self {
        case .github where normalizedHost == "github.com" || normalizedHost == "api.github.com":
            return nil
        case .gitlab where normalizedHost == "gitlab.com":
            return nil
        default:
            return origin
        }
    }

    func webBaseURL(serverOrigin: String?) -> URL {
        guard let origin = normalizedServerOrigin(serverOrigin) else {
            return defaultWebOrigin
        }

        return URL(string: origin) ?? defaultWebOrigin
    }

    func resolvedWebOriginString(serverOrigin: String?) -> String {
        webBaseURL(serverOrigin: serverOrigin)
            .absoluteString
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    func apiBaseURL(serverOrigin: String?) -> URL {
        guard let origin = normalizedServerOrigin(serverOrigin) else {
            return defaultAPIBaseURL
        }

        switch self {
        case .github:
            return URL(string: origin + "/api/v3") ?? defaultAPIBaseURL
        case .gitlab:
            return URL(string: origin + "/api/v4") ?? defaultAPIBaseURL
        }
    }
}

struct User: Decodable {
    let id: Int?
    let login: String?
    let name: String?
    let profileImageURL: String?
    let bio: String?
    let location: String?
    let company: String?
    let followers: Int?
    let following: Int?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, login, username, name, bio, location, company, organization, followers, following
        case profileImageURL = "avatar_url"
        case createdAt = "created_at"
    }

    init(
        login: String?,
        id: Int? = nil,
        name: String?,
        profileImageURL: String?,
        bio: String?,
        location: String?,
        company: String?,
        followers: Int?,
        following: Int?,
        createdAt: Date?
    ) {
        self.id = id
        self.login = login
        self.name = name
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.location = location
        self.company = company
        self.followers = followers
        self.following = following
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try values.decodeIfPresent(Int.self, forKey: .id)
        self.login = try values.decodeIfPresent(String.self, forKey: .login)
            ?? values.decodeIfPresent(String.self, forKey: .username)
        self.name = try values.decodeIfPresent(String.self, forKey: .name)
        self.profileImageURL = try values.decodeIfPresent(String.self, forKey: .profileImageURL)
        self.bio = try values.decodeIfPresent(String.self, forKey: .bio)
        self.location = try values.decodeIfPresent(String.self, forKey: .location)
        self.company = try values.decodeIfPresent(String.self, forKey: .company)
            ?? values.decodeIfPresent(String.self, forKey: .organization)
        self.followers = try values.decodeIfPresent(Int.self, forKey: .followers)
        self.following = try values.decodeIfPresent(Int.self, forKey: .following)
        self.createdAt = Date.parse(values, key: .createdAt)
    }
}

enum GitLabRequestAuthorization {
    private static let clientIDStoreKey = "gitlabOAuthClientIDs"
    private static let tokenService = "kr.devfimuxd.gitget.0.gitlab.tokens"
    private static let fallbackKeyPrefix = "gitlabOAuthFallbackTokens."

    static func authorizedRequest(_ request: URLRequest, for account: ContributionAccount) async -> URLRequest {
        guard account.provider == .gitlab else {
            return request
        }

        let origin = ContributionProvider.gitlab.resolvedWebOriginString(serverOrigin: account.serverOrigin)
        var authorizedRequest = request

        if let url = request.url,
           let cookies = HTTPCookieStorage.shared.cookies(for: url),
           !cookies.isEmpty {
            HTTPCookie.requestHeaderFields(with: cookies).forEach { header, value in
                authorizedRequest.setValue(value, forHTTPHeaderField: header)
            }
        }

        if let accessToken = await validAccessToken(forOrigin: origin) {
            authorizedRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return authorizedRequest
    }

    private static func validAccessToken(forOrigin origin: String) async -> String? {
        guard var tokens = readTokens(forOrigin: origin) else {
            return nil
        }

        if !tokens.isExpired {
            return tokens.accessToken
        }

        guard let refreshToken = tokens.refreshToken,
              let clientID = (UserDefaults.standard.dictionary(forKey: clientIDStoreKey) as? [String: String])?[origin],
              !clientID.trimmed.isEmpty else {
            return nil
        }

        guard let refreshedTokens = try? await refreshTokens(origin: origin, clientID: clientID, refreshToken: refreshToken) else {
            return nil
        }

        writeTokens(refreshedTokens, forOrigin: origin)
        tokens = refreshedTokens
        return tokens.accessToken
    }

    private static func refreshTokens(origin: String, clientID: String, refreshToken: String) async throws -> StoredTokens {
        guard let tokenURL = URL(string: origin + "/oauth/token") else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL)
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID
        ]
        .sorted { $0.key < $1.key }
        .map { key, value in
            let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(escapedKey)=\(escapedValue)"
        }
        .joined(separator: "&")
        .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse)
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.tokens
    }

    private static func readTokens(forOrigin origin: String) -> StoredTokens? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: tokenService,
            kSecAttrAccount: origin,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecMissingEntitlement || status == errSecNotAvailable {
            return fallbackTokens(forOrigin: origin)
        }

        guard status == errSecSuccess,
              let data = result as? Data else {
            return fallbackTokens(forOrigin: origin)
        }

        return try? JSONDecoder().decode(StoredTokens.self, from: data)
    }

    private static func writeTokens(_ tokens: StoredTokens, forOrigin origin: String) {
        guard let data = try? JSONEncoder().encode(tokens) else {
            return
        }

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: tokenService,
            kSecAttrAccount: origin
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var insertQuery = query
            insertQuery[kSecValueData] = data
            let insertStatus = SecItemAdd(insertQuery as CFDictionary, nil)
            if insertStatus == errSecMissingEntitlement || insertStatus == errSecNotAvailable {
                storeFallbackTokens(data, forOrigin: origin)
            }
            return
        }

        if updateStatus == errSecMissingEntitlement || updateStatus == errSecNotAvailable {
            storeFallbackTokens(data, forOrigin: origin)
        }
    }

    private static func fallbackTokens(forOrigin origin: String) -> StoredTokens? {
        guard let data = UserDefaults.standard.data(forKey: fallbackKey(forOrigin: origin)) else {
            return nil
        }

        return try? JSONDecoder().decode(StoredTokens.self, from: data)
    }

    private static func storeFallbackTokens(_ data: Data, forOrigin origin: String) {
        UserDefaults.standard.set(data, forKey: fallbackKey(forOrigin: origin))
    }

    private static func fallbackKey(forOrigin origin: String) -> String {
        fallbackKeyPrefix + origin
    }

    private struct StoredTokens: Codable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date?

        var isExpired: Bool {
            guard let expiresAt else {
                return false
            }

            return expiresAt <= Date().addingTimeInterval(30)
        }
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
        }

        var tokens: StoredTokens {
            StoredTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
            )
        }
    }
}
