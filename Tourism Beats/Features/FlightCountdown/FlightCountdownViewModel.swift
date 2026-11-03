import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class FlightCountdownViewModel {
    private(set) var flights: [CountdownFlight] = []
    private(set) var isLoading = true
    private(set) var isSaving = false
    private(set) var hasLoaded = false
    var errorMessage: String?

    @ObservationIgnored private let store: any FlightCountdownStoring
    @ObservationIgnored private let reloadWidget: @MainActor () -> Void

    init(
        store: any FlightCountdownStoring = FlightCountdownStore(),
        reloadWidget: @escaping @MainActor () -> Void = {
            WidgetCenter.shared.reloadTimelines(ofKind: FlightCountdownConfiguration.widgetKind)
        }
    ) {
        self.store = store
        self.reloadWidget = reloadWidget
    }

    func load() async {
        guard !isSaving else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            flights = try await store.load().sorted { $0.departure < $1.departure }
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func save(_ flight: CountdownFlight) async -> Bool {
        var updated = flights.filter { $0.id != flight.id }
        updated.append(flight)
        return await persist(updated)
    }

    @discardableResult
    func delete(_ flight: CountdownFlight) async -> Bool {
        await persist(flights.filter { $0.id != flight.id })
    }

    private func persist(_ updated: [CountdownFlight]) async -> Bool {
        guard hasLoaded, !isSaving, !isLoading else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            let sorted = updated.sorted { $0.departure < $1.departure }
            try await store.save(sorted)
            flights = sorted
            reloadWidget()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
