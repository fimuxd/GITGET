//
//  SettingView.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI

struct SettingView: View {
    private enum TeamSheetRoute: Identifiable {
        case teamManager
        case renameTeam(String)
        case member(String)

        var id: String {
            switch self {
            case .teamManager:
                return "teamManager"
            case .renameTeam(let teamID):
                return "rename.\(teamID)"
            case .member(let accountID):
                return "member.\(accountID)"
            }
        }
    }

    @State private var showHowToUse = false
    @State private var showAbout = false
    @State private var createdTeamName = ""
    @State private var renameTeamName = ""
    @State private var pendingDeletedTeam: ContributionTeam?
    @State private var teamSheetRoute: TeamSheetRoute?
    @ObservedObject var viewModel: ContributionViewModel

    private var hasTeams: Bool {
        !viewModel.teams.isEmpty
    }

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
        .accessibilityIdentifier("setting.tabView")
        .sheet(isPresented: $showHowToUse) {
            TutorialView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
                .presentationDetents([.height(430)])
        }
        .sheet(item: $teamSheetRoute) { route in
            switch route {
            case .teamManager:
                teamManagementSheet
            case .renameTeam(let teamID):
                if let team = viewModel.teams.first(where: { $0.id == teamID }) {
                    renameTeamSheet(for: team)
                }
            case .member(let accountID):
                if let profile = viewModel.profile(for: accountID) {
                    memberManagementSheet(for: profile)
                }
            }
        }
        .confirmationDialog(
            "Delete Team",
            isPresented: Binding(
                get: { pendingDeletedTeam != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeletedTeam = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let team = pendingDeletedTeam {
                Button("Delete \(team.name)", role: .destructive) {
                    viewModel.deleteTeam(teamID: team.id)
                    pendingDeletedTeam = nil
                }
                .accessibilityIdentifier("friends.teamDelete.confirm.\(team.id)")
            }

            Button("Cancel", role: .cancel) {
                pendingDeletedTeam = nil
            }
        } message: {
            if let team = pendingDeletedTeam {
                Text("Delete \(team.name)? Its members will stay available in All Friends.")
            }
        }
    }

    private var friendsTab: some View {
        NavigationStack {
            List {
                teamNavigationSection
                addFriendSection

                if hasTeams {
                    friendListSection
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("background").ignoresSafeArea())
            .navigationTitle("GitGet")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        presentTeamManager()
                    } label: {
                        Label("Teams", systemImage: "person.3.sequence.fill")
                    }
                    .accessibilityIdentifier("friends.manageTeamsButton")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refreshAll()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("friends.refreshButton")
                }
            }
        }
    }

    private var teamNavigationHeader: some View {
        HStack {
            Text("Teams")
            Spacer()
            Button("Manage") {
                teamSheetRoute = .teamManager
            }
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .accessibilityIdentifier("friends.teamSectionManageButton")
        }
    }

    private var teamNavigationSection: some View {
        Section {
            if hasTeams, let selectedTeamSummary = viewModel.selectedTeamSummary {
                selectedTeamCard(summary: selectedTeamSummary)
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowBackground(Color.clear)

                ForEach(viewModel.orderedTeamSummaries) { summary in
                    teamButton(summary: summary)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            } else {
                emptyStateCard(
                    title: "No teams yet",
                    message: "Add your first account to create All Friends, then use this tab to compare teammates and scan quick team insights.",
                    titleIdentifier: "friends.noTeamsTitle",
                    messageIdentifier: "friends.noTeamsMessage"
                )
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowBackground(Color.clear)
            }
        } header: {
            teamNavigationHeader
        } footer: {
            if hasTeams {
                Text("Pick a team to compare members, review insight cards, and choose where new friends are saved. Use Manage to create, rename, reorder, or delete teams.")
                    .font(.system(size: 12, design: .monospaced))
            }
        }
    }

    private var addFriendSection: some View {
        Section {
            addFriendContextCard

            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(ContributionProvider.allCases) { provider in
                    Text(provider.title).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("friends.providerPicker")

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

                Button("Add") {
                    viewModel.addAccount()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("friends.addButton")
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
            .accessibilityIdentifier("friends.serverOriginField")

            Text("Optional for GitHub Enterprise Server or self-managed GitLab.")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
        } header: {
            Text(addFriendSectionTitle)
        }
    }

    private var friendListSection: some View {
        Section {
            if let summary = viewModel.selectedTeamSummary {
                ContributionInsightSectionView(
                    summary: summary,
                    theme: viewModel.selectedTheme
                )
                .padding(.vertical, 8)
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowBackground(Color.clear)

                if viewModel.selectedTeamMembers.isEmpty {
                    emptyStateCard(
                        title: teamEmptyStateTitle,
                        message: teamEmptyStateMessage,
                        titleIdentifier: "friends.teamEmptyTitle",
                        messageIdentifier: "friends.teamEmptyMessage"
                    )
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)
                } else {
                    ContributionComparisonSectionView(
                        summary: summary,
                        selectedMetric: viewModel.selectedComparisonMetric,
                        theme: viewModel.selectedTheme,
                        onSelectMetric: { metric in
                            viewModel.selectComparisonMetric(metric)
                        }
                    )
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)

                    if !summary.unavailableMembers.isEmpty {
                        ContributionUnavailableSectionView(
                            members: summary.unavailableMembers,
                            theme: viewModel.selectedTheme
                        )
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        .listRowBackground(Color.clear)
                    }

                    ForEach(viewModel.selectedTeamMembers) { member in
                        memberCard(member)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        .listRowBackground(Color.clear)
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.removeProfileFromSelectedTeam(member.profile)
                            } label: {
                                Label(selectedTeamRemovalLabel, systemImage: selectedTeamRemovalIcon)
                            }
                        }
                    }
                }
            }
        } header: {
            Text(memberSectionTitle)
        } footer: {
            Text(memberSectionFooter)
                .font(.system(size: 12, design: .monospaced))
        }
    }

    private var addFriendSectionTitle: String {
        if let selectedTeam = viewModel.selectedTeam {
            return "Add to \(selectedTeam.name)"
        }

        return "Add Friend"
    }

    private var addFriendContextCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(addFriendContextTitle)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.blackAndWhite4)
                .accessibilityIdentifier("friends.addContextTitle")

            Text(addFriendContextMessage)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.blackAndWhite3)
                .accessibilityIdentifier("friends.addContextMessage")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(viewModel.selectedTheme.levelFourColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(viewModel.selectedTheme.levelFourColor.opacity(0.2), lineWidth: 1)
        )
        .accessibilityIdentifier("friends.addContextCard")
    }

    private var addFriendContextTitle: String {
        if let selectedTeam = viewModel.selectedTeam {
            return "Adding into \(selectedTeam.name)"
        }

        return "Your first account creates All Friends"
    }

    private var addFriendContextMessage: String {
        if viewModel.selectedTeam != nil {
            return "New accounts from this form are saved to the selected team so comparisons and insight cards stay team-specific."
        }

        return "Start with your own account or a teammate. Once saved, the Friends tab will help you compare teams and revisit recent contribution signals."
    }

    private var memberSectionTitle: String {
        guard let selectedTeam = viewModel.selectedTeam else {
            return "Friends"
        }

        return "\(selectedTeam.name) Members"
    }

    private var teamEmptyStateTitle: String {
        guard let selectedTeam = viewModel.selectedTeam else {
            return "No members yet"
        }

        return "\(selectedTeam.name) has no members yet"
    }

    private var teamEmptyStateMessage: String {
        guard let selectedTeam = viewModel.selectedTeam else {
            return "Add teammates below to start seeing comparison and insight cards here."
        }

        return "This team exists, but it does not have any saved accounts yet. Add teammates below and \(selectedTeam.name) will start showing comparison and insight cards."
    }

    private func selectedTeamCard(summary: ContributionTeamSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Selected Team")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.blackAndWhite3)
                .textCase(.uppercase)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(summary.team.name)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.blackAndWhite4)
                        .accessibilityIdentifier("friends.selectedTeamName")

                    Text(selectedTeamSummaryMessage(for: summary))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.blackAndWhite3)
                        .accessibilityIdentifier("friends.selectedTeamMessage")
                }

                Spacer(minLength: 12)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(viewModel.selectedTheme.levelFourColor)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(viewModel.selectedTheme.levelFourColor.opacity(0.12))
                    )
            }

            HStack(spacing: 8) {
                teamMetaPill(title: "Members", value: "\(summary.members.count)")

                if summary.partialFailureCount > 0 {
                    teamMetaPill(title: "Needs refresh", value: "\(summary.partialFailureCount)")
                } else {
                    teamMetaPill(title: "Status", value: summary.members.isEmpty ? "Empty" : "Ready")
                }
            }

            HStack(spacing: 8) {
                Button {
                    presentTeamManager()
                } label: {
                    Label("Manage Teams", systemImage: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("friends.selectedTeamManageButton")

                if summary.team.id == ContributionTeam.allFriendsID {
                    Text("Protected")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.selectedTheme.levelFourColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(viewModel.selectedTheme.levelFourColor.opacity(0.12)))
                        .accessibilityIdentifier("friends.selectedTeamProtectedLabel")
                } else {
                    Button {
                        renameTeamName = summary.team.name
                        teamSheetRoute = .renameTeam(summary.team.id)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("friends.selectedTeamRenameButton")

                    Button(role: .destructive) {
                        pendingDeletedTeam = summary.team
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("friends.selectedTeamDeleteButton")
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("background"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(viewModel.selectedTheme.levelFourColor.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("friends.selectedTeamCard")
    }

    private func teamButton(summary: ContributionTeamSummary) -> some View {
        let isSelected = summary.id == viewModel.selectedTeamID
        let teamButtonNameIdentifier = "friends.teamButtonName.\(teamIdentifierSlug(summary.team.name))"

        return Button {
            viewModel.selectTeam(summary.team.id)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(summary.team.name)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.blackAndWhite4)
                        .accessibilityIdentifier(teamButtonNameIdentifier)

                    Text(teamButtonSubtitle(for: summary))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.blackAndWhite3)
                }

                Spacer()

                Text(isSelected ? "Current" : "Open")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : viewModel.selectedTheme.levelFourColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(isSelected ? viewModel.selectedTheme.levelFourColor : viewModel.selectedTheme.levelFourColor.opacity(0.12))
                    )
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? viewModel.selectedTheme.levelFourColor.opacity(0.08) : Color("background"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? viewModel.selectedTheme.levelFourColor : viewModel.selectedTheme.levelFourColor.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("friends.teamButton.\(summary.id)")
    }

    private func teamIdentifierSlug(_ name: String) -> String {
        let normalized = name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return normalized.isEmpty ? "unnamed" : normalized
    }

    private func selectedTeamSummaryMessage(for summary: ContributionTeamSummary) -> String {
        if summary.members.isEmpty {
            return "This team is ready for its first saved member. Add someone below to unlock comparisons and insight cards here."
        }

        if !summary.rankedMembers(for: viewModel.selectedComparisonMetric).isEmpty {
            return "Showing \(summary.members.count) saved member\(summary.members.count == 1 ? "" : "s") with team comparison ranked by \(viewModel.selectedComparisonMetric.title.lowercased())."
        }

        return "Showing \(summary.members.count) saved member\(summary.members.count == 1 ? "" : "s") for the currently selected team."
    }

    private func teamButtonSubtitle(for summary: ContributionTeamSummary) -> String {
        if summary.members.isEmpty {
            return "Empty team"
        }

        if summary.partialFailureCount > 0 {
            return "\(summary.members.count) members • \(summary.partialFailureCount) need refresh"
        }

        return "\(summary.members.count) members"
    }

    private func teamMetaPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.blackAndWhite3)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.blackAndWhite4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(viewModel.selectedTheme.levelFourColor.opacity(0.08))
        )
    }

    private func emptyStateCard(
        title: String,
        message: String,
        titleIdentifier: String,
        messageIdentifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(viewModel.selectedTheme.levelFourColor)

            Text(title)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.blackAndWhite4)
                .accessibilityIdentifier(titleIdentifier)

            Text(message)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.blackAndWhite3)
                .accessibilityIdentifier(messageIdentifier)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("background"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(viewModel.selectedTheme.levelFourColor.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    private func presentTeamManager() {
        DispatchQueue.main.async {
            teamSheetRoute = .teamManager
        }
    }

    private func memberCard(_ member: ContributionTeamMemberState) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button {
                teamSheetRoute = .member(member.id)
            } label: {
                Label("Teams", systemImage: "person.3.sequence")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("friends.memberTeamsButton.\(member.id)")

            ContributionView(
                profile: member.profile,
                theme: viewModel.selectedTheme,
                cellColors: viewModel.cellColorSet(for: member.profile, columnsCount: 20)
            )
        }
    }

    private var selectedTeamRemovalLabel: String {
        viewModel.selectedTeamID == ContributionTeam.allFriendsID ? "Delete" : "Remove"
    }

    private var selectedTeamRemovalIcon: String {
        viewModel.selectedTeamID == ContributionTeam.allFriendsID ? "trash" : "person.crop.circle.badge.minus"
    }

    private var memberSectionFooter: String {
        if viewModel.selectedTeamID == ContributionTeam.allFriendsID {
            return "Use Teams on a card to assign friends into custom teams. Deleting here removes the account from every team."
        }

        return "Use Teams on a card to add or remove memberships. Removing here only detaches the friend from \(viewModel.selectedTeam?.name ?? "this team") and keeps the account in All Friends."
    }

    private var teamManagementSheet: some View {
        NavigationStack {
            List {
                Section("Create Team") {
                    TextField("New team name", text: $createdTeamName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("friends.teamManager.createField")

                    Button("Create Team") {
                        let trimmedName = createdTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
                        viewModel.createTeam(named: trimmedName)
                        createdTeamName = ""
                    }
                    .disabled(createdTeamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("friends.teamManager.createButton")
                }

                Section {
                    ForEach(viewModel.teams) { team in
                        teamManagementRow(team)
                    }
                } header: {
                    Text("Team Order")
                } footer: {
                    Text("All Friends is reserved, always stays first, and cannot be deleted. Deleting a custom team keeps its members in All Friends.")
                        .font(.system(size: 12, design: .monospaced))
                }
            }
            .navigationTitle("Manage Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        teamSheetRoute = nil
                    }
                    .accessibilityIdentifier("friends.teamManager.doneButton")
                }
            }
        }
    }

    private func teamManagementRow(_ team: ContributionTeam) -> some View {
        let isProtected = viewModel.isProtectedTeam(team.id)
        let teamPositionLabel = isProtected ? "Pinned" : "Position \(viewModel.customTeamPosition(for: team.id) ?? 0)"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.blackAndWhite4)
                        .accessibilityIdentifier("friends.teamManager.name.\(team.id)")

                    Text(teamPositionLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.blackAndWhite3)
                        .accessibilityIdentifier("friends.teamManager.position.\(team.id)")
                }

                Spacer()

                if team.id == viewModel.selectedTeamID {
                    Text("Selected")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(viewModel.selectedTheme.levelFourColor))
                        .accessibilityIdentifier("friends.teamManager.selected.\(team.id)")
                }
            }

            HStack(spacing: 8) {
                if isProtected {
                    Text("Protected")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.selectedTheme.levelFourColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(viewModel.selectedTheme.levelFourColor.opacity(0.12)))
                        .accessibilityIdentifier("friends.teamManager.protected.\(team.id)")
                } else {
                    Button {
                        renameTeamName = team.name
                        teamSheetRoute = .renameTeam(team.id)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("friends.teamManager.rename.\(team.id)")

                    Button(role: .destructive) {
                        pendingDeletedTeam = team
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("friends.teamManager.delete.\(team.id)")

                    Button {
                        viewModel.moveTeamUp(teamID: team.id)
                    } label: {
                        Label("Up", systemImage: "arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canMoveTeamUp(team.id))
                    .accessibilityIdentifier("friends.teamManager.moveUp.\(team.id)")

                    Button {
                        viewModel.moveTeamDown(teamID: team.id)
                    } label: {
                        Label("Down", systemImage: "arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.canMoveTeamDown(team.id))
                    .accessibilityIdentifier("friends.teamManager.moveDown.\(team.id)")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("friends.teamManager.row.\(team.id)")
    }

    private func renameTeamSheet(for team: ContributionTeam) -> some View {
        NavigationStack {
            Form {
                Section("Rename Team") {
                    TextField("Team name", text: $renameTeamName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("friends.teamRename.field.\(team.id)")
                }

                Section {
                    Button("Save") {
                        let trimmedName = renameTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
                        viewModel.renameTeam(teamID: team.id, to: trimmedName)
                        teamSheetRoute = nil
                    }
                    .disabled(renameTeamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("friends.teamRename.save.\(team.id)")
                }
            }
            .navigationTitle("Rename Team")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        teamSheetRoute = nil
                    }
                    .accessibilityIdentifier("friends.teamRename.cancel.\(team.id)")
                }
            }
        }
    }

    private func memberManagementSheet(for profile: ContributionProfile) -> some View {
        NavigationStack {
            List {
                Section("Friend") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(profile.name)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        Text("@\(profile.username)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("friends.memberTeamSheet.header.\(profile.id)")
                }

                Section {
                    Text("All Friends")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .accessibilityIdentifier("friends.memberTeamLocked.\(profile.id)")

                    if viewModel.customTeams.isEmpty {
                        Text("Create a custom team first, then assign this friend to it from here.")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("friends.memberTeamEmpty.\(profile.id)")
                    } else {
                        ForEach(viewModel.customTeams) { team in
                            Toggle(isOn: Binding(
                                get: { viewModel.isMember(profile.id, inTeamID: team.id) },
                                set: { isIncluded in
                                    viewModel.setMembership(forAccountID: profile.id, inTeamID: team.id, isIncluded: isIncluded)
                                }
                            )) {
                                Text(team.name)
                                    .font(.system(size: 14, design: .monospaced))
                            }
                            .accessibilityIdentifier("friends.memberTeamToggle.\(profile.id).\(team.id)")
                        }
                    }
                } header: {
                    Text("Memberships")
                } footer: {
                    Text("Turning a team off removes only that membership. The account always stays in All Friends until you delete it from the All Friends list.")
                        .font(.system(size: 12, design: .monospaced))
                }
            }
            .navigationTitle("Member Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        teamSheetRoute = nil
                    }
                    .accessibilityIdentifier("friends.memberTeamSheet.done.\(profile.id)")
                }
            }
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
                    Button("Widget Setup Guide") {
                        showHowToUse = true
                    }
                    .accessibilityIdentifier("settings.howToUseButton")

                    Button("About GitGet") {
                        showAbout = true
                    }
                    .accessibilityIdentifier("settings.aboutButton")
                }

                Section("Product") {
                    Text("GitGet helps you compare saved teammates, scan team insights, and keep contribution activity readable across your teams.")
                    Text("Use the Friends tab to switch teams, review rankings, and spot momentum from the accounts already tracked in the app.")
                    Text("Widgets still accept one GitHub username plus theme. GitLab support stays in the in-app team view for now.")
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}
