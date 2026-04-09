//
//  GitHubContributionsWidget.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import WidgetKit
import SwiftUI

struct GitHubContributionsWidget: Widget {
    private let kind = "fimuxd.gitget.github-contributions-widget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: GitHubContributionsWidgetIntent.self,
            provider: GitHubContributionsProvider()
        ) { entry in
            GitHubContributionsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GITGET")
        .description("GITHUB CONTRIBUTIONS")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
        .contentMarginsDisabled()
        .containerBackgroundRemovable()
    }
}
