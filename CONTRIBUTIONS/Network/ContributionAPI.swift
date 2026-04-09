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
    static func contributions(of username: String) async -> Result<[Contribution], Error> {
        let trimmedUsername = username.trimmed
        guard !trimmedUsername.isEmpty else {
            return .success([])
        }

        let urlRequest = try! Router.contributions(trimmedUsername).asURLRequest()
        
        let response = await AF.request(urlRequest)
            .serializingString()
            .response
        
        switch response.result {
        case .failure(let error):
            return .failure(error)
        case .success(let result):
            do {
                return .success(try parseContributions(from: result))
            } catch {
                return .failure(error)
            }
        }
    }

    static func parseContributions(from html: String) throws -> [Contribution] {
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
        case contributions(_ username: String)
        
        var baseURL: URL { .gitHubContributionsAPI }
        
        var method: HTTPMethod {
            switch self {
            case .contributions:
                return .get
            }
        }
        
        var path: String {
            switch self {
            case .contributions:
                return "/contributions"
            }
        }
        
        var headers: HTTPHeaders {
            return [
                "Accept": "text/html,application/xhtml+xml",
                "Accept-Language": "en-US,en;q=0.9",
                "User-Agent": "GITGET"
            ]
        }
        
        func asURLRequest() throws -> URLRequest {
            var url = baseURL
            
            switch self {
            case .contributions(let username):
                url = url.appending(username) ?? url
                url = url.appending(path) ?? url
                return try URLRequest(url: url, method: method, headers: headers)
            }
        }
    }
}
