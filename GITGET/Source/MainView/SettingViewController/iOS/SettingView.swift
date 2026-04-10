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
        TabView {
            friendsTab
                .tabItem {
                    Label("Friends", systemImage: "person.3")
                }
                .accessibilityIdentifier("tab-friends")

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "paintpalette")
                }
                .accessibilityIdentifier("tab-settings")
        }
        .tint(viewModel.selectedTheme.levelFourColor)
        .accessibilityIdentifier("setting.tabView")
    }

    private var friendsTab: some View {
        NavigationStack {
            List {
                addFriendSection
                friendListSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("background").ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if UITestSupport.isEnabled,
                   UITestSupport.scenario == .greenFriend,
                   let greenProfile = viewModel.profiles.first(where: { $0.uiIdentifier == "github-green-friend" }) {
                    Button("Delete Green Friend") {
                        viewModel.removeProfile(greenProfile)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("profile-delete-github-green-friend")
                    .background(Color("background"))
                }
            }
            .navigationTitle("GitGet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refreshAll()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("friends-refresh-button")
                }
            }
        }
    }

    private var addFriendSection: some View {
        Section {
            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(ContributionProvider.allCases) { provider in
                    Text(provider.title).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("provider-picker")

            HStack(spacing: 12) {
                TextField("Enter username", text: $viewModel.enteredUserName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityIdentifier("friends.usernameField")
                    .onSubmit {
                        viewModel.addAccount()
                    }
                    .accessibilityIdentifier("username-field")

                Button("Add") {
                    viewModel.addAccount()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("add-account-button")
            }

            TextField(
                "Server URL (optional)",
                text: $viewModel.enteredServerOrigin,
                prompt: Text(viewModel.selectedProvider.serverOriginPlaceholder)
            )
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.URL)
            .textContentType(.URL)
            .accessibilityIdentifier("server-origin-field")

            Text("Optional for GitHub Enterprise Server or self-managed GitLab.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .accessibilityIdentifier("server-origin-helper")
        } header: {
            Text("Add Friend")
        }
    }

    private var friendListSection: some View {
        Section {
            if viewModel.profiles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No friends yet")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .accessibilityIdentifier("friends.emptyStateTitle")
                    Text("Start with your own account, then add teammates or friends to compare activity at a glance.")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .accessibilityIdentifier("friends-empty-state")
            } else {
                ForEach(viewModel.profiles) { profile in
                    ContributionView(
                        profile: profile,
                        theme: viewModel.selectedTheme,
                        cellColors: viewModel.cellColorSet(for: profile, columnsCount: 20),
                        onDelete: {
                            viewModel.removeProfile(profile)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.removeProfile(profile)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

            }
        } header: {
            Text("Friends")
        }
    }

    private var settingsTab: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    Picker("Graph Theme", selection: $viewModel.selectedTheme) {
                        ForEach(Theme.selectableCases, id: \.rawValue) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .accessibilityIdentifier("theme-picker")
                }

                Section("Guide") {
                    Button("How To Use") {
                        showHowToUse = true
                    }
                    .accessibilityIdentifier("how-to-use-button")

                    Button("About") {
                        showAbout = true
                    }
                    .accessibilityIdentifier("about-button")
                }

                Section("Roadmap") {
                    Text("Widget configuration is still GitHub-only.")
                    Text("GitLab support is available in the app list view first.")
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
                .accessibilityIdentifier("roadmap-section")
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showHowToUse) {
                TutorialView()
            }
            .modifier(AboutPresentationModifier(isPresented: $showAbout))
        }
    }
}

private struct AboutPresentationModifier: ViewModifier {
    @Binding var isPresented: Bool
    @State private var previewSheet: UITestPreviewSheet?

    func body(content: Content) -> some View {
        if UITestSupport.isEnabled {
            content
                .fullScreenCover(isPresented: $isPresented) {
                    NavigationStack {
                        VStack(spacing: 24) {
                            AboutView()

                            VStack(spacing: 16) {
                                Button("Rate GitGet") {
                                    previewSheet = .review
                                }
                                .accessibilityIdentifier("about-rate-button")
                                .accessibilityLabel("Rate GitGet")

                                Button("Support") {
                                    previewSheet = .mail
                                }
                                .accessibilityIdentifier("about-support-button")
                                .accessibilityLabel("Support")

                                Button("GitHub") {
                                    previewSheet = .browser(title: "GitHub", url: SystemConstants.SNS.github)
                                }
                                .accessibilityIdentifier("about-github-button")
                                .accessibilityLabel("GitHub")
                            }
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .padding(.bottom, 32)
                        }
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Close") {
                                        isPresented = false
                                    }
                                    .accessibilityIdentifier("about-close-button")
                                }
                            }
                    }
                    .sheet(item: $previewSheet) { sheet in
                        NavigationStack {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(sheet.title)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                Text(sheet.message)
                                    .font(.system(size: 14, design: .monospaced))
                                Button("Close") {
                                    previewSheet = nil
                                }
                                .accessibilityIdentifier("preview-sheet-close-button")
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .navigationTitle(sheet.title)
                        }
                        .accessibilityIdentifier("preview-sheet-\(sheet.id)")
                    }
                }
        } else {
            content
                .sheet(isPresented: $isPresented) {
                AboutView()
                    .presentationDetents([.height(353)])
                }
        }
    }
}
