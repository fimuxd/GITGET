//
//  AccessoryWidgetContentView.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/11.
//

import SwiftUI
import WidgetKit

@available(iOS 16.0, *)
struct AccessoryWidgetContentView: View {
    let viewModel: GitHubContributionsWidgetViewModel

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            let cellColorSet = viewModel.cellColorSet(columnsCount: 12)
            if cellColorSet.isEmpty {
                Text("need GitHub username🧑🏻‍💻")
                    .modifier(NoticeTextStyle())
            } else {
                CalendarChart(columns: 13, spacing: 1.5) { row, column in
                    if let color = cellColorSet.element(at: row)?.element(at: column) {
                        if color != .level0 {
                            Color.default4
                                .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
                        } else {
                            Color.level0
                                .clipShape(RoundedRectangle(cornerRadius: 1.5, style: .continuous))
                        }
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 56)
            }
        }
    }
}
