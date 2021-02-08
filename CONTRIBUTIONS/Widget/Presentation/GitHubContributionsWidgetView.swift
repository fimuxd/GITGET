//
//  GitHubContributionsWidgetView.swift
//  CONTRIBUTIONSExtension
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct GitHubContributionsWidgetView: View {
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
    
    var body: some View {
        WidgetContentView(viewModel: viewModel)
        .redacted(reason: viewModel.isInitial ? .placeholder : .init())
    }
}
