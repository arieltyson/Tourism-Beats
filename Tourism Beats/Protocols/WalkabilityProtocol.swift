// MARK: - WalkabilityProtocol

protocol WalkabilityProtocol: Sendable {
    /// The scores for a city. The state or province tells apart cities in one
    /// country that share a name, such as Portland, Maine and Portland, Oregon.
    func fetchWalkability(
        city: String,
        administrativeArea: String?,
        countryCode: String
    ) async throws -> WalkabilityModel
}
