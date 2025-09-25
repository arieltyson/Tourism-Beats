import Foundation

enum VisaError: Error {
    case fileNotFound, decodingError, requirementNotFound
}

actor VisaService: VisaProtocol {
    private let fileName = "visa_requirements_2025"

    // Cache a map: "PASSPORT|DEST" (uppercased) → model
    private var cache: [String: VisaModel]?

    private func loadAll() throws -> [String: VisaModel] {
        if let c = cache { return c }
        guard
            let url = Bundle.main.url(
                forResource: fileName,
                withExtension: "json"
            )
        else { throw VisaError.fileNotFound }

        do {
            let data = try Data(contentsOf: url)
            let list = try JSONDecoder().decode([VisaModel].self, from: data)
            let map = Dictionary(
                uniqueKeysWithValues: list.map {
                    (
                        "\($0.passport.uppercased())|\($0.destination.uppercased())",
                        $0
                    )
                }
            )
            self.cache = map
            return map
        } catch {
            throw VisaError.decodingError
        }
    }

    func fetchVisaRequirement(passport: String, destination: String)
        async throws -> VisaModel
    {
        let map = try loadAll()
        if let entry = map[
            "\(passport.uppercased())|\(destination.uppercased())"
        ] {
            return entry
        }
        throw VisaError.requirementNotFound
    }
}
