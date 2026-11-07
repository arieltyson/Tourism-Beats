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
        // Return only puts the keyboard away; adding is the toolbar's.
        activityField.typeText("Skydiving\n")
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "Return didn't put the keyboard away")
        XCTAssertFalse(app.staticTexts["Activities to Do"].exists, "Return added the activity")

        // The keyboard's own button puts it away too.
        activityField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        app.buttons["Hide Keyboard"].firstMatch.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5), "Hide Keyboard didn't put the keyboard away")

        app.navigationBars.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts["Activities to Do"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Skydiving"].exists)

        // A city, found by its own name; its country comes with it.
        app.navigationBars.buttons["Add to Bucket List"].tap()
        app.buttons["Place"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Country'")).firstMatch.tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Kyoto")
        let kyoto = app.buttons["Kyoto, Japan"].firstMatch
        XCTAssertTrue(kyoto.waitForExistence(timeout: 5))
        kyoto.tap()

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Japan'")).firstMatch.waitForExistence(timeout: 5))
        app.navigationBars.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts["Places to Visit"].waitForExistence(timeout: 5))
        let kyotoRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Kyoto'")).firstMatch
        XCTAssertTrue(kyotoRow.exists)

        // Checking it off.
        kyotoRow.tap()
        XCTAssertEqual(kyotoRow.value as? String, "Done")
    }
    /// A city page adds its city to the list, and the plus becomes a checkmark.
    func testAddingACityFromItsPage() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-inMemoryStore"]
        app.launch()

        let mapTab = app.tabBars.buttons["Map"].firstMatch
        XCTAssertTrue(mapTab.waitForExistence(timeout: 15))
        mapTab.tap()

        let field = app.textFields["Search cities or countries"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Kyoto")
        let kyoto = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Kyoto'")).firstMatch
        XCTAssertTrue(kyoto.waitForExistence(timeout: 5))
        kyoto.tap()

        let add = app.navigationBars.buttons["Add to Bucket List"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        XCTAssertTrue(
            app.navigationBars.buttons["Remove from Bucket List"].firstMatch.waitForExistence(timeout: 5),
            "The plus didn't become a checkmark"
        )

        app.tabBars.buttons["Settings"].firstMatch.tap()
        app.buttons["Bucket List"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Places to Visit"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Kyoto'")).firstMatch.exists)
    }
}
