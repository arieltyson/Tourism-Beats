import Foundation
import Observation

// MARK: - TripStaySearchViewModel

/// Searches for a trip's hotel as the traveller types.
@MainActor
@Observable
final class TripStaySearchViewModel {
    /// The pause after typing before searching, so each keystroke
    /// doesn't start a search of its own.
    static let typingPause: Duration = .milliseconds(300)

    var query = ""
    private(set) var results: [TripStay] = []
    private(set) var isSearching = false
    private(set) var didFail = false

    let area: TripStaySearchArea

    @ObservationIgnored private let service: any TripStaySearching

    init(area: TripStaySearchArea, service: any TripStaySearching = TripStaySearchService()) {
        self.area = area
        self.service = service
    }

    var trimmedQuery: String {
        self.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Searches for the current query once typing pauses. Call from a task
    /// keyed on the query, so a newer query cancels this one.
    func search() async {
        let query = self.trimmedQuery
        if !query.isEmpty {
            do {
                try await Task.sleep(for: Self.typingPause)
            } catch {
                return
            }
        }

        self.isSearching = true
        defer { if !Task.isCancelled { self.isSearching = false } }

        do {
            let stays = try await self.service.stays(matching: query, in: self.area)
            guard !Task.isCancelled else { return }
            self.results = stays
            self.didFail = false
        } catch {
            guard !Task.isCancelled else { return }
            self.results = []
            self.didFail = true
        }
    }
}
