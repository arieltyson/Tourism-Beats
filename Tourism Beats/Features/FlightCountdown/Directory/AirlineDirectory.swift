import Foundation
import OSLog

/// Searches the bundled airlines by name or IATA designator.
struct AirlineDirectory: Sendable {
    static let bundled = AirlineDirectory(resource: "airlines", in: .main)

    /// Every airline, alphabetised for browsing.
    let airlines: [Airline]
    private let airlinesByCode: [String: Airline]

    init(airlines: [Airline]) {
        self.airlines = airlines.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        airlinesByCode = Dictionary(airlines.map { ($0.code, $0) }) { first, _ in first }
    }

    init(resource: String, in bundle: Bundle) {
        let logger = Logger(subsystem: bundle.bundleIdentifier ?? "TourismBeats", category: "AirlineDirectory")
        do {
            guard let url = bundle.url(forResource: resource, withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            self.init(airlines: try JSONDecoder().decode([Airline].self, from: Data(contentsOf: url)))
        } catch {
            logger.error("Couldn't load the airline directory: \(error.localizedDescription, privacy: .public)")
            self.init(airlines: [])
        }
    }

    func airline(code: String) -> Airline? {
        airlinesByCode[code.uppercased()]
    }

    /// Airlines matching `query`, best match first; every airline when empty.
    func results(matching query: String) -> [Airline] {
        let query = DirectoryMatch.normalized(query)
        guard !query.isEmpty else { return airlines }
        return airlines
            .compactMap { airline -> (airline: Airline, match: DirectoryMatch)? in
                if airline.code.caseInsensitiveCompare(query) == .orderedSame { return (airline, .code) }
                return DirectoryMatch.rank(airline.name, for: query).map { (airline, $0) }
            }
            .sorted { $0.match < $1.match }
            .map(\.airline)
    }
}
