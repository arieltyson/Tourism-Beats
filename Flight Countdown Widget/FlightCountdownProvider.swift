import CoreGraphics
import WidgetKit

struct FlightCountdownProvider: TimelineProvider, Sendable {
    func placeholder(in context: Context) -> FlightCountdownEntry {
        sample
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (FlightCountdownEntry) -> Void) {
        if context.isPreview { completion(sample); return }
        let pixelSize = Self.photoPixelSize(for: context.displaySize)
        Task {
            do {
                let flights = try await FlightCountdownStore().load()
                let now = Date.now
                let flight = CountdownFlight.next(in: flights, after: now)
                let photos = await Self.photos(for: flight.map { [$0] } ?? [], pixelSize: pixelSize)
                completion(FlightCountdownEntry(date: now, flight: flight, photo: flight.flatMap { photos[$0.id] }))
            } catch {
                completion(FlightCountdownEntry(date: .now, flight: nil, isUnavailable: true))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<FlightCountdownEntry>) -> Void) {
        let pixelSize = Self.photoPixelSize(for: context.displaySize)
        Task {
            let now = Date.now
            do {
                let flights = try await FlightCountdownStore().load()
                let dates = FlightCountdownSchedule.dates(for: flights, from: now)
                let upcoming = dates.compactMap { CountdownFlight.next(in: flights, after: $0) }
                let photos = await Self.photos(for: upcoming, pixelSize: pixelSize)
                let entries = dates.map { date in
                    let flight = CountdownFlight.next(in: flights, after: date)
                    return FlightCountdownEntry(date: date, flight: flight, photo: flight.flatMap { photos[$0.id] })
                }
                completion(Timeline(entries: entries, policy: .atEnd))
            } catch {
                let entry = FlightCountdownEntry(date: now, flight: nil, isUnavailable: true)
                completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(FlightCountdownConfiguration.secondsPerHour))))
            }
        }
    }

    /// Loads each distinct photo once, no larger than the widget shows it;
    /// WidgetKit won't draw images much bigger than the widget itself.
    private static func photos(for flights: [CountdownFlight], pixelSize: Int) async -> [UUID: CGImage] {
        let store = FlightPhotoStore()
        var photos: [UUID: CGImage] = [:]
        for flight in flights where flight.cardTheme == .photo && photos[flight.id] == nil {
            photos[flight.id] = await store.image(for: flight.id, maximumPixelSize: pixelSize)
        }
        return photos
    }

    private static func photoPixelSize(for size: CGSize) -> Int {
        Int(max(size.width, size.height) * FlightCountdownConfiguration.maximumDisplayScale)
    }

    private var sample: FlightCountdownEntry {
        FlightCountdownEntry(date: .now, flight: .sample(from: .now))
    }
}
