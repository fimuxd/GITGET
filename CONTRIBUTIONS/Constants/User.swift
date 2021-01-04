//
//  User.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/29/20.
//

import Foundation

struct User: Codable {
    let name: String
    let profileImageURL: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case profileImageURL = "avatar_url"
    }
}
