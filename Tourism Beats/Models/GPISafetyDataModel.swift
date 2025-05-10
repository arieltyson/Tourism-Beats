import Foundation

/// Mirrors each object in gpi_data_2024.json
struct GPISafetyDataModel: Codable, Identifiable {
    var id: String { countryCode }
    
    let countryName: String     // e.g. "Canada"
    let countryCode: String     // e.g. "CA"
    let region: String          // e.g. "North America"
    let rank: Int               // GPI rank
    let score: Double           // 1.0…5.0 peace index
    let rankChange: Int
    let scoreChange: Double
}
