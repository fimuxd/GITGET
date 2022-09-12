//
//  ContributionViewModel.swift
//  GITGET
//
//  Created by Bo-Young Park on 2022/09/12.
//

import SwiftUI
import Combine

class ContributionViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    private var contributions: [Contribution] = []
    var user: User? = nil
    
    @Published var enteredUserName: String = ""
    @Published var username: String = "Anonymous"
    @Published var todayContributionCount: Int?
    @Published var isInitial: Bool = true
    @Published var invalidUsername: Bool = false
    @Published var currentYearContributions: Int = 0
    @Published var name: String = "Anonymous"
    @Published var bio: String = "Keep GitHub Contributions Green 🟩".localized
    @Published var location: String = "Anywhere"
    @Published var company: String = "🔦🔍👀"
    @Published var followers: String = ""
    @Published var following: String = ""
    @Published var startYear: String = String(Date().year)
    
    func setContributionComponent(_ contributionList: [Contribution]) {
        username = user?.login ?? "Anonymous"
        todayContributionCount = contributionList.filter { $0.date.isToday }.first?.count
        isInitial = contributionList.isEmpty
        currentYearContributions = contributionList
            .filter { $0.date.year == Date().year }
            .map { $0.count }.reduce(0, +)
        name = user?.name ?? "Anonymous"
        bio = user?.bio ?? "Keep GitHub Contributions Green 🟩".localized
        location = user?.location ?? "Anywhere"
        company = user?.company ?? "🔦🔍👀"
        let followerCount = user?.followers ?? 0
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedFollowerCount = numberFormatter.string(from: NSNumber(value: followerCount)) ?? ""
        followers = formattedFollowerCount
        let followingCount = user?.following ?? 0
        let formattedFolloingCount = numberFormatter.string(from: NSNumber(value: followingCount)) ?? ""
        following = formattedFolloingCount
        startYear = String(user?.createdAt?.year ?? Date().year)
    }
    
    
    func cellColorSet(columnsCount: Int) -> [[Color]] {
        guard let lastDate = contributions.last?.date else {
            return []
        }
        
        let rows = 7
        let columns = columnsCount
        let theme = Theme.default
        
        let cellCount = rows * columns - (rows - Calendar.current.component(.weekday, from: lastDate))
        let levels = contributions.suffix(cellCount).map(\.level).chunked(into: rows)
        return levels.map { $0.map { theme.supplyColor(by: $0)} }
    }
    
    func getContributions() {
        GitHubNetwork().getContributions(of: enteredUserName)
            .combineLatest(GitHubNetwork().getUser(of: enteredUserName))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: {[weak self] completion in
                    switch completion {
                    case .failure:
                        self?.invalidUsername = true
                    case .finished:
                        print("finished")
                    }
                },
                receiveValue: {[weak self] (contributions, user) in
                    self?.contributions = contributions
                    self?.user = user
                    self?.setContributionComponent(contributions)
                    self?.invalidUsername = false
                }
            )
            .store(in: &cancellables)
    }
}
