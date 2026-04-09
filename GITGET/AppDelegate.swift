//
//  AppDelegate.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import SwiftUI

@main
struct GITGETApp: App {
    @StateObject private var viewModel = ContributionViewModel()

    var body: some Scene {
        WindowGroup {
            SettingView(viewModel: viewModel)
        }
    }
}
