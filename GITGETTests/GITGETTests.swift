//
//  GITGETTests.swift
//  GITGETTests
//
//  Created by Bo-Young PARK on 12/27/20.
//

import XCTest
@testable import GITGET

class GITGETTests: XCTestCase {

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
