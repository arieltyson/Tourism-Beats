import Foundation

protocol VisaServiceProtocol {
    func checkVisaFreeTravel(fromCountryCode: String, toCountryCode: String) async throws -> Bool
}
