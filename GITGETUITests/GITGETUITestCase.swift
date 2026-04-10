import XCTest

class GITGETUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @discardableResult
    func launchApp(state: String = "initial") -> XCUIApplication {
        app.launchEnvironment["GITGET_UI_TEST_MODE"] = "1"
        app.launchEnvironment["GITGET_UI_TEST_STATE"] = state
        app.launch()
        return app
    }

    var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }
}
