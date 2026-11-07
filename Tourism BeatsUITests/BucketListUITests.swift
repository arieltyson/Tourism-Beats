import XCTest

// MARK: - BucketListUITests

final class BucketListUITests: XCTestCase {
    /// From an empty list, an activity and then a city find their sections.
    func testAddingAnActivityAndACity() throws {
        let app = XCUIApplication()
        // A fresh, in-memory store, so the list always starts empty.
        app.launchArguments += ["-inMemoryStore"]
        app.launch()

        let settingsTab = app.tabBars.buttons["Settings"].firstMatch
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 15))
        settingsTab.tap()

        let bucketList = app.buttons["Bucket List"].firstMatch
        XCTAssertTrue(bucketList.waitForExistence(timeout: 5))
        bucketList.tap()

        XCTAssertTrue(app.staticTexts["Someday Starts Here"].waitForExistence(timeout: 5), "The empty state didn't show")

        // An activity.
        app.navigationBars.buttons["Add to Bucket List"].tap()
        app.buttons["Activity"].tap()
        let activityField = app.textFields["Activity"].firstMatch
        XCTAssertTrue(activityField.waitForExistence(timeout: 5))
        activityField.typeText("Skydiving")
        app.navigationBars.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts["Activities to Do"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Skydiving"].exists)

        // A city, by its country.
        app.navigationBars.buttons["Add to Bucket List"].tap()
        app.buttons["Place"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Country'")).firstMatch.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Japan")
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Japan'")).firstMatch.tap()

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'City'")).firstMatch.tap()
        let kyoto = app.buttons["Kyoto"].firstMatch
        XCTAssertTrue(kyoto.waitForExistence(timeout: 5))
        kyoto.tap()
        app.navigationBars.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts["Places to Visit"].waitForExistence(timeout: 5))
        let kyotoRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Kyoto'")).firstMatch
        XCTAssertTrue(kyotoRow.exists)

        // Checking it off.
        kyotoRow.tap()
        XCTAssertEqual(kyotoRow.value as? String, "Done")
    }
}
