//
//  GitHubContributionsWidget.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import Intents
import WidgetKit
import SwiftUI

struct GitHubContributionsWidget: Widget {
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: "fimuxd.gitget.github-contributions-widget",
            intent: ConfigurationIntent.self,
            provider: GitHubContributionsProvider()) { entry in
            GitHubContributionsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("GITGET")
        .description("GITHUB CONTRIBUTIONS")
        .supportedFamilies([.systemMedium])
    }
}
