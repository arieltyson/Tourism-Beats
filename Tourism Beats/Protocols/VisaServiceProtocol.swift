protocol VisaServiceProtocol {
    func fetchVisaRequirement(
        passport: String,
        destination: String
    ) async throws -> VisaModel
}
