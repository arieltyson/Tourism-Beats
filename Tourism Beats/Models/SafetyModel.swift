import Foundation

struct SafetyModel: Codable, Identifiable, Sendable {
    var id: String { self.countryCode }

    let countryName: String
    let countryCode: String
    let region: String
    let rank: Int
    let score: Double
    let rankChange: Int
    let scoreChange: Double
}
