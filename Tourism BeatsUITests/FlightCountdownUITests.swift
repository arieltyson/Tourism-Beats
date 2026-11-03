import XCTest

@MainActor
final class FlightCountdownUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddingAFlightBySearchingAndSwipingToDelete() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleInterfaceStyle", "Light"]
        app.launch()
        openFlightCountdown(in: app)
        capture("Flights")

        app.navigationBars.buttons["Add Flight"].tap()
        XCTAssertTrue(app.buttons["flightAirline"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["saveFlight"].isEnabled)
        capture("Add Flight")

        app.buttons["flightAirline"].tap()
        search(app, for: "Air Canada")
        choose(app, labelBeginningWith: "Air Canada")

        app.textFields["flightNumber"].tap()
        app.textFields["flightNumber"].typeText("901")
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        app.buttons["Done"].firstMatch.tap()
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 2), "Done dismisses the number pad")

        app.buttons["flightOrigin"].tap()
        search(app, for: "Vancouver")
        choose(app, labelBeginningWith: "Vancouver International")

        app.buttons["flightDestination"].tap()
        search(app, for: "London")
        XCTAssertTrue(element(app, labelBeginningWith: "London Gatwick").waitForExistence(timeout: 5),
                      "A city's airports are listed together")
        capture("London Airports")
        choose(app, labelBeginningWith: "London Heathrow")

        XCTAssertTrue(app.staticTexts["Use the local time in Vancouver."].exists)
        capture("Flight Filled In")
        app.buttons["addToCalendar"].tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2), "Adding an event asks for no calendar access")
        sleep(6)
        capture("New Event")
        dismissEventEditor(app, revealing: app.buttons["addToCalendar"])

        app.swipeUp()
        capture("Card Designs")
        XCTAssertTrue(app.buttons["saveFlight"].isEnabled)
        app.buttons["saveFlight"].tap()

        let flight = element(app, labelContaining: "Air Canada 901")
        XCTAssertTrue(flight.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Preview"].exists)
        XCTAssertTrue(app.staticTexts["Flights"].exists)
        capture("Countdown")

        app.terminate()
        app.launch()
        openFlightCountdown(in: app)
        XCTAssertTrue(flight.waitForExistence(timeout: 5))
        flight.press(forDuration: 1)
        XCTAssertTrue(app.buttons["Add to Calendar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Share Event"].exists)
        capture("Flight Menu")
        app.buttons["Add to Calendar"].tap()
        sleep(2)
        dismissEventEditor(app, revealing: flight)
        flight.swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(flight.waitForNonExistence(timeout: 5))
    }

    func testAccessibilityTextSizeAndWidgetInstructions() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        openFlightCountdown(in: app)
        capture("Flights Accessibility")
        app.navigationBars.buttons["Add a Widget"].tap()
        XCTAssertTrue(app.navigationBars["Add a Widget"].waitForExistence(timeout: 5))
        capture("Widget Instructions Accessibility")
        app.navigationBars["Add a Widget"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Flight Countdown"].waitForExistence(timeout: 5))
    }

    func testWidgetInstructions() throws {
        let app = XCUIApplication()
        app.launch()
        openFlightCountdown(in: app)
        app.navigationBars.buttons["Add a Widget"].tap()
        XCTAssertTrue(app.navigationBars["Add a Widget"].waitForExistence(timeout: 5))
        capture("Widget Instructions")
    }

    private func openFlightCountdown(in app: XCUIApplication) {
        // The tab bar can briefly hold two Settings buttons while it settles.
        let settings = app.tabBars.buttons["Settings"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        settings.tap()
        // A tap during launch can land before the tab bar responds.
        let tool = app.buttons["Flight Countdown"]
        if !tool.waitForExistence(timeout: 3) { settings.tap() }
        XCTAssertTrue(tool.waitForExistence(timeout: 5))
        tool.tap()
        XCTAssertTrue(app.navigationBars["Flight Countdown"].waitForExistence(timeout: 5))
    }

    /// The New Event sheet runs in another process, so its controls aren't
    /// in this app's hierarchy and it draws only once loaded; its close
    /// button is tapped where it sits until the screen beneath returns.
    private func dismissEventEditor(_ app: XCUIApplication, revealing element: XCUIElement) {
        for _ in 0..<10 where !element.isHittable {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.09, dy: 0.125)).tap()
            _ = element.waitForExistence(timeout: 1)
            if !element.isHittable { sleep(1) }
        }
        XCTAssertTrue(element.isHittable, "The New Event sheet closes")
    }

    private func search(_ app: XCUIApplication, for text: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        if !app.keyboards.firstMatch.exists { field.tap() }
        field.typeText(text)
    }

    private func choose(_ app: XCUIApplication, labelBeginningWith prefix: String) {
        let result = element(app, labelBeginningWith: prefix)
        XCTAssertTrue(result.waitForExistence(timeout: 5), app.debugDescription)
        result.tap()
    }

    private func element(_ app: XCUIApplication, labelBeginningWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func element(_ app: XCUIApplication, labelContaining text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
