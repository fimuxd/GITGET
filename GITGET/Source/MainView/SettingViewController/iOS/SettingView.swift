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

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "paintpalette")
                }
        }
        .tint(viewModel.selectedTheme.levelFourColor)
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
            .navigationTitle("GitGet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refreshAll()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
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

            HStack(spacing: 12) {
                TextField("Enter username", text: $viewModel.enteredUserName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        viewModel.addAccount()
                    }

                Button("Add") {
                    viewModel.addAccount()
                }
                .buttonStyle(.borderedProminent)
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

            Text("Optional for GitHub Enterprise Server or self-managed GitLab. Example: https://tw-gitlab.t-wal.com")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
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
                    Text("Start with your own account, then add teammates or friends to compare activity at a glance.")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.profiles) { profile in
                    ContributionView(
                        profile: profile,
                        theme: viewModel.selectedTheme,
                        cellColors: viewModel.cellColorSet(for: profile, columnsCount: 20)
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
                }

                Section("Guide") {
                    Button("How To Use") {
                        showHowToUse = true
                    }

                    Button("About") {
                        showAbout = true
                    }
                }

                Section("Roadmap") {
                    Text("Widget configuration is still GitHub-only.")
                    Text("GitLab support is available in the app list view first.")
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showHowToUse) {
                TutorialView()
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
                    .presentationDetents([.height(353)])
            }
        }
    }
}
