protocol SafetyProtocol {
    func fetchSafetyData(for countryCode: String) async throws -> SafetyModel
}
