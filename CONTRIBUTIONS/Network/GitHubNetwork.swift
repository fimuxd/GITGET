//
//  GitHubNetwork.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import Combine
import SwiftSoup
import SwiftDate

enum GitHubNetworkError: Error {
    case error(String)
    case invalidURL
    case htmlParsingError
    case jsonDecodingError
    case defaultError
    
    var message: String? {
        switch self {
        case let .error(msg):
            return msg
        case .invalidURL:
            return "### Error: invalid URL-getContributions @GitHubNetwork.swift ###"
        case .htmlParsingError:
            return "### Error: HTML parsing @GitHubNetwork.swift ###"
        case .jsonDecodingError:
            return "### Error: JSON Decoding @GitHubNetwork.swift ###"
        case .defaultError:
            return "잠시 후에 다시 시도해주세요."
        }
    }
}

struct GitHubNetwork {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func getContributions(of username: String) -> AnyPublisher<[Contribution], GitHubNetworkError> {
        var request = URLRequest(url: URL(string: "https://typescript.nestjs.kinest1997.com/github/contributions?username=\(username)&years=last")!)
        request.httpMethod = "GET"
        return session.dataTaskPublisher(for: request)
            .mapError({ _ in
                GitHubNetworkError.invalidURL
            })
            .flatMap { data in
                return Just(data.data)
                    .decode(type: ContributionResponse.self, decoder: JSONDecoder())
                    .mapError { _ in
                        GitHubNetworkError.jsonDecodingError
                    }
                    .map {
                        return $0.contributions
                            .filter {
                                $0.date <= Date()
                            }
                            .sorted { $0.date < $1.date }
                    }
            }
            .eraseToAnyPublisher()
    }
    
    func getUser(of username: String) -> AnyPublisher<User, GitHubNetworkError> {
        guard let url = getUser(of: username).url else {
            let error = GitHubNetworkError.invalidURL
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: URLRequest(url: url))
            .mapError { error in
                GitHubNetworkError.error("###Error: \(error)")
            }
            .print("xxx0")
            .flatMap { data in
                return Just(data.data)
                    .decode(type: User.self, decoder: JSONDecoder())
                    .mapError { _ in
                        GitHubNetworkError.jsonDecodingError
                    }
            }
            .eraseToAnyPublisher()
    }
}

//URLComponents
extension GitHubNetwork {
    struct GitHubURL {
        static let scheme = "https"
        static let host = "github.com"
        static let path = "/users"
    }
    
    func composeURLComponentsToGetContributions(of username: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = GitHubURL.scheme
        components.host = GitHubURL.host
        components.path = GitHubURL.path + "/\(username)" + "/contributions"
        
        return components
    }
    
    func getUser(of username: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = GitHubURL.scheme
        components.host = "api." + GitHubURL.host
        components.path = GitHubURL.path + "/\(username)"
        
        return components
    }
}

//HTML Parsing
extension GitHubNetwork {
    func parseContributions(from element: Element) throws -> Contribution? {
        let dataLevel = try element.attr("data-level")
        
        var count: Int = 0
        let parstDataCount = try element.html()
        
        if let splitDataCount = parstDataCount.split(separator: " ").first {
            if let dataCount = Int(splitDataCount) {
                count = dataCount
            } else {
                count = 0
            }
        } else {
            count = 0
        }
        
        
        let dataDate = try element.attr("data-date")
        
        guard let level = Int(dataLevel),
              let date = Date(dataDate) else {
            return nil
        }
        
        return Contribution(date: date, count: count, level: Contribution.Level(rawValue: level) ?? .zero)
    }
}
