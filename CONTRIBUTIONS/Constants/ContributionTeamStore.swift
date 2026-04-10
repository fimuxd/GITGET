//
//  ContributionTeamStore.swift
//  GITGET
//
//  Created by OpenAI on 2026/04/10.
//

import Foundation

struct ContributionTeam: Identifiable, Codable, Hashable {
    static let allFriendsID = "system.all-friends"
    static let allFriendsName = "All Friends"

    let id: String
    let name: String
    let accountIDs: [String]

    static func allFriends(accountIDs: [String]) -> ContributionTeam {
        ContributionTeam(id: Self.allFriendsID, name: Self.allFriendsName, accountIDs: accountIDs)
    }
}

struct ContributionTeamStore: Codable, Hashable {
    static let currentVersion = 1

    let version: Int
    let selectedTeamID: String
    let teams: [ContributionTeam]
    let accounts: [ContributionAccount]

    var selectedTeam: ContributionTeam? {
        teams.first { $0.id == selectedTeamID }
    }

    var selectedAccounts: [ContributionAccount] {
        guard let selectedTeam else { return [] }

        let accountsByID = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
        return selectedTeam.accountIDs.compactMap { accountsByID[$0] }
    }

    var customTeams: [ContributionTeam] {
        teams.filter { $0.id != ContributionTeam.allFriendsID }
    }

    func normalized() -> ContributionTeamStore {
        let normalizedAccounts = Self.normalizedAccounts(accounts)
        let validAccountIDs = Set(normalizedAccounts.map(\.id))
        var seenTeamIDs = Set<String>()
        let normalizedCustomTeams = teams.compactMap { team -> ContributionTeam? in
            guard team.id != ContributionTeam.allFriendsID,
                  seenTeamIDs.insert(team.id).inserted else {
                return nil
            }

            let normalizedAccountIDs = Self.normalizedAccountIDs(team.accountIDs, validIDs: validAccountIDs)
            let normalizedName = team.name.trimmed.isEmpty ? team.name : team.name.trimmed
            return ContributionTeam(id: team.id, name: normalizedName, accountIDs: normalizedAccountIDs)
        }

        let allFriendsTeam = ContributionTeam.allFriends(accountIDs: normalizedAccounts.map(\.id))
        let fallbackTeams = [allFriendsTeam] + normalizedCustomTeams

        let resolvedSelectedTeamID: String
        if fallbackTeams.contains(where: { $0.id == selectedTeamID }) {
            resolvedSelectedTeamID = selectedTeamID
        } else {
            resolvedSelectedTeamID = ContributionTeam.allFriendsID
        }

        return ContributionTeamStore(
            version: version,
            selectedTeamID: resolvedSelectedTeamID,
            teams: fallbackTeams,
            accounts: normalizedAccounts
        )
    }

    func addingAccount(_ account: ContributionAccount) -> ContributionTeamStore {
        addingAccount(account, toTeamID: selectedTeamID)
    }

    func addingAccount(_ account: ContributionAccount, toTeamID teamID: String) -> ContributionTeamStore {
        let normalizedAccount = Self.normalizedAccount(account)
        guard !accounts.contains(where: { $0.id == normalizedAccount.id }) else {
            return self
        }

        let resolvedSelectedTeamID = teams.contains(where: { $0.id == teamID }) ? teamID : selectedTeamID
        let updatedAccounts = [normalizedAccount] + accounts
        let updatedTeams = teams.map { team in
            guard team.id == ContributionTeam.allFriendsID || team.id == resolvedSelectedTeamID else {
                return team
            }

            return ContributionTeam(id: team.id, name: team.name, accountIDs: [normalizedAccount.id] + team.accountIDs)
        }

        return ContributionTeamStore(
            version: version,
            selectedTeamID: resolvedSelectedTeamID,
            teams: updatedTeams,
            accounts: updatedAccounts
        ).normalized()
    }

    func selectingTeam(withID teamID: String) -> ContributionTeamStore {
        guard teams.contains(where: { $0.id == teamID }) else {
            return self
        }

        return ContributionTeamStore(
            version: version,
            selectedTeamID: teamID,
            teams: teams,
            accounts: accounts
        ).normalized()
    }

    func removingAccounts(withIDs removedAccountIDs: [String]) -> ContributionTeamStore {
        let removalSet = Set(removedAccountIDs)
        let updatedAccounts = accounts.filter { !removalSet.contains($0.id) }
        let updatedTeams = teams.map { team in
            let updatedAccountIDs = team.accountIDs.filter { !removalSet.contains($0) }
            return ContributionTeam(id: team.id, name: team.name, accountIDs: updatedAccountIDs)
        }

        return ContributionTeamStore(
            version: version,
            selectedTeamID: selectedTeamID,
            teams: updatedTeams,
            accounts: updatedAccounts
        ).normalized()
    }

