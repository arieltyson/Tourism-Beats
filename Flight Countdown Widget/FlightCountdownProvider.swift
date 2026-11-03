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
                let page = FlightWidgetCarousel.page(in: flights, at: now, selectedID: FlightWidgetSelection.selectedID())
                let images = await Self.images(for: page.map { [$0.flight] } ?? [], displaySize: displaySize)
                completion(Self.entry(at: now, page: page, images: images))
            } catch {
                completion(FlightCountdownEntry(date: .now, page: nil, isUnavailable: true))
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
                // Each entry shows the chosen flight until it departs, then the next.
                let selectedID = FlightWidgetSelection.selectedID()
                let pages = dates.map { FlightWidgetCarousel.page(in: flights, at: $0, selectedID: selectedID) }
                let images = await Self.images(for: pages.compactMap(\.?.flight), displaySize: displaySize)
                let entries = zip(dates, pages).map { Self.entry(at: $0, page: $1, images: images) }
                completion(Timeline(entries: entries, policy: .atEnd))
            } catch {
                let entry = FlightCountdownEntry(date: now, page: nil, isUnavailable: true)
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
            let pixelSize = photoPixelSize(for: displaySize, count: flight.photos.count)
            for photo in flight.photos where images[photo.id] == nil {
                images[photo.id] = await store.image(for: photo.id, maximumPixelSize: pixelSize)
            }
        }
        return images
    }

    /// A photo sharing the widget with two or more others spans at most
    /// half of it, so it's loaded at half the size to stay within the
    /// widget's memory.
    private static func photoPixelSize(for size: CGSize, count: Int) -> Int {
        let side = max(size.width, size.height) * FlightCountdownConfiguration.maximumDisplayScale
        return Int(count > 2 ? side / 2 : side)
    }

    private static func entry(at date: Date, page: FlightWidgetPage?, images: [UUID: CGImage]) -> FlightCountdownEntry {
        FlightCountdownEntry(
            date: date, page: page, photos: page.map { FlightCardImage.images(for: $0.flight, from: images) } ?? []
        )
    }

    private var sample: FlightCountdownEntry {
        FlightCountdownEntry(date: .now, page: FlightWidgetPage(flight: .sample(from: .now), position: 1, count: 1))
    }
}
