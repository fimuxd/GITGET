//
//  GITGETTests.swift
//  GITGETTests
//
//  Created by Bo-Young PARK on 12/27/20.
//

import XCTest
@testable import GITGET

class GITGETTests: XCTestCase {

    func testContributionAccountDecodesLegacyPayloadWithoutServerOrigin() throws {
        let data = #"{"provider":"github","username":"octocat"}"#.data(using: .utf8)!

        let account = try JSONDecoder().decode(ContributionAccount.self, from: data)

        XCTAssertEqual(account.provider, .github)
        XCTAssertEqual(account.username, "octocat")
        XCTAssertNil(account.serverOrigin)
    }

    func testContributionAccountNormalizesUsernameAndServerOrigin() {
        let account = ContributionAccount(
            provider: .gitlab,
            username: "  haru  ",
            serverOrigin: "tw-gitlab.t-wal.com/gitlab?from=app#section"
        )

        XCTAssertEqual(account.username, "haru")
        XCTAssertEqual(account.serverOrigin, "https://tw-gitlab.t-wal.com")
    }

    func testGitHubEnterpriseServerOriginUsesWebOriginAndAPIV3() {
        XCTAssertEqual(
            ContributionProvider.github.webBaseURL(serverOrigin: "github.example.com/api/v3").absoluteString,
            "https://github.example.com"
        )
        XCTAssertEqual(
            ContributionProvider.github.apiBaseURL(serverOrigin: "github.example.com/api/v3").absoluteString,
            "https://github.example.com/api/v3"
        )
        XCTAssertEqual(
            ContributionProvider.github.apiBaseURL(serverOrigin: "https://github.com").absoluteString,
            "https://api.github.com"
        )
    }

    func testGitLabServerOriginUsesAPIV4() {
        XCTAssertEqual(
            ContributionProvider.gitlab.webBaseURL(serverOrigin: "https://gitlab.example.com/gitlab").absoluteString,
            "https://gitlab.example.com"
        )
        XCTAssertEqual(
            ContributionProvider.gitlab.apiBaseURL(serverOrigin: "https://gitlab.example.com/gitlab").absoluteString,
            "https://gitlab.example.com/api/v4"
        )
        XCTAssertEqual(
            ContributionProvider.gitlab.apiBaseURL(serverOrigin: "gitlab.com").absoluteString,
            "https://gitlab.com/api/v4"
        )
    }

    func testServerOriginNormalizationPrefersHTTPS() {
        XCTAssertEqual(
            ContributionProvider.github.webBaseURL(serverOrigin: "http://github.example.com/internal").absoluteString,
            "https://github.example.com"
        )
        XCTAssertEqual(
            ContributionProvider.gitlab.apiBaseURL(serverOrigin: "tw-gitlab.t-wal.com/team").absoluteString,
            "https://tw-gitlab.t-wal.com/api/v4"
        )
    }

    func testAccountAwareURLConstructionUsesCustomOrigins() {
        let githubAccount = ContributionAccount(
            provider: .github,
            username: "octocat",
            serverOrigin: "github.example.com"
        )
        let gitLabAccount = ContributionAccount(
            provider: .gitlab,
            username: "haru",
            serverOrigin: "https://tw-gitlab.t-wal.com/gitlab"
        )

        XCTAssertEqual(
            URL.userAPI(account: githubAccount).absoluteString,
            "https://github.example.com/api/v3/users"
        )
        XCTAssertEqual(
            URL.contributionsAPI(account: githubAccount).absoluteString,
            "https://github.example.com/users"
        )
        XCTAssertEqual(
            URL.userAPI(account: gitLabAccount).absoluteString,
            "https://tw-gitlab.t-wal.com/api/v4/users"
        )
        XCTAssertEqual(
            URL.contributionsAPI(account: gitLabAccount).absoluteString,
            "https://tw-gitlab.t-wal.com/users"
        )
    }

    func testParseContributionsFromGitHubFragment() throws {
        let html = """
        <table>
          <tbody>
            <tr>
              <td id="contribution-day-component-0-0" class="ContributionCalendar-day" data-date="2026-04-07" data-level="0"></td>
              <tool-tip for="contribution-day-component-0-0">No contributions on April 7th.</tool-tip>
              <td id="contribution-day-component-0-1" class="ContributionCalendar-day" data-date="2026-04-08" data-level="2"></td>
              <tool-tip for="contribution-day-component-0-1">12 contributions on April 8th.</tool-tip>
              <td id="contribution-day-component-0-2" class="ContributionCalendar-day" data-date="2026-04-09" data-level="4"></td>
              <tool-tip for="contribution-day-component-0-2">1 contribution on April 9th.</tool-tip>
            </tr>
          </tbody>
        </table>
        """

        let contributions = try ContributionAPI.parseContributions(from: html)

        XCTAssertEqual(contributions.count, 3)
        XCTAssertEqual(contributions.map(\.count), [0, 12, 1])
        XCTAssertEqual(contributions.map(\.level), [.zero, .two, .four])
        XCTAssertEqual(contributions.map { Contribution.string(from: $0.date) }, ["2026-04-07", "2026-04-08", "2026-04-09"])
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
