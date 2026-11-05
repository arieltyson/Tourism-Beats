import CoreGraphics
import WidgetKit

struct FlightCountdownProvider: TimelineProvider, Sendable {
    func placeholder(in context: Context) -> FlightCountdownEntry {
        sample
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (FlightCountdownEntry) -> Void) {
        if context.isPreview { completion(sample); return }
        let displaySize = context.displaySize
        Task {
            do {
                let flights = try await FlightCountdownStore().load()
                let now = Date.now
                let flight = CountdownFlight.next(in: flights, after: now)
                let images = await Self.images(for: flight.map { [$0] } ?? [], displaySize: displaySize)
                completion(Self.entry(at: now, flight: flight, images: images))
            } catch {
                completion(FlightCountdownEntry(date: .now, flight: nil, isUnavailable: true))
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<FlightCountdownEntry>) -> Void) {
        let displaySize = context.displaySize
        Task {
            let now = Date.now
            do {
                let flights = try await FlightCountdownStore().load()
                let dates = FlightCountdownSchedule.dates(for: flights, from: now)
                // Each entry shows the next flight until it departs, then the one after.
                let shown = dates.map { CountdownFlight.next(in: flights, after: $0) }
                let images = await Self.images(for: shown.compactMap(\.self), displaySize: displaySize)
                let entries = zip(dates, shown).map { Self.entry(at: $0, flight: $1, images: images) }
                completion(Timeline(entries: entries, policy: .atEnd))
            } catch {
                let entry = FlightCountdownEntry(date: now, flight: nil, isUnavailable: true)
                completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(FlightCountdownConfiguration.secondsPerHour))))
            }
        }
    }

    /// Loads each distinct photo once, no larger than the widget shows it;
    /// WidgetKit won't draw images much bigger than the widget itself.
    private static func images(for flights: [CountdownFlight], displaySize: CGSize) async -> [UUID: CGImage] {
        let store = FlightPhotoStore()
        var images: [UUID: CGImage] = [:]
        for flight in flights where flight.cardTheme == .photo {
            let pixelSize = photoPixelSize(for: displaySize)
            for photo in flight.photos where images[photo.id] == nil {
                images[photo.id] = await store.image(for: photo.id, maximumPixelSize: pixelSize)
            }
        }
        return images
    }

    /// Each photo fills the whole widget in its turn.
    private static func photoPixelSize(for size: CGSize) -> Int {
        Int(max(size.width, size.height) * FlightCountdownConfiguration.maximumDisplayScale)
    }

    private static func entry(at date: Date, flight: CountdownFlight?, images: [UUID: CGImage]) -> FlightCountdownEntry {
        FlightCountdownEntry(
            date: date, flight: flight, photos: flight.map { FlightCardImage.images(for: $0, from: images) } ?? []
        )
    }

    private var sample: FlightCountdownEntry {
        FlightCountdownEntry(date: .now, flight: .sample(from: .now))
    }
}
