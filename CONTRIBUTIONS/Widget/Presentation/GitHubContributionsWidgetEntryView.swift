//
//  GitHubContributionsWidgetEntryView.swift
//  CONTRIBUTIONSExtension
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct GitHubContributionsWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.widgetContentMargins) private var widgetContentMargins
    let entry: GitHubContributionsWidgetViewModel
    
    var body: some View {
        if entry.invalidUsername {
            invalidUsernameView
        } else {
            switch widgetFamily {
            case .systemSmall:
                GitHubContributionsWidgetView(viewModel: entry)
                    .widgetContainerBackground(color: entry.isInitial ? .default4 : .background)
                    .padding(widgetContentMargins)
            case .systemMedium:
                GitHubContributionsWidgetView(viewModel: entry)
                    .widgetContainerBackground(color: entry.isInitial ? .default4 : .background)
                    .padding(widgetContentMargins)
            case .systemLarge:
                GitHubContributionsWidgetView(viewModel: entry)
                    .widgetContainerBackground(color: entry.isInitial ? .default4 : .background)
                    .padding(widgetContentMargins)
            case .accessoryRectangular:
                AccessoryWidgetContentView(viewModel: entry)
                    .padding(widgetContentMargins)
            default:
                EmptyView()
            }
        }
    }

    private var invalidUsernameView: some View {
        Text("invalid username😢")
            .modifier(NoticeTextStyle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(widgetContentMargins)
            .widgetContainerBackground(color: .halloween3)
    }
}

private extension View {
    func widgetContainerBackground(color: Color) -> some View {
        containerBackground(for: .widget) {
            color
        }
    }
}
