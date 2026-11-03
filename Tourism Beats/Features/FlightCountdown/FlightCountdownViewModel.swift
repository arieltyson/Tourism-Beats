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
    /// Card photos for flights that use one, ready to draw.
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

    /// Saves a new or edited flight. A flight that no longer uses a photo
    /// has its photo removed.
    @discardableResult
    func save(_ flight: CountdownFlight, photo change: FlightPhotoChange = .unchanged) async -> Bool {
        var updated = flights.filter { $0.id != flight.id }
        updated.append(flight)
        let photoStore = photoStore
        let saved = await persist(updated) {
            if case let .replace(photo) = change, flight.cardTheme == .photo {
                try await photoStore.save(photo.data, for: flight.id)
            }
        }
        guard saved else { return false }
        if flight.cardTheme != .photo {
            await discardPhoto(of: flight.id)
        } else if case let .replace(photo) = change {
            photos[flight.id] = photo.image
        }
        return true
    }

    @discardableResult
    func delete(_ flight: CountdownFlight) async -> Bool {
        guard await persist(flights.filter({ $0.id != flight.id })) else { return false }
        await discardPhoto(of: flight.id)
        return true
    }

    /// Writes the flights, after any photo they depend on, then refreshes the widget.
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
            if let photo = photos[flight.id] {
                loaded[flight.id] = photo
            } else {
                loaded[flight.id] = await photoStore.image(
                    for: flight.id, maximumPixelSize: FlightCountdownTokens.photoPixelSize
                )
            }
        }
        photos = loaded
    }

    /// A leftover photo only takes space, so failing to remove it isn't
    /// worth interrupting anyone over.
    private func discardPhoto(of id: UUID) async {
        photos[id] = nil
        do {
            try await photoStore.remove(for: id)
        } catch {
            logger.error("Couldn't remove a card photo: \(error.localizedDescription, privacy: .public)")
        }
    }
}
