//
//  SettingView.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var viewModel: ContributionViewModel
    
    var body: some View {
        VStack {
            Text("GitHub username을 입력하고 GitHub Contribution 잔디를 확인하세요")
            TextField("Enter your GitHub username", text: $viewModel.enteredUserName)
                .onSubmit {
                    viewModel.getContributions()
                }
            ZStack {
                if !viewModel.isInitial {
                    Text("invalid username😢")
                        .modifier(NoticeTextStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(Color.halloween3)
                        .opacity(viewModel.invalidUsername ? 1 : 0)
                }
                ContributionView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(viewModel.isInitial ? Color.default4 : Color.background)
                    .opacity(viewModel.invalidUsername ? 0 : 1)
            }
        }
        .padding(20)
    }
}
