import Foundation

enum SafetyError: Error {
    case fileNotFound, decodingError, countryNotFound
}

actor SafetyService: SafetyProtocol {
    // Cache a dictionary keyed by uppercase ISO code → model
    private var byCode: [String: SafetyModel]?

    func fetchSafetyData(for countryCode: String) async throws -> SafetyModel {
        let map = try await loadIfNeeded()
        if let entry = map[countryCode.uppercased()] {
            return entry
        }
        throw SafetyError.countryNotFound
    }

    // MARK: - Loading

    private func loadIfNeeded() async throws -> [String: SafetyModel] {
        if let map = byCode { return map }

        guard
            let url = Bundle.main.url(
                forResource: "gpi_data_2024",
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
}
