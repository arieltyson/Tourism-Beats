import XCTest

// MARK: - CityPagerUITests

final class CityPagerUITests: XCTestCase {
    /// Half an indicator icon's visible width.
    private static let indicatorHalfWidth: CGFloat = 23

    /// How long a person looks at a city before swiping on.
    private static let glanceDuration: TimeInterval = 1.5

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

        // Ending the search brings back the sheet's own close button.
        app.buttons["close"].firstMatch.tap()
        let close = app.buttons["passportPicker.close"]
        Self.waitUntilHittable(close)
        close.tap()
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

    /// Every page keeps the pager inside the screen, with the page
    /// indicator fully on it, whichever pages have been built so far.
    func testPagesAndIndicatorStayInsideTheScreen() throws {
        let app = Self.openCity(searchingFor: "Cannes", result: "Cannes, France")
        let screen = app.windows.firstMatch.frame
        let sections = ["City", "Music", "Advisories", "Activities", "Restaurants"]

        for section in sections {
            let button = app.buttons[section]
            Self.waitUntilHittable(button)
            button.tap()
            Self.waitUntilSelected(button)

            // An icon's frame reaches past its glyph to widen the tap target,
            // so its centre, not its frame, must sit clear of the edge.
            for indicator in sections.map({ app.buttons[$0] }) {
                XCTAssertTrue(
                    indicator.frame.midX <= screen.maxX - Self.indicatorHalfWidth,
                    "On \(section), \(indicator.label) sits at \(indicator.frame), outside \(screen)"
                )
            }
        }
    }

    /// Two quick swipes from the city reach the advisories page with its
    /// cards already in place, rather than a blank page that fills in late.
    func testAdvisoriesAreReadyWhenTwoQuickSwipesArrive() throws {
        let app = Self.openCity(searchingFor: "Asuncion", result: "Asuncion, Paraguay")

        app.swipeUp(velocity: .fast)
        app.swipeUp(velocity: .fast)

        let visaStatus = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Visa status")
        ).firstMatch
        XCTAssertTrue(visaStatus.waitForExistence(timeout: 2), "The advisories page wasn't ready as it arrived")
        XCTAssertFalse(app.staticTexts["No advisory information available."].exists)
        XCTAssertFalse(app.staticTexts["No visa information for this passport and destination"].exists)
    }

    /// A quick run of swipes from the city, after a moment on it, reaches an
    /// activities page that's already built rather than one built on arrival.
    func testActivitiesAreReadyAfterAQuickRunOfSwipes() throws {
        let app = Self.openCity(searchingFor: "Nassau", result: "Nassau, Bahamas")
        // A moment on the city page, as a person takes in its photo.
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "A glance at the city")], timeout: Self.glanceDuration)

        for _ in 0 ..< 3 {
            app.swipeUp(velocity: .fast)
        }

        let activitiesPage = app.staticTexts["Top Activities"]
        XCTAssertTrue(activitiesPage.waitForExistence(timeout: 1), "The activities page wasn't built ahead of time")
        Self.waitUntilHittable(activitiesPage)
        XCTAssertFalse(app.staticTexts["No Activities Yet"].exists)
    }

    /// Not a check: walks a city's pages the way a person does, for Time
    /// Profiler to record. Runs only when PROFILE_PAGER is set, against an
    /// app the profiler has already launched, so the trace covers the walk:
    ///
    /// ```bash
    /// xcrun xctrace record --template "Time Profiler" --device <id> \
    ///     --time-limit 40s --launch -- com.arieljtyson.Tourism-Beats &
    /// TEST_RUNNER_PROFILE_PAGER=1 xcodebuild test-without-building ... \
    ///     -only-testing:"Tourism BeatsUITests/CityPagerUITests/testProfilePagerSwipes"
    /// ```
    ///
    /// UI testing reads the app's accessibility tree between steps, so leave
    /// the accessibility frames out when reading the trace.
    func testProfilePagerSwipes() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["PROFILE_PAGER"] == nil)
        // The profiler launched the app; drive that instance rather than a new one.
        let app = XCUIApplication()
        app.activate()
        let mapTab = app.tabBars.buttons["Map"].firstMatch
        XCTAssertTrue(mapTab.waitForExistence(timeout: 30))
        mapTab.tap()
        let field = app.textFields["Search cities or countries"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Nassau")
        app.buttons["Nassau, Bahamas"].tap()
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "A glance at the city")], timeout: 1.5)
        app.swipeUp()
        app.swipeUp()
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Rest on advisories")], timeout: 0.4)
        app.swipeUp()
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "Activities settle")], timeout: 6)
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
