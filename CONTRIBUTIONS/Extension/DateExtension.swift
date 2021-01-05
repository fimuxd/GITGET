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
            tempDate = Calendar.current.date(byAdding: .day, value: 1, to: tempDate)!
            array.append(tempDate)
        }
        return array
    }
}
