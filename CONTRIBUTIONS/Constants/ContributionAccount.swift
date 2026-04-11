//
//  ContributionAccount.swift
//  GITGET
//
//  Created by Bo-Young PARK on 2026-04-10.
//

import Foundation

struct ContributionAccount: Identifiable, Codable, Hashable {
    let provider: ContributionProvider
    let username: String
    let serverOrigin: String?

    init(provider: ContributionProvider, username: String, serverOrigin: String? = nil) {
        self.provider = provider
        self.username = username.trimmed
        self.serverOrigin = provider.normalizedServerOrigin(serverOrigin)
    }

    enum CodingKeys: String, CodingKey {
        case provider
        case username
        case serverOrigin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let provider = try container.decode(ContributionProvider.self, forKey: .provider)
        let username = try container.decode(String.self, forKey: .username)
        let serverOrigin = try container.decodeIfPresent(String.self, forKey: .serverOrigin)

        self.init(provider: provider, username: username, serverOrigin: serverOrigin)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(provider, forKey: .provider)
        try container.encode(username, forKey: .username)
        try container.encodeIfPresent(serverOrigin, forKey: .serverOrigin)
    }

    var id: String {
        let host = serverOrigin ?? "public"
        return "\(provider.rawValue):\(host.lowercased()):\(username.lowercased())"
    }
}
