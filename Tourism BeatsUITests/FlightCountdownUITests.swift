import XCTest

@MainActor
final class FlightCountdownUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSettingsAndStandaloneFlightLifecycle() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleInterfaceStyle", "Light"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Tools"].exists)
        XCTAssertTrue(app.staticTexts["Support"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Tourism Beats 5.'")).firstMatch.exists)
        capture("Settings")
        app.buttons["Flight Countdown"].tap()
        XCTAssertTrue(app.navigationBars["Flight Countdown"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Add Flight"].tap()
        XCTAssertTrue(app.textFields["flightNumber"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveFlight"].isEnabled)
        app.textFields["flightNumber"].tap()
        app.textFields["flightNumber"].typeText("UITEST 901")
        app.textFields["flightOrigin"].tap()
        app.textFields["flightOrigin"].typeText("YVR")
        app.textFields["flightDestination"].tap()
        app.textFields["flightDestination"].typeText("LHR")
        capture("Add Flight")
        app.buttons["saveFlight"].tap()
        let flight = app.buttons.containing(.staticText, identifier: "UITEST 901").firstMatch
        XCTAssertTrue(flight.waitForExistence(timeout: 5))
        capture("Countdown")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Flight Countdown"].tap()
        XCTAssertTrue(flight.waitForExistence(timeout: 5))
        flight.tap()
        app.buttons["Delete Flight"].tap()
        try XCTUnwrap(app.buttons.matching(identifier: "Delete Flight").allElementsBoundByIndex.last).tap()
        XCTAssertTrue(app.navigationBars["Flight Countdown"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["UITEST 901"].exists)
    }

    func testAccessibilityTextSizeAndWidgetInstructions() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Tools"].exists)
        capture("Settings Accessibility")
        app.buttons["Flight Countdown"].tap()
        XCTAssertTrue(app.navigationBars["Flight Countdown"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Add Widget"].tap()
        XCTAssertTrue(app.navigationBars["Add a Widget"].waitForExistence(timeout: 5))
        capture("Widget Instructions Accessibility")
        app.buttons["Done"].tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
