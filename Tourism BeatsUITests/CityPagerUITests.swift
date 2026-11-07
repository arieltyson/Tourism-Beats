import XCTest

// MARK: - CityPagerUITests

final class CityPagerUITests: XCTestCase {
    /// The Top Songs page sits between two pages of the vertical pager. One
    /// swipe up must move past it, however long the song's title runs.
    func testSwipingUpMovesPastTheSongsPage() throws {
        let app = XCUIApplication()
        app.launch()

        let mapTab = app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 15))
        mapTab.tap()

        let field = app.textFields["Search cities or countries"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Shanghai")

        let shanghai = app.buttons["Shanghai, China"]
        XCTAssertTrue(shanghai.waitForExistence(timeout: 5))
        shanghai.tap()

        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "The city page didn't open")

        app.swipeUp()
        let songsPage = app.staticTexts["Top Songs"]
        XCTAssertTrue(songsPage.waitForExistence(timeout: 5), "The first swipe didn't reach the songs page")
        Self.waitUntilHittable(songsPage)

        app.swipeUp()
        let advisoriesPage = app.staticTexts["Safety Advisory"]
        XCTAssertTrue(advisoriesPage.waitForExistence(timeout: 5), "The swipe stayed on the songs page")
        Self.waitUntilHittable(advisoriesPage)
    }

    private static func waitUntilHittable(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let hittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"),
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [hittable], timeout: 5),
            .completed,
            "\(element) never came on screen",
            file: file,
            line: line
        )
    }
}
