protocol SafetyServiceProtocol {
    func fetchSafetyData(for countryCode: String) async throws -> SafetyModel
}
