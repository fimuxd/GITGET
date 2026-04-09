import Foundation

struct ContributionResponse: Codable {
    let contributions: [Contribution]
}

struct Contribution: Codable {
    enum Level: Int, CaseIterable, Codable {
        case zero, one, two, three, four
    }
    
    let date: Date
    let count: Int
    let level: Level
    
    enum CodingKeys: String, CodingKey {
        case date, count, level
    }
    
    init (date: Date, count: Int, level: Level) {
        self.date = date
        self.count = count
        self.level = level
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let dateString = try container.decode(String.self, forKey: .date)
        if let date = Self.date(from: dateString) {
            self.date = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Date string does not match format")
        }
        
        count = try container.decode(Int.self, forKey: .count)
        level = try container.decode(Level.self, forKey: .level)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateString = Self.string(from: date)
        
        try container.encode(dateString, forKey: .date)
        try container.encode(count, forKey: .count)
        try container.encode(level, forKey: .level)
    }

    static func date(from string: String) -> Date? {
        gitHubDateFormatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        gitHubDateFormatter.string(from: date)
    }

    private static let gitHubDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
}

extension Contribution.Level {
    static func random() -> Self {
        Self.allCases.randomElement()!
    }
}
