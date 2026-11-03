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

    @Test func headlineShowsTheLargestWholeUnit() {
        let day = FlightCountdownConfiguration.secondsPerDay
        let hour = FlightCountdownConfiguration.secondsPerHour
        func headline(_ interval: TimeInterval) -> String {
            String(FlightCountdownText.headline(until: now.addingTimeInterval(interval), from: now).characters)
        }
        #expect(headline(47 * day + 17 * hour) == "47 days")
        #expect(headline(day) == "1 day")
        #expect(headline(5 * hour + 1_800) == "5 hours")
        #expect(headline(30) == "1 minute")
        #expect(headline(-1) == "Departed")
        let marked = FlightCountdownText.headline(until: now.addingTimeInterval(47 * day), from: now)
        #expect(marked.runs.contains { $0.measurement == .value })
    }
}
