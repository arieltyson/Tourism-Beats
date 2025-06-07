import Foundation

enum SafetyError: Error {
    case fileNotFound, decodingError, countryNotFound
}

class SafetyService: SafetyProtocol {
    func fetchSafetyData(for countryCode: String) async throws -> SafetyModel {
        // 1. Locate bundled JSON
        guard
            let url = Bundle.main.url(
                forResource: "gpi_data_2024",
                withExtension: "json"
            )
        else {
            throw SafetyError.fileNotFound
        }
        let raw = try Data(contentsOf: url)

        // 2. Decode full list
        let decoder = JSONDecoder()
        let list = try decoder.decode([SafetyModel].self, from: raw)

        // 3. Filter by code (case-insensitive)
        if let entry = list.first(where: {
            $0.countryCode.uppercased() == countryCode.uppercased()
        }) {
            return entry
        } else {
            throw SafetyError.countryNotFound
        }
    }
}
