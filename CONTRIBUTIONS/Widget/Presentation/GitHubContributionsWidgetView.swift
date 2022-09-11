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
    
    var body: some View {
        WidgetContentView(viewModel: viewModel)
        .redacted(reason: viewModel.isInitial ? .placeholder : .init())
    }
}
