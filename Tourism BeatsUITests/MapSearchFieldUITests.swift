import XCTest

// MARK: - MapSearchFieldUITests

/// Every part of the map's search capsule must start a search on the first
/// tap, not only the text itself.
final class MapSearchFieldUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        self.app = XCUIApplication()
        self.app.launch()

        let mapTab = self.app.tabBars.buttons["Map"]
        XCTAssertTrue(mapTab.waitForExistence(timeout: 15))
        mapTab.tap()
    }

    func testEveryPartOfTheCapsuleFocusesOnTheFirstTap() throws {
        let field = self.app.textFields["Search cities or countries"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        // The field reports the whole capsule as its frame. Tap just inside
        // its edges, away from the text: where the magnifying glass sits,
        // along the top and bottom, and at the far end.
        let frame = field.frame
        let inset: CGFloat = 6
        let offsets: [(name: String, dx: CGFloat, dy: CGFloat)] = [
            ("magnifying glass", 24, frame.height / 2),
            ("top edge", frame.width / 2, inset),
            ("bottom edge", frame.width / 2, frame.height - inset),
            ("far end", frame.width - 3 * inset, frame.height / 2),
            ("text", frame.width / 3, frame.height / 2)
        ]

        for offset in offsets {
            field.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: offset.dx, dy: offset.dy))
                .tap()

            XCTAssertTrue(
                self.app.keyboards.firstMatch.waitForExistence(timeout: 2),
                "A tap on the \(offset.name) didn't focus the field"
            )

            let close = self.app.buttons["Close"]
            if close.waitForExistence(timeout: 2) {
                close.tap()
            }
            _ = self.app.keyboards.firstMatch.waitForNonExistence(timeout: 3)
        }
    }
}
