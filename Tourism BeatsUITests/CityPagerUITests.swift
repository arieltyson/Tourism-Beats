import XCTest

// MARK: - CityPagerUITests

final class CityPagerUITests: XCTestCase {
    /// The Top Songs page sits between two pages of the vertical pager. One
    /// swipe up must move past it, however long the song's title runs.
    func testSwipingUpMovesPastTheSongsPage() throws {
        let app = Self.openCity(searchingFor: "Shanghai", result: "Shanghai, China")

        app.swipeUp()
        let songsPage = app.staticTexts["Top Songs"]
        XCTAssertTrue(songsPage.waitForExistence(timeout: 5), "The first swipe didn't reach the songs page")
        Self.waitUntilHittable(songsPage)

        app.swipeUp()
        let advisoriesPage = app.staticTexts["Safety Advisory"]
        XCTAssertTrue(advisoriesPage.waitForExistence(timeout: 5), "The swipe stayed on the songs page")
        Self.waitUntilHittable(advisoriesPage)
    }

    /// The advisories page fits the screen, so a swipe either way must leave
    /// it rather than bounce its contents in place.
    func testSwipingMovesOnFromTheAdvisoriesPage() throws {
        let app = Self.openCity(searchingFor: "Rabat", result: "Rabat, Morocco")

        app.swipeUp()
        app.swipeUp()
        let advisoriesPage = app.staticTexts["Safety Advisory"]
        XCTAssertTrue(advisoriesPage.waitForExistence(timeout: 5), "Two swipes didn't reach the advisories page")
        Self.waitUntilHittable(advisoriesPage)

        app.swipeUp()
        let activitiesPage = app.staticTexts["Top Activities"]
        XCTAssertTrue(activitiesPage.waitForExistence(timeout: 5), "The swipe up stayed on the advisories page")
        Self.waitUntilHittable(activitiesPage)

        app.swipeDown()
        Self.waitUntilHittable(advisoriesPage)

        app.swipeDown()
        let songsPage = app.staticTexts["Top Songs"]
        XCTAssertTrue(songsPage.waitForExistence(timeout: 5), "The swipe down stayed on the advisories page")
        Self.waitUntilHittable(songsPage)
    }

    func testPassportSearchStaysPresentedAndSelectsCountry() throws {
        let app = Self.openCity(searchingFor: "Funchal", result: "Funchal, Portugal")
        app.buttons["Advisories"].tap()

        let passport = app.buttons["Select passport country"]
        Self.waitUntilHittable(passport)
        passport.tap()

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Canada")

        let canada = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Canada")).firstMatch
        Self.waitUntilHittable(canada)
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        canada.tap()

        XCTAssertTrue(search.waitForNonExistence(timeout: 5))
        XCTAssertEqual(passport.value as? String, "Canada")

        passport.tap()
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("zzzzzz")
        let noResults = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "No Results")
        ).firstMatch
        XCTAssertTrue(noResults.waitForExistence(timeout: 5))
        app.buttons["passportPicker.close"].tap()
        XCTAssertTrue(search.waitForNonExistence(timeout: 5))
        XCTAssertEqual(passport.value as? String, "Canada")
    }

    func testRepeatedSwipesKeepEveryPageAligned() throws {
        let app = Self.openCity(searchingFor: "Funchal", result: "Funchal, Portugal")
        let sections = ["City", "Music", "Advisories", "Activities", "Restaurants"]

        for _ in 0 ..< 2 {
            for section in sections.dropFirst() {
                app.swipeUp()
                Self.waitUntilSelected(app.buttons[section])
            }
            for section in sections.dropLast().reversed() {
                app.swipeDown()
                Self.waitUntilSelected(app.buttons[section])
            }
        }
    }

    private static func waitUntilSelected(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Selected"),
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [selected], timeout: 5),
            .completed,
            "The pager did not settle on \(element.label)",
            file: file,
            line: line
        )
    }

    // MARK: - Helpers

    /// Launches the app and opens a city from the map's search.
    private static func openCity(
        searchingFor query: String,
        result: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()

        // While the tab bar settles it can briefly list a tab twice.
        let mapTab = app.tabBars.buttons["Map"].firstMatch
        XCTAssertTrue(mapTab.waitForExistence(timeout: 15), file: file, line: line)
        mapTab.tap()

        let field = app.textFields["Search cities or countries"]
        XCTAssertTrue(field.waitForExistence(timeout: 10), file: file, line: line)
        field.tap()
        field.typeText(query)

        let city = app.buttons[result]
        XCTAssertTrue(city.waitForExistence(timeout: 5), file: file, line: line)
        city.tap()

        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "The city page didn't open", file: file, line: line)
        return app
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
