import CoreGraphics
import Foundation
import Observation
import OSLog
import WidgetKit

/// The flights being counted down to, kept in step with the widget.
@MainActor
@Observable
final class FlightCountdownViewModel {
    private(set) var flights: [CountdownFlight] = []
    /// Card photos for flights that use them, by photo, ready to draw.
    private(set) var photos: [UUID: CGImage] = [:]
    private(set) var isLoading = true
    private(set) var isSaving = false
    private(set) var hasLoaded = false
    /// Counts saves and deletions, so each one can be felt.
    private(set) var changeCount = 0
    var errorMessage: String?

    @ObservationIgnored private let store: any FlightCountdownStoring
    @ObservationIgnored private let photoStore: any FlightPhotoStoring
    @ObservationIgnored private let reloadWidget: @MainActor () -> Void
    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TourismBeats", category: "FlightCountdown"
    )

    init(
        store: any FlightCountdownStoring = FlightCountdownStore(),
        photoStore: any FlightPhotoStoring = FlightPhotoStore(),
        reloadWidget: @escaping @MainActor () -> Void = {
            WidgetCenter.shared.reloadTimelines(ofKind: FlightCountdownConfiguration.widgetKind)
        }
    ) {
        self.store = store
        self.photoStore = photoStore
        self.reloadWidget = reloadWidget
    }

    var nextFlight: CountdownFlight? { CountdownFlight.next(in: flights, after: .now) }

    func load() async {
        guard !isSaving else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            flights = try await store.load().sorted { $0.departure < $1.departure }
            if flights.contains(where: { $0.countdownStartedAt == nil }) {
                let now = Date.now
                for index in flights.indices where flights[index].countdownStartedAt == nil {
                    flights[index].countdownStartedAt = now
                }
                try await store.save(flights)
                reloadWidget()
            }
            hasLoaded = true
            await loadPhotos()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The flight's card photos in collage order, as far as they've loaded.
    func images(for flight: CountdownFlight) -> [FlightCardImage] {
        FlightCardImage.images(for: flight, from: photos)
    }

    /// Saves a new or edited flight with any photos just chosen for it.
    /// Photos the flight no longer uses are removed.
    @discardableResult
    func save(_ flight: CountdownFlight, newPhotos: [UUID: FlightPhoto] = [:]) async -> Bool {
        let previous = flights.first { $0.id == flight.id }
        var updated = flights.filter { $0.id != flight.id }
        updated.append(flight)
        let added = flight.photos.compactMap { photo in newPhotos[photo.id].map { (id: photo.id, photo: $0) } }
        let photoStore = photoStore
        let saved = await persist(updated) {
            for (id, photo) in added {
                try await photoStore.save(photo.data, for: id)
            }
        }
        guard saved else { return false }
        for (id, photo) in added {
            photos[id] = photo.image
        }
        let kept = Set(flight.photos.map(\.id))
        await discardPhotos((previous?.photos ?? []).map(\.id).filter { !kept.contains($0) })
        return true
    }

    @discardableResult
    func delete(_ flight: CountdownFlight) async -> Bool {
        guard await persist(flights.filter({ $0.id != flight.id })) else { return false }
        await discardPhotos(flight.photos.map(\.id))
        return true
    }

    /// Writes the flights, after any photos they depend on, then refreshes the widget.
    private func persist(
        _ updated: [CountdownFlight], afterPreparing prepare: () async throws -> Void = {}
    ) async -> Bool {
        guard hasLoaded, !isSaving, !isLoading else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await prepare()
            let sorted = updated.sorted { $0.departure < $1.departure }
            try await store.save(sorted)
            flights = sorted
            changeCount += 1
            reloadWidget()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func loadPhotos() async {
        var loaded: [UUID: CGImage] = [:]
        for flight in flights where flight.cardTheme == .photo {
            for photo in flight.photos {
                if let image = photos[photo.id] {
                    loaded[photo.id] = image
                } else {
                    loaded[photo.id] = await photoStore.image(
                        for: photo.id, maximumPixelSize: FlightCountdownTokens.photoPixelSize
                    )
                }
            }
        }
        photos = loaded
    }

    /// A leftover photo only takes space, so failing to remove it isn't
    /// worth interrupting anyone over.
    private func discardPhotos(_ ids: [UUID]) async {
        for id in ids {
            photos[id] = nil
            do {
                try await photoStore.remove(for: id)
            } catch {
                logger.error("Couldn't remove a card photo: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
