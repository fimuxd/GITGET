//
//  User.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/29/20.
//

import Foundation

struct User: Codable {
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
        case login, name, bio, location, company, followers, following
        case profileImageURL = "avatar_url"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.login = try values.decodeIfPresent(String.self, forKey: .login)
        self.name = try values.decodeIfPresent(String.self, forKey: .name)
        self.profileImageURL = try values.decodeIfPresent(String.self, forKey: .profileImageURL)
        self.bio = try values.decodeIfPresent(String.self, forKey: .bio)
        self.location = try values.decodeIfPresent(String.self, forKey: .location)
        self.company = try values.decodeIfPresent(String.self, forKey: .company)
        self.followers = try values.decodeIfPresent(Int.self, forKey: .followers)
        self.following = try values.decodeIfPresent(Int.self, forKey: .following)
        self.createdAt = Date.parse(values, key: .createdAt)
    }
}
