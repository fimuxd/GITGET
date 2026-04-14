//
//  WidgetContentView.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct WidgetContentView: SwiftUI.View {
    @Environment(\.widgetFamily) var widgetFamily
    
    let viewModel: GitHubContributionsWidgetViewModel
    var columnsCount: Int {
        switch widgetFamily {
        case .systemSmall:
            return 9
        default:
            return 20
        }
    }
    
    var body: some SwiftUI.View {
        VStack {
            let cellColorSet = viewModel.cellColorSet(columnsCount: columnsCount)
            if cellColorSet.isEmpty {
                Text("need \(viewModel.providerDisplayName) username🧑🏻‍💻")
                    .modifier(NoticeTextStyle())
            } else {
                if widgetFamily == .systemLarge {
                    HStack {
                        Spacer()
                        Text("CONTRIBUTIONS".localizedStringWithFormat(viewModel.currentYearContributions) + " IN " + Date().gitHubYearString)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.widgetSecondaryText)
                            .textCase(.uppercase)
                            .lineLimit(1)
                    }
                }
                
                HStack {
                    HStack(alignment: .center, spacing: 6) {
                        Text(viewModel.displayUsername)
                    }
                    Spacer()
                    viewModel.todayContributionCount != nil && widgetFamily != .systemSmall
                        ? Text("CONTRIBUTIONS".localizedStringWithFormat(viewModel.todayContributionCount ?? 0) + " TODAY")
                        : Text("")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.widgetSecondaryText)
                .textCase(.uppercase)
                .lineLimit(1)
                
                CalendarChart(columns: columnsCount, spacing: 3.0) { row, column in
                    if let color = cellColorSet.element(at: row)?.element(at: column) {
                        color.modifier(CalendarChartCell())
                    } else {
                        Color.clear
                    }
                }
                .frame(height: widgetFamily == .systemSmall ? 100 : 110)
                
                if widgetFamily == .systemLarge {
                    Color.level0.frame(height: 1)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(viewModel.displayUsername)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.widgetPrimaryText)

                        Text(viewModel.bio)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color.widgetPrimaryText)
                        
                        HStack {
                            Image(systemName: "location.circle")
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color.widgetPrimaryText)
                            Text(" " + viewModel.location)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.widgetPrimaryText)
                        }
                        
                        HStack {
                            Image(systemName: "building")
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color.widgetPrimaryText)
                            Text(" " + viewModel.company)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color.widgetPrimaryText)
                        }
                        
                        HStack {
                            Image(systemName: "person.2")
                                .frame(width: 12, height: 12)
                                .foregroundColor(Color.widgetPrimaryText)
                            Text(" " + viewModel.followers)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.widgetPrimaryText)
                            Text("followers |")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.widgetSecondaryText)
                            Text(viewModel.following)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.widgetPrimaryText)
                            Text("following")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.widgetSecondaryText)
                        }
                        
                        HStack {
                            Spacer()
                            Text(verbatim: "develop since \(viewModel.startYear)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.widgetSecondaryText)
                        }
                    }
                    .padding([.leading, .trailing], 10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
