import Foundation

// MARK: - WalkabilityError

enum WalkabilityError: Error {
    case fileNotFound
    case decodingError
    case cityNotFound
}

// MARK: - WalkabilityService

actor WalkabilityService: WalkabilityProtocol {
    /// Cache keyed by "CITY|COUNTRYCODE", or "CITY|AREA|COUNTRYCODE" for
    /// rows that name their state or province.
    private var cache: [String: WalkabilityModel]?

    func fetchWalkability(
        city: String,
        administrativeArea: String?,
        countryCode: String
    ) async throws -> WalkabilityModel {
        let map = try await self.loadIfNeeded()
        let keys = [
            administrativeArea.map {
                Self.normalizedLookupKey(city: city, administrativeArea: $0, countryCode: countryCode)
            },
            Self.normalizedLookupKey(city: city, administrativeArea: nil, countryCode: countryCode),
        ]
        guard let entry = keys.compactMap(\.self).lazy.compactMap({ map[$0] }).first else {
            throw WalkabilityError.cityNotFound
        }
        return entry
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
            // Keep the first row for a key rather than trap on a repeat.
            let map = list.reduce(into: [String: WalkabilityModel]()) { map, row in
                let key = Self.normalizedLookupKey(
                    city: row.city,
                    administrativeArea: row.administrativeArea,
                    countryCode: row.countryCode
                )
                if map[key] == nil { map[key] = row }
            }
            self.cache = map
            return map
        } catch {
            throw WalkabilityError.decodingError
        }
    }

    private static func normalizedLookupKey(
        city: String,
        administrativeArea: String?,
        countryCode: String
    ) -> String {
        let names = [city, administrativeArea].compactMap(\.self).map(Self.normalized)
        return (names + [countryCode.uppercased()]).joined(separator: "|")
    }

    private static func normalized(_ name: String) -> String {
        let folded = name.folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )
        let tokens = folded.unicodeScalars.split { scalar in
            !CharacterSet.alphanumerics.contains(scalar)
        }
        return tokens.map(String.init).joined(separator: " ").uppercased()
    }
}
