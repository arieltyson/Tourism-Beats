import Foundation

protocol SafetyServiceProtocol {
    func fetchSafetyData(for countryCode: String) async throws -> GPISafetyDataModel
}

