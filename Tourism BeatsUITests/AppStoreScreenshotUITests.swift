import XCTest

// MARK: - AppStoreScreenshotUITests

/// Walks the real app to each App Store listing screen, one test per screen
/// so each starts from a fresh launch, and has `capture.sh` save it.
///
/// Skipped unless an output folder is given, so ordinary test runs never
/// touch the listing images. Run it through the script, which passes the
/// folder and saves each screen from the display you name:
///
/// ```bash
/// App_Store/Screenshots/capture.sh "iPhone 18 Pro" raw-iphone
/// App_Store/Screenshots/capture.sh "iPhone Duo" raw-duo-outer
/// App_Store/Screenshots/capture.sh "iPhone Duo" raw-duo-inner primary-1
/// ```
@MainActor
final class AppStoreScreenshotUITests: XCTestCase {
    /// Long enough for photos, weather and city guides to arrive.
    private static let settleTime: TimeInterval = 12

    /// How long to wait for the capture script to save a screen.
    private static let captureTimeout: TimeInterval = 60

    private var outputDirectory: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let path = ProcessInfo.processInfo.environment["SCREENSHOT_OUTPUT_DIR"] ?? ""
        try XCTSkipIf(path.isEmpty, "Set TEST_RUNNER_SCREENSHOT_OUTPUT_DIR to capture the listing screens.")
        self.outputDirectory = URL(filePath: path, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: self.outputDirectory, withIntermediateDirectories: true)
    }

    func test01Home() throws {
        let app = Self.launch()
        XCTAssertTrue(app.buttons["Explore all destinations"].waitForExistence(timeout: 20))
        try self.capture("01-home", of: app)
    }

    func test02City() throws {
        let app = Self.openParis()
        try self.capture("02-city", of: app)
    }

    func test03Activities() throws {
        let app = Self.openParis()
        Self.showCityPage("Activities", in: app)
        try self.capture("03-activities", of: app)
    }

    func test04Restaurants() throws {
        let app = Self.openParis()
        Self.showCityPage("Restaurants", in: app)
        try self.capture("04-restaurants", of: app)
    }

    func test05GastroCities() throws {
        let app = Self.launch()
        Self.selectTab("Food", in: app)
        XCTAssertTrue(app.staticTexts["Your journal starts here"].waitForExistence(timeout: 15))
        try self.capture("05-gastro-cities", of: app)
    }

    func test06Music() throws {
        let app = Self.openParis()
        Self.showCityPage("Music", in: app)
        try self.capture("06-music", of: app)
    }

    func test07Advisories() throws {
        let app = Self.openParis()
        Self.showCityPage("Advisories", in: app)
        try self.capture("07-advisories", of: app)
    }

    func test08Trips() throws {
        let app = Self.launch()
        Self.selectTab("Trips", in: app)
        try self.capture("08-trips", of: app)
    }

    func test09SuggestedPlan() throws {
        let app = Self.launch()
        Self.selectTab("Trips", in: app)

        // The trip card is one element whose label starts with the trip's name.
        let sampleTrip = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Trinidad and Tobago")).firstMatch
        XCTAssertTrue(sampleTrip.waitForExistence(timeout: 15), "No sample trip")
        sampleTrip.tap()

        let actions = app.buttons["Trip actions"].firstMatch
        XCTAssertTrue(actions.waitForExistence(timeout: 10))
        actions.tap()
        let suggest = app.buttons["Suggest a Plan"].firstMatch
        XCTAssertTrue(suggest.waitForExistence(timeout: 5))
        suggest.tap()
        try self.capture("09-suggested-plan", of: app)
    }

    // MARK: - Helpers

    /// Launches with a fresh in-memory store, so the journal and trips show
    /// what a new person sees.
    private static func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-inMemoryStore", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        return app
    }

    private static func selectTab(_ title: String, in app: XCUIApplication) {
        // A phone's tab bar and iPhone Duo's side rail expose the tab
        // differently, so match the button wherever it is. While the bar
        // settles it can briefly list a tab twice.
        let tab = app.buttons.matching(identifier: title).firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 20), "No \(title) tab")
        tab.tap()
    }

    private static func openParis() -> XCUIApplication {
        let app = self.launch()
        self.selectTab("Map", in: app)

        let field = app.textFields["Search cities or countries"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Paris")

        let paris = app.buttons["Paris, France"]
        XCTAssertTrue(paris.waitForExistence(timeout: 10))
        paris.tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 10), "The city page didn't open")
        return app
    }

    /// Moves the city pager to a page with its side indicator.
    private static func showCityPage(_ label: String, in app: XCUIApplication) {
        let indicator = app.buttons[label].firstMatch
        XCTAssertTrue(indicator.waitForExistence(timeout: 10), "No \(label) page")
        indicator.tap()
    }

    /// Hands the screen to `App_Store/Screenshots/capture.sh`, which saves
    /// the whole display with `simctl`, status bar included.
    ///
    /// The test can't take the picture itself: iPhone Duo has two displays,
    /// and XCTest only sees the outer one, which is dark while the phone is
    /// open. So the test leaves a ready marker and waits for the script to
    /// leave a done marker once the display is saved.
    private func capture(_ name: String, of app: XCUIApplication) throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        Thread.sleep(forTimeInterval: Self.settleTime)

        let ready = self.outputDirectory.appending(path: "\(name).ready")
        let done = self.outputDirectory.appending(path: "\(name).done")
        try Data().write(to: ready)

        let deadline = Date.now.addingTimeInterval(Self.captureTimeout)
        while !FileManager.default.fileExists(atPath: done.path(percentEncoded: false)), Date.now < deadline {
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: done.path(percentEncoded: false)), "capture.sh didn't save \(name)")
        try? FileManager.default.removeItem(at: done)
    }
}
