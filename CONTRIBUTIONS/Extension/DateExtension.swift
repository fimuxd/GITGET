//
//  DateExtension.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/29/20.
//

import Foundation

extension Date {
    func range(to: Date) -> [Date] {
        var tempDate = self
        var array = [tempDate]
        while tempDate < to {
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: tempDate) else {
                break
            }
            tempDate = nextDate
            array.append(tempDate)
        }
        return array
    }
    
    static func parse<K: CodingKey>(_ values: KeyedDecodingContainer<K>, key: K) -> Date? {
        guard let dateString = try? values.decode(String.self, forKey: key),
              let date = from(dateString: dateString) else {
            return nil
        }
        
        return date
    }
    
    static func from(dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "ko_kr")
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
}

extension Calendar {
    static let gitHubUTC: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }()
}

extension Date {
    var isGitHubToday: Bool {
        Calendar.gitHubUTC.isDate(self, inSameDayAs: Date())
    }

    var gitHubYear: Int {
        Calendar.gitHubUTC.component(.year, from: self)
    }

    var gitHubYearString: String {
        String(gitHubYear)
    }
}
