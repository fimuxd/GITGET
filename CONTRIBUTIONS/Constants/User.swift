//
//  User.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/29/20.
//

import Foundation

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
        case login, username, name, bio, location, company, organization, followers, following
        case profileImageURL = "avatar_url"
        case createdAt = "created_at"
    }

    init(
        login: String?,
        name: String?,
        profileImageURL: String?,
        bio: String?,
        location: String?,
        company: String?,
        followers: Int?,
        following: Int?,
        createdAt: Date?
    ) {
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
