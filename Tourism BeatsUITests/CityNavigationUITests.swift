import XCTest

// MARK: - CityNavigationUITests

final class CityNavigationUITests: XCTestCase {
    func testSwipingFromTheLeftEdgeReturnsToTheMap() throws {
        let app = XCUIApplication()
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 15))
        mapTab.tap()

        let field = app.textFields["Search cities or countries"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Paris")

        let paris = app.buttons["Paris, France"]
        XCTAssertTrue(paris.waitForExistence(timeout: 5))
        paris.tap()

        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "The city page didn't open")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))

        XCTAssertTrue(field.waitForExistence(timeout: 5), "Swiping right didn't return to the map")
    }
}
