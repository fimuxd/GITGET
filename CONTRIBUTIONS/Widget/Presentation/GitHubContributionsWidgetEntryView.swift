//
//  GitHubContributionsWidgetEntryView.swift
//  CONTRIBUTIONSExtension
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct GitHubContributionsWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    let entry: GitHubContributionsWidgetViewModel
    
    var body: some View {
        if entry.invalidUsername {
            Text("invalid username😢")
                .modifier(NoticeTextStyle())
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .background(Color.halloween3)
        } else {
            switch widgetFamily {
            case .systemSmall:
                GitHubContributionsWidgetView(viewModel: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(entry.isInitial ? Color.default4 : Color.background)
            case .systemMedium:
                GitHubContributionsWidgetView(viewModel: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(entry.isInitial ? Color.default4 : Color.background)
            case .systemLarge:
                GitHubContributionsWidgetView(viewModel: entry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(entry.isInitial ? Color.default4 : Color.background)
            default:
                EmptyView()
            }
        }
    }
}
