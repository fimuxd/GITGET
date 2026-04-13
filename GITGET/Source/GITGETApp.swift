//
//  GITGETApp.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import SwiftUI

@main
struct GITGETApp: App {
    @StateObject private var viewModel = ContributionWorkspaceViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: viewModel)
        }
    }
}