    func creatingTeam(named name: String) -> ContributionTeamStore {
        let trimmedName = name.trimmed
        guard !trimmedName.isEmpty else { return self }

        let createdTeam = ContributionTeam(
            id: "team.\(UUID().uuidString.lowercased())",
            name: trimmedName,
            accountIDs: []
        )

        return ContributionTeamStore(
            version: version,
            selectedTeamID: createdTeam.id,
            teams: teams + [createdTeam],
            accounts: accounts
        ).normalized()
    }

    func renamingTeam(withID teamID: String, to name: String) -> ContributionTeamStore {
        let trimmedName = name.trimmed
        guard teamID != ContributionTeam.allFriendsID,
              !trimmedName.isEmpty,
              teams.contains(where: { $0.id == teamID }) else {
            return self
        }

        let updatedTeams = teams.map { team in
            guard team.id == teamID else { return team }
            return ContributionTeam(id: team.id, name: trimmedName, accountIDs: team.accountIDs)
        }

        return ContributionTeamStore(
            version: version,
            selectedTeamID: selectedTeamID,
            teams: updatedTeams,
            accounts: accounts
        ).normalized()
    }

    func deletingTeam(withID teamID: String) -> ContributionTeamStore {
        guard teamID != ContributionTeam.allFriendsID,
              teams.contains(where: { $0.id == teamID }) else {
            return self
        }

        let updatedTeams = teams.filter { $0.id != teamID }
        let nextSelectedTeamID = selectedTeamID == teamID ? ContributionTeam.allFriendsID : selectedTeamID

        return ContributionTeamStore(
            version: version,
            selectedTeamID: nextSelectedTeamID,
            teams: updatedTeams,
            accounts: accounts
        ).normalized()
    }

    func reorderingCustomTeams(from sourceIndex: Int, to destinationIndex: Int) -> ContributionTeamStore {
        var reorderedTeams = customTeams
        guard reorderedTeams.indices.contains(sourceIndex),
              destinationIndex >= 0,
              destinationIndex <= reorderedTeams.count else {
            return self
        }

        let movedTeam = reorderedTeams.remove(at: sourceIndex)
        let insertionIndex = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        reorderedTeams.insert(movedTeam, at: insertionIndex)

        return ContributionTeamStore(
            version: version,
            selectedTeamID: selectedTeamID,
            teams: [ContributionTeam.allFriends(accountIDs: accounts.map(\.id))] + reorderedTeams,
            accounts: accounts
        ).normalized()
    }

    func settingMembership(forAccountID accountID: String, inTeamID teamID: String, isIncluded: Bool) -> ContributionTeamStore {
        guard teamID != ContributionTeam.allFriendsID,
              accounts.contains(where: { $0.id == accountID }),
              teams.contains(where: { $0.id == teamID }) else {
            return self
        }

        let updatedTeams = teams.map { team in
            guard team.id == teamID else { return team }

            var updatedAccountIDs = team.accountIDs.filter { $0 != accountID }
            if isIncluded {
                updatedAccountIDs.insert(accountID, at: 0)
            }

            return ContributionTeam(id: team.id, name: team.name, accountIDs: updatedAccountIDs)
        }

        return ContributionTeamStore(
            version: version,
            selectedTeamID: selectedTeamID,
            teams: updatedTeams,
            accounts: accounts
        ).normalized()
    }

    static func migratedFromLegacyAccounts(_ accounts: [ContributionAccount]) -> ContributionTeamStore {
        let normalizedAccounts = normalizedAccounts(accounts)
        let allFriends = ContributionTeam.allFriends(accountIDs: normalizedAccounts.map(\.id))
        return ContributionTeamStore(
            version: currentVersion,
            selectedTeamID: allFriends.id,
            teams: [allFriends],
            accounts: normalizedAccounts
        )
    }

    static func migratedFromLegacyUsername(_ username: String) -> ContributionTeamStore {
        migratedFromLegacyAccounts([
            ContributionAccount(provider: .github, username: username)
        ])
    }

    static func normalizedAccounts(_ accounts: [ContributionAccount]) -> [ContributionAccount] {
        var seenIDs = Set<String>()
        var normalizedAccounts: [ContributionAccount] = []

        for account in accounts.map(Self.normalizedAccount) {
            guard seenIDs.insert(account.id).inserted else { continue }
            normalizedAccounts.append(account)
        }

        return normalizedAccounts
    }

    private static func normalizedAccount(_ account: ContributionAccount) -> ContributionAccount {
        ContributionAccount(
            provider: account.provider,
            username: account.username,
            serverOrigin: account.serverOrigin
        )
    }

    private static func normalizedAccountIDs(_ accountIDs: [String], validIDs: Set<String>) -> [String] {
        var seenIDs = Set<String>()
        var normalizedAccountIDs: [String] = []

        for accountID in accountIDs where validIDs.contains(accountID) {
            guard seenIDs.insert(accountID).inserted else { continue }
            normalizedAccountIDs.append(accountID)
        }

        return normalizedAccountIDs
    }
}
