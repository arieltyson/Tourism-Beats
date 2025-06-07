protocol VisaProtocol {
    func fetchVisaRequirement(
        passport: String,
        destination: String
    ) async throws -> VisaModel
}
