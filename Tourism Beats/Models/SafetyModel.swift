import Foundation

struct GPISafetyDataModel: Codable, Identifiable {
    var id: String { countryCode }

    let countryName: String
    let countryCode: String
    let region: String
    let rank: Int
    let score: Double
    let rankChange: Int
    let scoreChange: Double
}
