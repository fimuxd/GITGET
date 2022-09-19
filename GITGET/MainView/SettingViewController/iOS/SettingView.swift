//
//  SettingView.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI

struct SettingView: View {
    @State private var showHowToUse: Bool = false
    @ObservedObject var viewModel: ContributionViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("GitHub username을 입력하고 GitHub Contribution 잔디를 확인하세요")
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .unredacted()
            TextField("Enter your GitHub username", text: $viewModel.enteredUserName)
                .font(.system(size: 16, weight: .regular, design: .monospaced))
                .unredacted()
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.getContributions(by: viewModel.enteredUserName)
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
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isInitial ? Color.default4 : Color.background)
                    .opacity(viewModel.invalidUsername ? 0 : 1)
            }
            
            VStack(alignment: .center) {
                Button {
                    showHowToUse = true
                } label: {
                    Text("HOW TO USE".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 50)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.default4)
                        )
                }
                .sheet(isPresented: $showHowToUse) {
                    TutorialView()
                }
            }
            .opacity(viewModel.isInitial ? 0 : 1)
            
            Spacer(minLength: 200)
        }
        .padding(20)
    }
}
