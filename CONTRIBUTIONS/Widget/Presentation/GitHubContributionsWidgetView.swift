//
//  GitHubContributionsWidgetView.swift
//  CONTRIBUTIONSExtension
//
//  Created by Bo-Young PARK on 12/28/20.
//

import SwiftUI

struct GitHubContributionsWidgetView: View {
    let viewModel: GitHubContributionsWidgetViewModel
    
    init(viewModel: GitHubContributionsWidgetViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        WidgetContentView(
            username: viewModel.username ?? "",
            todayContributionCount: viewModel.todayContributionCount,
            cellColorSet: viewModel.cellColorSet
        )
        .redacted(reason: viewModel.isInitial ? .placeholder : .init())
    }
}
