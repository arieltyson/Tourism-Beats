import Foundation

// MARK: - WalkabilityModel

struct WalkabilityModel: Codable, Identifiable, Sendable {
    var id: String { "\(self.city)|\(self.countryCode)" }

    let city: String
    let countryCode: String
    let walkScore: Int
    let transitScore: Int

    // MARK: - Walk Score Descriptors

    var walkDescription: String {
        switch self.walkScore {
        case 90...:
            "Walker's Paradise"
        case 70 ..< 90:
            "Very Walkable"
        case 50 ..< 70:
            "Somewhat Walkable"
        case 25 ..< 50:
            "Car-Dependent"
        default:
            "Car-Dependent"
        }
    }

    var walkDetail: String {
        switch self.walkScore {
        case 90...:
            "Daily errands do not require a car."
        case 70 ..< 90:
            "Most errands can be accomplished on foot."
        case 50 ..< 70:
            "Some errands can be accomplished on foot."
        case 25 ..< 50:
            "Most errands require a car."
        default:
            "Almost all errands require a car."
        }
    }

    // MARK: - Transit Score Descriptors

    var transitDescription: String {
        switch self.transitScore {
        case 90...:
            "World-Class Transit"
        case 70 ..< 90:
            "Excellent Transit"
        case 50 ..< 70:
            "Good Transit"
        case 25 ..< 50:
            "Some Transit"
        default:
            "Minimal Transit"
        }
    }

    var transitDetail: String {
        switch self.transitScore {
        case 90...:
            "Convenient for most trips."
        case 70 ..< 90:
            "Many nearby public transportation options."
        case 50 ..< 70:
            "Public transit is a convenient option for some trips."
        case 25 ..< 50:
            "A few public transportation options."
        default:
            "Very few public transportation options."
        }
    }
}
