import Observation
import SwiftUI

@MainActor
@Observable
final class SafetyViewModel {
    private(set) var safetyData: SafetyModel?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let city: CityModel
    @ObservationIgnored private let safetyService: SafetyProtocol

    init(
        city: CityModel,
        safetyService: SafetyProtocol = SafetyService()
    ) {
        self.city = city
        self.safetyService = safetyService
    }

    func fetchSafetyData() async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            self.safetyData = try await self.safetyService.fetchSafetyData(
                for: self.city.country.code
            )
        } catch {
            self.errorMessage = "Could not load Global Peace Index data."
        }

        self.isLoading = false
    }

    var riskLevelText: String? {
        guard let score = self.safetyData?.score else { return nil }
        switch score {
        case ..<1.7:
            return "LOW"
        case 1.7 ..< 2.7:
            return "MED"
        case 2.7...:
            return "HIGH"
        default:
            return "Unknown"
        }
    }

    var riskLevelColor: Color? {
        guard let score = self.safetyData?.score else { return nil }
        switch score {
        case ..<1.7:
            return .green
        case 1.7 ..< 2.7:
            return .yellow
        case 2.7...:
            return .red
        default:
            return .gray
        }
    }

    var riskLevelScoreText: String? {
        guard let score = self.safetyData?.score else { return nil }
        return "\(score.formatted(.number.precision(.fractionLength(1)))) / 5"
    }
}
