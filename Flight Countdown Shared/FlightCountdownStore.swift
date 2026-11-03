import Foundation

/// Only the app writes; the extension reads an atomically replaced snapshot.
actor FlightCountdownStore: FlightCountdownStoring {
    private let fileURL: URL?

    init(directory: URL? = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: FlightCountdownConfiguration.appGroup
    )) {
        fileURL = directory?.appending(path: "flight-countdowns.json")
    }

    func load() throws -> [CountdownFlight] {
        guard let fileURL else { throw FlightCountdownStorageError.unavailable }
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return [] }
        return try JSONDecoder().decode([CountdownFlight].self, from: Data(contentsOf: fileURL))
    }

    func save(_ flights: [CountdownFlight]) throws {
        guard let fileURL else { throw FlightCountdownStorageError.unavailable }
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(flights).write(
            to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }
}
