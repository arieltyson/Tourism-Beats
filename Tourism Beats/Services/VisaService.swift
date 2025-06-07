import Foundation

enum VisaError: Error {
    case fileNotFound, decodingError, requirementNotFound
}

class VisaService: VisaProtocol {
    private let fileName = "visa_requirements_2025"
    private var cache: [VisaModel]?

    private func loadAll() throws -> [VisaModel] {
        if let c = cache { return c }
        guard
            let url = Bundle.main.url(
                forResource: fileName,
                withExtension: "json"
            )
        else { throw VisaError.fileNotFound }

        let data = try Data(contentsOf: url)
        let list = try JSONDecoder().decode(
            [VisaModel].self,
            from: data
        )
        cache = list
        return list
    }

    func fetchVisaRequirement(
        passport: String,
        destination: String
    ) async throws -> VisaModel {
        let list = try loadAll()
        if let entry = list.first(where: {
            $0.passport.uppercased() == passport.uppercased()
                && $0.destination.uppercased() == destination.uppercased()
        }) {
            return entry
        }
        throw VisaError.requirementNotFound
    }
}
