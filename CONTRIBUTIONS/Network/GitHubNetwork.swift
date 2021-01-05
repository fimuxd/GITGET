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
    
    func getContributions(of username: String) -> Future<[Contribution], GitHubNetworkError> {
        Future { promise in
            guard let url = composeURLComponentsToGetContributions(of: username).url else {
                let error = GitHubNetworkError.invalidURL
                return promise(.failure(error))
            }
            
            do {
                let html = try String(contentsOf: url, encoding: .utf8)
                let document = try SwiftSoup.parse(html)
                let defaultColor = try parseDefaultColorSet(from: document)
                let contributions = try document.select("rect").compactMap { try parseContributions(from: $0, colors: defaultColor) }
                return promise(.success(contributions))
            } catch {
                return promise(.failure(.htmlParsingError))
            }
        }
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
    func parseDefaultColorSet(from document: Document) throws -> [String] {
        try document.getElementsByClass("legend").first()?.children().map { try $0.attr("style") } ?? []
    }
    
    func parseContributions(from element: Element, colors: [String]) throws -> Contribution? {
        let fill = try element.attr("fill")
        let dataCount = try element.attr("data-count")
        let dataDate = try element.attr("data-date")
        
        guard let colorID = colors.firstIndex(where: { $0.contains(fill) }),
              let count = Int(dataCount),
              let date = Date(dataDate) else {
            return nil
        }
        
        return Contribution(date: date, count: count, level: Contribution.Level(rawValue: colorID) ?? .zero)
    }
}
