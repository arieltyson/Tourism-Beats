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

    private func source(_ identifier: String?, _ data: Data) -> FlightPhotoSource {
        FlightPhotoSource(identifier: identifier) { data }
    }

    @Test func choosingPhotosMakesThemTheBackground() async throws {
        let form = FlightCountdownFormViewModel(flight: flight())
        #expect(!form.hasChanges)
        form.cardTheme = .photo
        #expect(!form.canSave)
        let data = try cameraPhoto()
        await form.usePhotos([source("a", data), source("b", data)])
        #expect(form.cardTheme == .photo)
        #expect(form.cardImages.count == 2)
        #expect(form.hasChanges)
        #expect(form.canSave)
        #expect(form.flight.photos.map(\.sourceIdentifier) == ["a", "b"])

        form.cardTheme = .ocean
        #expect(form.flight.photos.isEmpty)
    }

    @Test func choosingAgainKeepsFramingAndOrder() async throws {
        let form = FlightCountdownFormViewModel(flight: flight())
        let data = try cameraPhoto()
        await form.usePhotos([source("a", data), source("b", data)])
        let first = try #require(form.photos.first)
        let framing = FlightPhotoFraming(focusX: 0.2, focusY: 0.7, zoom: 2)
        form.applyFramings([first.id: framing])

        await form.usePhotos([source("c", data), source("a", data)])
        #expect(form.photos.map(\.sourceIdentifier) == ["c", "a"])
        #expect(form.photos.last?.id == first.id)
        #expect(form.photos.last?.framing == framing)
        #expect(form.newPhotos.count == 2)

        await form.usePhotos([source("x", Data("not a photo".utf8))])
        #expect(form.photos.count == 2)
        #expect(form.photoErrorMessage != nil)

        await form.usePhotos([])
        #expect(form.photos.isEmpty)
        #expect(form.cardTheme == FlightCardTheme.gradients.first)
    }

    @Test func aCollageHoldsAtMostFourPhotos() async throws {
        let form = FlightCountdownFormViewModel(flight: flight())
        let data = try cameraPhoto()
        await form.usePhotos((0..<6).map { source("\($0)", data) })
        #expect(form.photos.count == FlightCountdownStyle.maximumCollageCount)
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
        let first = FlightCardPhoto(sourceIdentifier: "a")
        let second = FlightCardPhoto(sourceIdentifier: "b")
        var value = flight(theme: .photo)
        value.photos = [first, second]

        #expect(await model.save(value, newPhotos: [first.id: photo, second.id: photo]))
        #expect(model.images(for: value).count == 2)
        #expect(await photoStore.image(for: second.id, maximumPixelSize: 100) != nil)

        let reloaded = FlightCountdownViewModel(
            store: FlightCountdownStore(directory: directory), photoStore: photoStore, reloadWidget: {}
        )
        await reloaded.load()
        #expect(reloaded.images(for: value).map(\.id) == [first.id, second.id])

        value.photos = [first]
        #expect(await model.save(value))
        #expect(await photoStore.image(for: first.id, maximumPixelSize: 100) != nil)
        #expect(await photoStore.image(for: second.id, maximumPixelSize: 100) == nil)

        value.cardTheme = .ocean
        value.photos = []
        #expect(await model.save(value))
        #expect(model.images(for: value).isEmpty)
        #expect(await photoStore.image(for: first.id, maximumPixelSize: 100) == nil)

        value.cardTheme = .photo
        value.photos = [first]
        #expect(await model.save(value, newPhotos: [first.id: photo]))
        #expect(await model.delete(value))
        #expect(await photoStore.image(for: first.id, maximumPixelSize: 100) == nil)
        #expect(model.changeCount == 5)
    }

    /// A card from before collages kept its one photo under the flight's ID.
    @Test func singlePhotoCardsBecomeOnePhotoCollages() throws {
        let json = """
        {"id":"00000000-0000-0000-0000-000000000002","airlineCode":"AC","flightNumber":"308","origin":"YVR","destination":"YUL","departure":100,"timeZoneIdentifier":"America/Vancouver","cardTheme":"photo"}
        """
        let decoded = try JSONDecoder().decode(CountdownFlight.self, from: Data(json.utf8))
        #expect(decoded.photos.map(\.id) == [decoded.id])
        #expect(decoded.photos.first?.framing == .centered)
        let roundTripped = try JSONDecoder().decode(CountdownFlight.self, from: JSONEncoder().encode(decoded))
        #expect(roundTripped == decoded)
    }

    @Test func framingCoversTheFrameAndKeepsItsFocusCentred() {
        let image = CGSize(width: 3_000, height: 2_000)
        let wide = CGSize(width: 360, height: 200)
        let square = CGSize(width: 170, height: 170)

        let centred = FlightPhotoFraming.centered.rect(for: image, in: wide)
        #expect(centred.width == 360 && centred.minX == 0)
        #expect(abs(centred.midY - wide.height / 2) < 0.001)

        // Dragging past an edge stops at it and stores no hidden travel.
        let dragged = FlightPhotoFraming.centered.moved(by: CGSize(width: 500, height: 0), imageSize: image, frameSize: square)
        let stopped = dragged.rect(for: image, in: square)
        #expect(stopped.minX == 0)
        let back = dragged.moved(by: CGSize(width: -10, height: 0), imageSize: image, frameSize: square)
        #expect(abs(back.rect(for: image, in: square).minX + 10) < 0.001)

        // The same framing serves every shape and never shows an edge.
        let zoomed = FlightPhotoFraming(focusX: 0.9, focusY: 0.1, zoom: 3)
        for frame in [wide, square] {
            let rect = zoomed.rect(for: image, in: frame)
            #expect(rect.minX <= 0 && rect.maxX >= frame.width - 0.001)
            #expect(rect.minY <= 0 && rect.maxY >= frame.height - 0.001)
        }
        #expect(FlightPhotoFraming.centered.zoomed(by: 100).zoom == FlightPhotoFraming.zoomRange.upperBound)
        #expect(FlightPhotoFraming.centered.zoomed(by: 0.1).zoom == FlightPhotoFraming.zoomRange.lowerBound)
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
