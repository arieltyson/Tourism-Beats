import Foundation

enum VisaServiceError: Error {
    case fileNotFound, decodingError, requirementNotFound
}

class VisaService: VisaServiceProtocol {
    private let fileName = "visa_requirements_2025"
    private var cache: [VisaRequirementModel]?

    private func loadAll() throws -> [VisaRequirementModel] {
        if let c = cache { return c }
        guard let url = Bundle.main.url(
            forResource: fileName, withExtension: "json"
        ) else { throw VisaServiceError.fileNotFound }

        let data = try Data(contentsOf: url)
        let list = try JSONDecoder().decode(
            [VisaRequirementModel].self, from: data
        )
        cache = list
        return list
    }

    func fetchVisaRequirement(
        passport: String,
        destination: String
    ) async throws -> VisaRequirementModel {
        let list = try loadAll()
        if let entry = list.first(where: {
            $0.passport.uppercased() == passport.uppercased() &&
            $0.destination.uppercased() == destination.uppercased()
        }) {
            return entry
        }
        throw VisaServiceError.requirementNotFound
    }
}
