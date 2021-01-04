//
//  GitHubContributionsWidgetBundle.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/28/20.
//

import WidgetKit
import SwiftUI

@main
struct GitHubContributionWidgetBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        GitHubContributionsWidget()
    }
}
