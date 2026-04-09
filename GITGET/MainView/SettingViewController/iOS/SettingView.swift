//
//  SettingView.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI

struct SettingView: View {
    @State private var showHowToUse = false
    @State private var showAbout = false
    @ObservedObject var viewModel: ContributionViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("GitHub username을 입력하고 GitHub Contribution 잔디를 확인하세요")
                        .font(.system(size: 16, weight: .regular, design: .monospaced))

                    TextField("Enter your GitHub username", text: $viewModel.enteredUserName)
                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.getContributions(by: viewModel.enteredUserName)
                        }

                    contentCard

                    if !viewModel.isInitial {
                        actionButtons
                    }
                }
                .padding(20)
            }
            .background(Color("background").ignoresSafeArea())
            .navigationTitle("GitGet".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showHowToUse) {
                TutorialView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
                    .presentationDetents([.height(353)])
            }
        }
    }

    @ViewBuilder
    private var contentCard: some View {
        ZStack {
            if !viewModel.isInitial && viewModel.invalidUsername {
                Text("invalid username😢")
                    .modifier(NoticeTextStyle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .background(Color.halloween3)
            } else {
                ContributionView(viewModel: viewModel)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isInitial ? Color.default4 : Color.background)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showHowToUse = true
            } label: {
                actionLabel("HOW TO USE".localized)
            }

            Button {
                showAbout = true
            } label: {
                actionLabel("About".localized)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.default4)
            )
    }
}
