import Foundation
import OSLog

/// Searches the bundled airports by city, name, or code.
struct AirportDirectory: Sendable {
    static let bundled = AirportDirectory(resource: "airports", in: .main)
    private static let maximumGroups = 30

    let airports: [Airport]
    private let airportsByCode: [String: Airport]
    /// Everything searchable about each airport in one string, so a keystroke
    /// costs one comparison per airport and only matches are ranked.
    private let searchTexts: [String]

    init(airports: [Airport]) {
        self.airports = airports
        airportsByCode = Dictionary(airports.map { ($0.code, $0) }) { first, _ in first }
        searchTexts = airports.map { airport in
            [airport.code, airport.servedCity, airport.city, airport.name, airport.aliases ?? ""].joined(separator: " ")
        }
    }

    init(resource: String, in bundle: Bundle) {
        let logger = Logger(subsystem: bundle.bundleIdentifier ?? "TourismBeats", category: "AirportDirectory")
        do {
            guard let url = bundle.url(forResource: resource, withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile)
            }
            self.init(airports: try JSONDecoder().decode([Airport].self, from: Data(contentsOf: url)))
        } catch {
            logger.error("Couldn't load the airport directory: \(error.localizedDescription, privacy: .public)")
            self.init(airports: [])
        }
    }

    func airport(code: String) -> Airport? {
        airportsByCode[code.uppercased()]
    }

    /// Airports matching `query`, grouped by the city they serve.
    ///
    /// Searching "London" lists Heathrow, Gatwick, Stansted, Luton, City,
    /// and Southend together. Runs off the main actor so typing stays fluid.
    @concurrent
    func groups(matching query: String) async -> [AirportGroup] {
        results(matching: query)
    }

    func results(matching query: String) -> [AirportGroup] {
        let query = DirectoryMatch.normalized(query)
        guard !query.isEmpty else { return [] }
        let matches = zip(airports, searchTexts).compactMap { airport, text in
            text.localizedStandardContains(query) ? match(airport, query).map { (airport: airport, match: $0) } : nil
        }
        let grouped = Dictionary(grouping: matches) { "\($0.airport.servedCity)|\($0.airport.country)" }
        let ranked = grouped.values.map { members in
            members.sorted { ($0.match, $0.airport.size, $0.airport.name) < ($1.match, $1.airport.size, $1.airport.name) }
        }
        return ranked
            .sorted { lhs, rhs in
                (lhs[0].match, lhs[0].airport.size, lhs[0].airport.servedCity)
                    < (rhs[0].match, rhs[0].airport.size, rhs[0].airport.servedCity)
            }
            .prefix(Self.maximumGroups)
            .map { members in
                let first = members[0].airport
                return AirportGroup(
                    city: first.servedCity, countryName: first.countryName, airports: members.map(\.airport)
                )
            }
    }

    private func match(_ airport: Airport, _ query: String) -> DirectoryMatch? {
        if airport.code.caseInsensitiveCompare(query) == .orderedSame { return .code }
        return [airport.servedCity, airport.city, airport.name, airport.aliases ?? ""]
            .compactMap { DirectoryMatch.rank($0, for: query) }
            .min()
    }
}
