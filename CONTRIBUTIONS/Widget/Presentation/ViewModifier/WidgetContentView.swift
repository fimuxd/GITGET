//
//  WidgetContentView.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct WidgetContentView: View {
    @Environment(\.redactionReasons) var redactionReasons
    
    let username: String
    let todayContributionCount: Int?
    let cellColorSet: [[Color]]
    
    var body: some View {
        VStack() {
            HStack() {
                HStack(alignment: .center, spacing: 6) {
                    Text(username)
                }
                Spacer()
                todayContributionCount != nil
                    ? Text("CONTRIBUTIONS".localizedStringWithFormat(todayContributionCount ?? 0))
                    : Text("")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.gray)
            .textCase(.uppercase)
            .lineLimit(1)
            
            if cellColorSet.isEmpty {
                Text("need GitHub username🧑🏻‍💻")
                    .modifier(NoticeTextStyle())
            } else {
                CalendarChart(columns: 20) { row, column in
                    if let color = cellColorSet.element(at: row)?.element(at: column) {
                        color.modifier(CalendarChartCell())
                    } else {
                        Color.clear
                    }
                }
            }
        }
    }
}
