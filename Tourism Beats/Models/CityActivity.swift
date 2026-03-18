import Foundation

struct CityActivity: Identifiable, Hashable, Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case see
        case `do`

        var label: String {
            switch self {
            case .see:
                "Sight"
            case .do:
                "Experience"
            }
        }

        var systemImage: String {
            switch self {
            case .see:
                "binoculars.fill"
            case .do:
                "figure.walk"
            }
        }
    }

    let id: String
    let name: String
    let summary: String
    let category: String
    let kind: Kind
    let imageURL: URL?
    let officialURL: URL?
    let sourceURL: URL?
    let sourceName: String
    let hours: String?
    let price: String?
    let address: String?
    let directions: String?
    let timingTip: String?
    let latitude: Double?
    let longitude: Double?
    let wikidataIdentifier: String?
    let sourcePageTitle: String?
    let sourceAnchor: String?

    var hasPracticalInfo: Bool {
        self.hours != nil
            || self.price != nil
            || self.address != nil
            || self.directions != nil
            || self.timingTip != nil
    }

    var locationSummary: String? {
        if let address, !address.isEmpty {
            return address
        }

        if let directions, !directions.isEmpty {
            return directions
        }

        return nil
    }
}
