protocol VisaProtocol: Sendable {
    func fetchVisaRequirement(
        passport: String,
        destination: String
    ) async throws -> VisaModel
}
