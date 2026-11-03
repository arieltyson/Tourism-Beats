import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Tourism_Beats

@MainActor
struct FlightCardTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func flight(theme: FlightCardTheme = .twilight) -> CountdownFlight {
        CountdownFlight(
            airlineCode: "AC", flightNumber: "308", origin: "YVR", destination: "YUL",
            departure: now.addingTimeInterval(3_600), timeZoneIdentifier: "America/Vancouver", cardTheme: theme
        )
    }

    /// A large photo carrying a location, as a camera would save it.
    private func cameraPhoto() throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: 3_000, height: 2_000, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 3_000, height: 2_000))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        let location: [CFString: Any] = [kCGImagePropertyGPSLatitude: 49.19, kCGImagePropertyGPSLongitude: 123.18]
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyGPSDictionary: location] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    @Test func photosAreDownsizedAndLoseTheirLocation() async throws {
        let original = try cameraPhoto()
        let originalProperties = CGImageSourceCopyPropertiesAtIndex(
            try #require(CGImageSourceCreateWithData(original as CFData, nil)), 0, nil
        ) as? [CFString: Any]
        #expect(originalProperties?[kCGImagePropertyGPSDictionary] != nil)

        let photo = try await FlightPhotoProcessor.prepare(original)
        #expect(max(photo.image.width, photo.image.height) == FlightCountdownTokens.photoPixelSize)
        let source = try #require(CGImageSourceCreateWithData(photo.data as CFData, nil))
        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        #expect(properties?[kCGImagePropertyGPSDictionary] == nil)
    }

    @Test func unreadableDataIsRejected() async {
        await #expect(throws: FlightPhotoError.self) {
            try await FlightPhotoProcessor.prepare(Data("not a photo".utf8))
        }
    }

    @Test func choosingAPhotoMakesItTheBackground() async throws {
        let form = FlightCountdownFormViewModel(flight: flight())
        #expect(!form.hasChanges)
        form.cardTheme = .photo
        #expect(!form.canSave)
        await form.usePhoto(try cameraPhoto())
        #expect(form.cardTheme == .photo)
        #expect(form.photo != nil)
        #expect(form.hasChanges)
        #expect(form.canSave)
        #expect(form.flight.cardTheme == .photo)
    }

    @Test func photosAreSavedWithTheFlightAndRemovedWhenNoLongerUsed() async throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let photoStore = FlightPhotoStore(directory: directory.appending(path: "photos"))
        let model = FlightCountdownViewModel(
            store: FlightCountdownStore(directory: directory), photoStore: photoStore, reloadWidget: {}
        )
        await model.load()
        let photo = try await FlightPhotoProcessor.prepare(try cameraPhoto())
        var value = flight(theme: .photo)

        #expect(await model.save(value, photo: .replace(photo)))
        #expect(model.photos[value.id] != nil)
        #expect(await photoStore.image(for: value.id, maximumPixelSize: 100) != nil)

        let reloaded = FlightCountdownViewModel(
            store: FlightCountdownStore(directory: directory), photoStore: photoStore, reloadWidget: {}
        )
        await reloaded.load()
        #expect(reloaded.photos[value.id] != nil)

        value.cardTheme = .ocean
        #expect(await model.save(value))
        #expect(model.photos[value.id] == nil)
        #expect(await photoStore.image(for: value.id, maximumPixelSize: 100) == nil)

        value.cardTheme = .photo
        #expect(await model.save(value, photo: .replace(photo)))
        #expect(await model.delete(value))
        #expect(await photoStore.image(for: value.id, maximumPixelSize: 100) == nil)
        #expect(model.changeCount == 4)
    }

    @Test func flightsSavedBeforeDesignsUseTwilight() throws {
        let json = """
        {"id":"00000000-0000-0000-0000-000000000001","flightNumber":"AC 123","origin":"YVR","destination":"YYZ","departure":100,"timeZoneIdentifier":"America/Vancouver"}
        """
        #expect(try JSONDecoder().decode(CountdownFlight.self, from: Data(json.utf8)).cardTheme == .twilight)
    }

    /// A departures board's columns: months and days, then days and hours
    /// within a month, then hours and minutes on the day.
    @Test func countdownShowsTheTwoUnitsThatMatter() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Vancouver"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: 13, minute: 18)))
        func columns(_ components: DateComponents) throws -> [String] {
            let departure = try #require(calendar.date(byAdding: components, to: start))
            return FlightCountdownText.components(until: departure, from: start, calendar: calendar)
                .map { "\($0.value) \($0.unit)" }
        }
        #expect(try columns(DateComponents(month: 1, day: 17, hour: 5)) == ["1 month", "17 day"])
        #expect(try columns(DateComponents(month: 14)) == ["14 month", "0 day"])
        #expect(try columns(DateComponents(day: 29, hour: 23, minute: 59)) == ["29 day", "23 hour"])
        #expect(try columns(DateComponents(day: 1)) == ["1 day", "0 hour"])
        #expect(try columns(DateComponents(hour: 5, minute: 7, second: 30)) == ["5 hour", "7 minute"])
        #expect(try columns(DateComponents(minute: 45)) == ["0 hour", "45 minute"])
        #expect(try columns(DateComponents(second: -1)).isEmpty)
    }

    @Test func unitsAgreeWithTheirNumbers() {
        let locale = Locale(identifier: "en_US")
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        func label(_ value: Int, _ unit: FlightCountdownUnit) -> String {
            FlightCountdownComponent(value: value, unit: unit).unitLabel(calendar: calendar, locale: locale)
        }
        #expect(label(1, .month) == "month")
        #expect(label(2, .month) == "months")
        #expect(label(17, .day) == "days")
        #expect(label(0, .hour) == "hours")
        #expect(label(1, .minute) == "minute")
    }

    @Test func countdownIsSpokenAsTheCardShowsIt() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        let departure = try #require(calendar.date(byAdding: DateComponents(month: 1, day: 17, hour: 3), to: now))
        let spoken = FlightCountdownText.remaining(until: departure, from: now, calendar: calendar)
        #expect(spoken.contains("1 month") && spoken.contains("17 days") && !spoken.contains("hour"))
    }
}
