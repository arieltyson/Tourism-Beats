// MARK: - WalkabilityProtocol

protocol WalkabilityProtocol: Sendable {
    func fetchWalkability(city: String, countryCode: String) async throws -> WalkabilityModel
}
