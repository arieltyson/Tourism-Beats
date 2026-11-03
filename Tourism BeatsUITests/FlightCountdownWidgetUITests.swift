import XCTest

@MainActor
final class FlightCountdownWidgetUITests: XCTestCase {
    func testNativeWidgetGalleryAndDeepLink() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 15))
        XCUIDevice.shared.press(.home)
        let home = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        home.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).press(forDuration: 1.5)
        XCTAssertTrue(home.buttons["Edit"].waitForExistence(timeout: 5), home.debugDescription)
        home.buttons["Edit"].tap()
        home.buttons.matching(NSPredicate(format: "label ENDSWITH %@", "Add Widget")).firstMatch.tap()
        let search = home.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), home.debugDescription)
        search.tap()
        search.typeText("Tourism Beats")
        let result = home.cells["Tourism Beats"]
        XCTAssertTrue(result.waitForExistence(timeout: 5), home.debugDescription)
        result.tap()
        XCTAssertTrue(home.staticTexts["Flight Countdown"].waitForExistence(timeout: 5), home.debugDescription)
        let gallery = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        gallery.name = "Native Widget Gallery"
        gallery.lifetime = .keepAlways
        add(gallery)
        home.buttons.matching(NSPredicate(format: "label ENDSWITH %@", "Add Widget")).firstMatch.tap()
        if home.buttons["Done"].waitForExistence(timeout: 5) { home.buttons["Done"].tap() }
        let widget = home.icons.matching(NSPredicate(format: "label == %@ AND value CONTAINS %@", "Tourism Beats", "Widget")).firstMatch
        XCTAssertTrue(widget.waitForExistence(timeout: 10), home.debugDescription)
        widget.tap()
        XCTAssertTrue(app.navigationBars["Flight Countdown"].waitForExistence(timeout: 10))
    }
}
