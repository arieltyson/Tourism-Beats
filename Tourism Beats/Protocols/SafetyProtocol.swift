protocol SafetyProtocol: Sendable {
    func fetchSafetyData(for countryCode: String) async throws -> SafetyModel
}
