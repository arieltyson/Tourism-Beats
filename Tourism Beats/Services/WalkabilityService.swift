import Foundation

// MARK: - WalkabilityError

enum WalkabilityError: Error {
    case fileNotFound
    case decodingError
    case cityNotFound
}

// MARK: - WalkabilityService

actor WalkabilityService: WalkabilityProtocol {
    /// Cache keyed by "CITY|COUNTRYCODE"
    private var cache: [String: WalkabilityModel]?

    func fetchWalkability(
        city: String,
        countryCode: String
    ) async throws -> WalkabilityModel {
        let map = try await self.loadIfNeeded()
        let key = "\(city.uppercased())|\(countryCode.uppercased())"
        if let entry = map[key] {
            return entry
        }
        throw WalkabilityError.cityNotFound
    }

    // MARK: - Loading

    private func loadIfNeeded() async throws -> [String: WalkabilityModel] {
        if let map = self.cache { return map }

        guard
            let url = Bundle.main.url(
                forResource: "walkability_data",
                withExtension: "json"
            )
        else { throw WalkabilityError.fileNotFound }

        do {
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode(
                [WalkabilityModel].self,
                from: data
            )
            let map = Dictionary(
                uniqueKeysWithValues: list.map {
                    ("\($0.city.uppercased())|\($0.countryCode.uppercased())", $0)
                }
            )
            self.cache = map
            return map
        } catch {
            throw WalkabilityError.decodingError
        }
    }
}
