import Foundation

// MARK: - SafetyError

enum SafetyError: Error {
    case fileNotFound, decodingError, countryNotFound
}

// MARK: - SafetyService

actor SafetyService: SafetyProtocol {
    // Cache a dictionary keyed by uppercase ISO code → model
    private var byCode: [String: SafetyModel]?
    /// Each territory's governing country, by ISO code.
    private var governingCountries: [String: String]?

    /// The country's own index or, for a territory the index doesn't rank,
    /// the index of the country that governs it. Countries the index doesn't
    /// rank at all, such as many small island states, throw `countryNotFound`.
    func fetchSafetyData(for countryCode: String) async throws -> SafetyModel {
        let map = try await loadIfNeeded()
        let code = countryCode.uppercased()
        if let entry = map[code] {
            return entry
        }
        if let governingCode = self.loadGoverningCountries()[code], let entry = map[governingCode] {
            return entry
        }
        throw SafetyError.countryNotFound
    }

    // MARK: - Loading

    private func loadIfNeeded() async throws -> [String: SafetyModel] {
        if let map = byCode { return map }

        guard
            let url = Bundle.main.url(
                forResource: "gpi_data_2026",
                withExtension: "json"
            )
        else { throw SafetyError.fileNotFound }

        do {
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode([SafetyModel].self, from: data)
            let map = Dictionary(
                uniqueKeysWithValues: list.map {
                    ($0.countryCode.uppercased(), $0)
                }
            )
            self.byCode = map
            return map
        } catch {
            throw SafetyError.decodingError
        }
    }

    /// The territories the index scores through their governing country.
    /// Missing, it leaves territories unranked rather than failing the rest.
    private func loadGoverningCountries() -> [String: String] {
        if let governingCountries { return governingCountries }
        let map = Bundle.main.url(forResource: "gpi_governing_countries", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) }
            ?? [:]
        self.governingCountries = map
        return map
    }
}
