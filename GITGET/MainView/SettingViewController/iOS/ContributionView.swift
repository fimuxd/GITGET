//
//  ContributionView.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI
import Kingfisher

struct ContributionView: View {
    @ObservedObject var viewModel: ContributionViewModel
    
    var body: some View {
        VStack {
            let cellColorSet = viewModel.cellColorSet(columnsCount: 20)
            if cellColorSet.isEmpty {
                Text("need GitHub username🧑🏻‍💻")
                    .modifier(NoticeTextStyle())
            } else {
                HStack {
                    Spacer()
                    Text("CONTRIBUTIONS".localizedStringWithFormat(viewModel.currentYearContributions) + " IN " + String(Date().year))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                        .lineLimit(1)
                }
                
                HStack {
                    HStack(alignment: .center, spacing: 6) {
                        Text(viewModel.name)
                    }
                    Spacer()
                    viewModel.todayContributionCount != nil
                    ? Text("%d CONTRIBUTIONS".localizedStringWithFormat(viewModel.todayContributionCount ?? 0) + " TODAY")
                    : Text("")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .lineLimit(1)
                
                CalendarChart(columns: 20, spacing: 3.0) { row, column in
                    if let color = cellColorSet.element(at: row)?.element(at: column) {
                        color.modifier(CalendarChartCell())
                    } else {
                        Color.clear
                    }
                }
                .frame(height: 110)
                
                Color.level0.frame(height: 1)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.username)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.blackAndWhite4)
                    
                    Text(viewModel.bio)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.blackAndWhite4)
                    
                    HStack {
                        Image(systemName: "location.circle")
                            .frame(width: 12, height: 12)
                            .foregroundColor(.blackAndWhite4)
                        Text(" " + viewModel.location)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.blackAndWhite4)
                    }
                    
                    HStack {
                        Image(systemName: "building")
                            .frame(width: 12, height: 12)
                            .foregroundColor(.blackAndWhite4)
                        Text(" " + viewModel.company)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.blackAndWhite4)
                    }
                    
                    HStack {
                        Image(systemName: "person.2")
                            .frame(width: 12, height: 12)
                            .foregroundColor(.blackAndWhite4)
                        Text(" " + viewModel.followers)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blackAndWhite4)
                        Text("followers |")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.blackAndWhite3)
                        Text(viewModel.following)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.blackAndWhite4)
                        Text("following")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.blackAndWhite3)
                    }
                    
                    HStack {
                        Spacer()
                        Text("develop since \(viewModel.startYear)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.blackAndWhite3)
                    }
                }
                .padding([.leading, .trailing], 10)
            }
        }
    }
}

