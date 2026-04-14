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
    private static let requestTimeout: TimeInterval = 8

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

    static func parseGitLabCalendar(_ calendar: [String: Int]) throws -> [Contribution] {
        try parseGitLabContributions(from: calendar)
    }

    static func parseGitLabEvents(_ events: [GitLabEvent], today: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> [Contribution] {
        parseGitLabContributions(from: events, today: today, calendar: calendar)
    }

    private static func gitHubContributions(of account: ContributionAccount) async -> Result<[Contribution], Error> {
        guard let urlRequest = try? Router.gitHubContributions(account).asURLRequest() else {
            return .failure(AFError.parameterEncodingFailed(reason: .missingURL))
        }

        let response = await AF.request(urlRequest)
            .serializingString()
            .response

        switch response.result {
        case .failure(let error):
            return .failure(ContributionRequestError.from(error, endpoint: "GitHub contribution graph"))
        case .success(let result):
            if let statusCode = response.response?.statusCode,
               !(200..<300).contains(statusCode) {
                return .failure(ContributionRequestError.httpStatus(endpoint: "GitHub contribution graph", statusCode: statusCode))
            }

            do {
                return .success(try parseGitHubContributions(from: result))
            } catch {
                return .failure(ContributionRequestError.invalidResponse(endpoint: "GitHub contribution graph"))
            }
        }
    }

    private static func gitLabContributions(of account: ContributionAccount) async -> Result<[Contribution], Error> {
        guard let urlRequest = try? Router.gitLabCalendar(account).asURLRequest() else {
            return .failure(AFError.parameterEncodingFailed(reason: .missingURL))
        }

        let authorizedRequest = await GitLabRequestAuthorization.authorizedRequest(urlRequest, for: account)
        let response = await AF.request(authorizedRequest)
            .serializingData()
            .response

        switch response.result {
        case .failure(let error):
            return .failure(ContributionRequestError.from(error, endpoint: "GitLab contribution graph"))
        case .success(let result):
            if let statusCode = response.response?.statusCode,
               !(200..<300).contains(statusCode) {
                return .failure(ContributionRequestError.httpStatus(endpoint: "GitLab contribution graph", statusCode: statusCode))
            }

            do {
                let calendar = try JSONDecoder().decode([String: Int].self, from: result)
                return .success(try parseGitLabContributions(from: calendar))
            } catch {
                return .failure(ContributionRequestError.invalidResponse(endpoint: "GitLab contribution graph"))
            }
        }
    }

    private static func gitLabEvents(of account: ContributionAccount) async throws -> [GitLabEvent] {
        let calendarUTC = Calendar.gitHubUTC
        let today = calendarUTC.startOfDay(for: Date())
        let startDate = calendarUTC.date(byAdding: .day, value: -364, to: today) ?? today
        let endDate = calendarUTC.date(byAdding: .day, value: 1, to: today) ?? today

        let userResult = await UserAPI.userInfo(of: account)
        guard case .success(let user) = userResult,
              let userID = user.id else {
            throw ContributionRequestError.notFound(endpoint: "GitLab contribution graph")
        }

        var page = 1
        var allEvents: [GitLabEvent] = []

        while true {
            guard let urlRequest = try? Router.gitLabContributionEvents(
                account,
                userID: userID,
                after: Contribution.string(from: startDate),
                before: Contribution.string(from: endDate),
                page: page,
                perPage: 100
            ).asURLRequest() else {
                throw AFError.parameterEncodingFailed(reason: .missingURL)
            }

            let authorizedRequest = await GitLabRequestAuthorization.authorizedRequest(urlRequest, for: account)
            let response = await AF.request(authorizedRequest)
                .serializingData()
                .response

            switch response.result {
            case .failure(let error):
                throw ContributionRequestError.from(error, endpoint: "GitLab contribution graph")
            case .success(let result):
                if let statusCode = response.response?.statusCode,
                   !(200..<300).contains(statusCode) {
                    throw ContributionRequestError.httpStatus(endpoint: "GitLab contribution graph", statusCode: statusCode)
                }

                let decodedEvents: [GitLabEvent]
                do {
                    decodedEvents = try JSONDecoder().decode([GitLabEvent].self, from: result)
                } catch {
                    throw ContributionRequestError.invalidResponse(endpoint: "GitLab contribution graph")
                }

                allEvents.append(contentsOf: decodedEvents)

                let nextPage = response.response?.headers["X-Next-Page"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if nextPage.isEmpty || decodedEvents.isEmpty {
                    return allEvents
                }

                page = Int(nextPage) ?? (page + 1)
            }
        }
    }

    private static func parseGitHubContributions(from html: String) throws -> [Contribution] {
        let document = try SwiftSoup.parseBodyFragment(html)
        let dayElements = try document.select(".ContributionCalendar-day, [data-date][data-level]")
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

    private static func parseGitLabContributions(from calendar: [String: Int]) throws -> [Contribution] {
        let calendarUTC = Calendar.gitHubUTC
        let today = calendarUTC.startOfDay(for: Date())
        let startDate = calendarUTC.date(byAdding: .day, value: -364, to: today) ?? today
        let dates = startDate.range(to: today)

        let countsByDate = calendar.reduce(into: [Date: Int]()) { partialResult, entry in
            guard let date = gitLabContributionDate(from: entry.key) else { return }
            partialResult[calendarUTC.startOfDay(for: date)] = entry.value
        }

        if !calendar.isEmpty && countsByDate.isEmpty {
            throw ContributionRequestError.invalidResponse(endpoint: "GitLab contribution graph")
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

    private static func parseGitLabContributions(from events: [GitLabEvent], today: Date = Date(), calendar: Calendar = .autoupdatingCurrent) -> [Contribution] {
        let normalizedToday = calendar.startOfDay(for: today)
        let startDate = calendar.date(byAdding: .day, value: -364, to: normalizedToday) ?? normalizedToday
        let dates = startDate.range(to: normalizedToday)

        let countsByDate = events.reduce(into: [Date: Int]()) { partialResult, event in
            guard event.qualifiesAsContribution else {
                return
            }

            let normalizedDate = calendar.startOfDay(for: event.createdAt)
            guard normalizedDate >= startDate, normalizedDate <= normalizedToday else {
                return
            }

            partialResult[normalizedDate, default: 0] += 1
        }

        let maxCount = countsByDate.values.max() ?? 0
        return dates.map { date in
            let normalizedDate = calendar.startOfDay(for: date)
            let count = countsByDate[normalizedDate] ?? 0
            return Contribution(date: normalizedDate, count: count, level: gitLabLevel(for: count, maxCount: maxCount))
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

    private static func gitLabContributionDate(from value: String) -> Date? {
        if let parsedDate = Contribution.date(from: value) {
            return parsedDate
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.count >= 10 else {
            return nil
        }

        let prefix = String(trimmedValue.prefix(10))
        return Contribution.date(from: prefix)
    }
}

extension ContributionAPI {
    struct GitLabEvent: Decodable {
        let createdAt: Date
        let actionName: String
        let targetType: String?
        let pushData: PushData?
        let note: Note?

        enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
            case actionName = "action_name"
            case targetType = "target_type"
            case pushData = "push_data"
            case note
        }

        var qualifiesAsContribution: Bool {
            let action = actionName.lowercased()
            let target = contributionTarget

            switch action {
            case "approved":
                return target == "mergerequest"
            case "accepted", "merged":
                return target == "mergerequest"
            case "opened", "created":
                return ["design", "epic", "issue", "mergerequest", "milestone", "project", "wikipage", "workitem", "designmanagement::design"].contains(target ?? "")
            case "closed":
                return ["epic", "issue", "mergerequest", "milestone", "workitem"].contains(target ?? "")
            case "reopened":
                return ["epic", "issue", "mergerequest", "milestone"].contains(target ?? "")
            case "updated":
                return ["design", "designmanagement::design", "wikipage"].contains(target ?? "")
            case "destroyed":
                return ["design", "designmanagement::design", "milestone", "wikipage"].contains(target ?? "")
            case "commented on", "commented":
                return ["alert", "commit", "design", "designmanagement::design", "issue", "mergerequest", "snippet"].contains(target ?? "")
            case "joined", "left", "expired":
                return true
            case "deleted":
                return pushData?.isContributionRemoval == true
            default:
                if action.hasPrefix("pushed") {
                    return pushData?.isContributionPush == true
                }
                return false
            }
        }

        private var contributionTarget: String? {
            if actionName.lowercased().contains("comment") {
                return note?.noteableType?.lowercased() ?? targetType?.lowercased()
            }

            return targetType?.lowercased() ?? note?.noteableType?.lowercased()
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            guard let createdAt = Date.parse(container, key: .createdAt) else {
                throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format")
            }
            self.createdAt = createdAt
            self.actionName = try container.decode(String.self, forKey: .actionName)
            self.targetType = try container.decodeIfPresent(String.self, forKey: .targetType)
            self.pushData = try container.decodeIfPresent(PushData.self, forKey: .pushData)
            self.note = try container.decodeIfPresent(Note.self, forKey: .note)
        }

        struct PushData: Decodable {
            let commitCount: Int?
            let action: String?
            let refType: String?

            enum CodingKeys: String, CodingKey {
                case commitCount = "commit_count"
                case action
                case refType = "ref_type"
            }

            var isContributionPush: Bool {
                (commitCount ?? 0) > 0 || action == "created"
            }

            var isContributionRemoval: Bool {
                action == "removed" && refType == "branch"
            }
        }

        struct Note: Decodable {
            let noteableType: String?

            enum CodingKeys: String, CodingKey {
                case noteableType = "noteable_type"
            }
        }
    }

    enum Router: URLRequestConvertible {
        case gitHubContributions(_ account: ContributionAccount)
        case gitLabCalendar(_ account: ContributionAccount)
        case gitLabContributionEvents(_ account: ContributionAccount, userID: Int, after: String, before: String, page: Int, perPage: Int)

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
                var request = try URLRequest(url: url, method: method, headers: headers)
                request.timeoutInterval = requestTimeout
                return request

            case .gitLabCalendar(let account):
                var url = URL.contributionsAPI(account: account)
                url = url.appending(account.username) ?? url
                url = url.appending("calendar.json") ?? url
                var request = try URLRequest(url: url, method: method, headers: headers)
                request.timeoutInterval = requestTimeout
                return request

            case .gitLabContributionEvents(let account, let userID, let after, let before, let page, let perPage):
                var url = URL.userAPI(account: account)
                url = url.appending(String(userID)) ?? url
                url = url.appending("events") ?? url
                url = url
                    .appendingQuery(name: "after", value: after)
                    .appendingQuery(name: "before", value: before)
                    .appendingQuery(name: "page", value: String(page))
                    .appendingQuery(name: "per_page", value: String(perPage))
                    .appendingQuery(name: "scope", value: "all")
                var request = try URLRequest(url: url, method: method, headers: headers)
                request.timeoutInterval = requestTimeout
                return request
            }
        }
    }
}
