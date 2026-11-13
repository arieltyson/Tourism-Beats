import XCTest

// MARK: - TripBudgetUITests

/// A new trip's budget: opened from the form, fine-tuned by category, and
/// followed by hotel picks in the suggested plan.
@MainActor
final class TripBudgetUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testBudgetIsFineTunedAndHotelsAreRecommendedWithThePlan() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-inMemoryStore", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let tripsTab = app.buttons.matching(identifier: "Trips").firstMatch
        XCTAssertTrue(tripsTab.waitForExistence(timeout: 20))
        tripsTab.tap()

        let addTrip = app.buttons["Add Trip"].firstMatch
        XCTAssertTrue(addTrip.waitForExistence(timeout: 10))
        addTrip.tap()

        let name = app.textFields["Trip Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Lisbon Escape")

        let city = app.textFields["City"]
        city.tap()
        city.typeText("Lisbon")
        let lisbon = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Lisbon,")).firstMatch
        XCTAssertTrue(lisbon.waitForExistence(timeout: 5))
        lisbon.tap()
        Self.hideKeyboard(in: app)

        // The budget opens at what such a trip typically costs.
        let budgetRow = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Budget")).firstMatch
        Self.scrollTo(budgetRow, in: app)
        budgetRow.tap()

        let staySlider = app.sliders["Stay"]
        XCTAssertTrue(staySlider.waitForExistence(timeout: 5), "The budget didn't open")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "A trip like this to Lisbon")).firstMatch.exists)
        self.attach("budget-typical", app)

        let foodBefore = app.sliders["Food"].value as? String
        staySlider.adjust(toNormalizedSliderPosition: 0.7)
        XCTAssertNotEqual(app.sliders["Food"].value as? String, foodBefore, "The other categories didn't rebalance")
        XCTAssertTrue(app.buttons["Use Typical Budget"].waitForExistence(timeout: 2))
        self.attach("budget-tuned", app)

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(budgetRow.waitForExistence(timeout: 5))
        XCTAssertNotEqual(budgetRow.label, "Budget, Optional")

        let suggestPlan = app.switches["Suggest a Plan"]
        Self.scrollTo(suggestPlan, in: app)
        suggestPlan.switches.firstMatch.tap()
        app.buttons["Add"].firstMatch.tap()

        // The plan for a trip without a hotel ends with where to stay.
        let whereToStay = app.staticTexts["Where to Stay"]
        Self.scrollTo(whereToStay, in: app, timeout: 60)
        self.attach("where-to-stay", app)

        let firstHotel = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Accommodation")).firstMatch
        XCTAssertTrue(firstHotel.waitForExistence(timeout: 5))
        firstHotel.tap()
        XCTAssertTrue(firstHotel.isSelected)
    }

    // MARK: - Helpers

    private func attach(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    private static func hideKeyboard(in app: XCUIApplication) {
        let hide = app.buttons["Hide Keyboard"].firstMatch
        if hide.waitForExistence(timeout: 2) {
            hide.tap()
        }
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
    }

    /// Swipes up until the element is on screen.
    private static func scrollTo(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 10) {
        let deadline = Date.now.addingTimeInterval(timeout)
        while !(element.exists && element.isHittable), Date.now < deadline {
            if element.exists {
                app.swipeUp()
            } else {
                _ = element.waitForExistence(timeout: 2)
                if !element.exists { app.swipeUp() }
            }
        }
        XCTAssertTrue(element.isHittable, "\(element) never came on screen")
    }
}
