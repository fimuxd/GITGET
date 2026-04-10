//
//  ContributionAPI.swift
//  GITGET
//
//  Created by Bo-Young Park on 2024-10-07.
//

import Foundation
import Alamofire
import SwiftSoup

enum ContributionAPI {
    static func contributions(of account: ContributionAccount) async -> Result<[Contribution], Error> {
        let normalizedAccount = ContributionAccount(
            provider: account.provider,
            username: account.username.trimmed,
            serverOrigin: account.serverOrigin
        )
        guard !normalizedAccount.username.isEmpty else {
            return .success([])
        }

        switch normalizedAccount.provider {
        case .github:
            return await gitHubContributions(of: normalizedAccount)
        case .gitlab:
            return await gitLabContributions(of: normalizedAccount)
        }
    }

    static func contributions(of username: String, provider: ContributionProvider, serverOrigin: String? = nil) async -> Result<[Contribution], Error> {
        await contributions(of: ContributionAccount(provider: provider, username: username, serverOrigin: serverOrigin))
    }

    static func parseContributions(from html: String) throws -> [Contribution] {
        try parseGitHubContributions(from: html)
    }

    private static func gitHubContributions(of account: ContributionAccount) async -> Result<[Contribution], Error> {
        let urlRequest = try! Router.gitHubContributions(account).asURLRequest()

        let response = await AF.request(urlRequest)
            .serializingString()
            .response

        switch response.result {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            do {
                return .success(try parseGitHubContributions(from: result))
            } catch {
                return .failure(error)
            }
        }
    }

    private static func gitLabContributions(of account: ContributionAccount) async -> Result<[Contribution], Error> {
        let urlRequest = try! Router.gitLabContributions(account).asURLRequest()

        let response = await AF.request(urlRequest)
            .serializingData()
            .response

        switch response.result {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            do {
                let calendar = try JSONDecoder().decode([String: Int].self, from: result)
                return .success(parseGitLabContributions(from: calendar))
            } catch {
                return .failure(error)
            }
        }
    }

    private static func parseGitHubContributions(from html: String) throws -> [Contribution] {
        let document = try SwiftSoup.parseBodyFragment(html)
        let dayElements = try document.select(".ContributionCalendar-day")
        let tooltipElements = try document.select("tool-tip[for]")

        let countsByElementID = try tooltipElements.array().reduce(into: [String: Int]()) { partialResult, element in
            let elementID = try element.attr("for")
            let tooltipText = try element.text()
            partialResult[elementID] = contributionCount(from: tooltipText)
        }

        let contributions = try dayElements.array().compactMap { element -> Contribution? in
            let dateString = try element.attr("data-date")
            guard let date = Contribution.date(from: dateString) else {
                return nil
            }

            let rawLevel = Int(try element.attr("data-level")) ?? 0
            let level = Contribution.Level(rawValue: rawLevel) ?? .zero
            let count = countsByElementID[try element.attr("id")] ?? 0
            return Contribution(date: date, count: count, level: level)
        }
        .sorted { $0.date < $1.date }

        guard !contributions.isEmpty else {
            throw AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        }

        return contributions
    }

    private static func parseGitLabContributions(from calendar: [String: Int]) -> [Contribution] {
        let calendarUTC = Calendar.gitHubUTC
        let today = calendarUTC.startOfDay(for: Date())
        let startDate = calendarUTC.date(byAdding: .day, value: -364, to: today) ?? today
        let dates = startDate.range(to: today)

        let countsByDate = calendar.reduce(into: [Date: Int]()) { partialResult, entry in
            guard let date = Contribution.date(from: entry.key) else { return }
            partialResult[calendarUTC.startOfDay(for: date)] = entry.value
        }

        let maxCount = countsByDate.values.max() ?? 0

        return dates.map { date in
            let normalizedDate = calendarUTC.startOfDay(for: date)
            let count = countsByDate[normalizedDate] ?? 0
            return Contribution(
                date: normalizedDate,
                count: count,
                level: gitLabLevel(for: count, maxCount: maxCount)
            )
        }
    }

    private static func gitLabLevel(for count: Int, maxCount: Int) -> Contribution.Level {
        guard count > 0, maxCount > 0 else {
            return .zero
        }

        let ratio = Double(count) / Double(maxCount)
        switch ratio {
        case ..<0.25:
            return .one
        case ..<0.5:
            return .two
        case ..<0.75:
            return .three
        default:
            return .four
        }
    }

    private static func contributionCount(from tooltipText: String) -> Int {
        let pattern = #"(?i)\b(no|[0-9,]+)\s+contribution"#

        guard let range = tooltipText.range(of: pattern, options: .regularExpression) else {
            return 0
        }

        let matchedText = String(tooltipText[range]).lowercased()
        if matchedText.hasPrefix("no") {
            return 0
        }

        let numericText = matchedText
            .replacingOccurrences(of: " contribution", with: "")
            .replacingOccurrences(of: ",", with: "")

        return Int(numericText) ?? 0
    }
}

extension ContributionAPI {
    enum Router: URLRequestConvertible {
        case gitHubContributions(_ account: ContributionAccount)
        case gitLabContributions(_ account: ContributionAccount)

        var method: HTTPMethod { .get }

        var headers: HTTPHeaders {
            [
                "Accept": "text/html,application/xhtml+xml,application/json",
                "Accept-Language": "en-US,en;q=0.9",
                "User-Agent": "GITGET"
            ]
        }

        func asURLRequest() throws -> URLRequest {
            switch self {
            case .gitHubContributions(let account):
                var url = URL.contributionsAPI(account: account)
                url = url.appending(account.username) ?? url
                url = url.appending("/contributions") ?? url
                return try URLRequest(url: url, method: method, headers: headers)

            case .gitLabContributions(let account):
                var url = URL.contributionsAPI(account: account)
                url = url.appending(account.username) ?? url
                url = url.appending("/calendar.json") ?? url
                return try URLRequest(url: url, method: method, headers: headers)
            }
        }
    }
}
