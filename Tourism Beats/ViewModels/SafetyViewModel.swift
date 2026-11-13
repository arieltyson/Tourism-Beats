import Observation
import SwiftUI

@MainActor
@Observable
final class SafetyViewModel {
    private(set) var safetyData: SafetyModel?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// Whether the index leaves this country unranked, as it does many small
    /// island states. That's not a failure, so it isn't shown as one.
    private(set) var isUnranked = false

    @ObservationIgnored private let city: CityModel
    @ObservationIgnored private let safetyService: SafetyProtocol

    init(
        city: CityModel,
        safetyService: SafetyProtocol = SafetyService()
    ) {
        self.city = city
        self.safetyService = safetyService
    }

    /// Loads the index the first time the view appears. Coming back to the
    /// page, or showing it in another layout, reuses what's loaded instead of
    /// flashing a spinner while fetching it again.
    func loadIfNeeded() async {
        guard self.safetyData == nil, !self.isUnranked, !self.isLoading else { return }
        await self.fetchSafetyData()
    }

    func fetchSafetyData() async {
        self.isLoading = true
        self.errorMessage = nil

        do {
            self.safetyData = try await self.safetyService.fetchSafetyData(
                for: self.city.country.code
            )
        } catch SafetyError.countryNotFound {
            self.isUnranked = true
        } catch {
            self.errorMessage = "Could not load Global Peace Index data."
        }

        self.isLoading = false
    }

    /// The country whose index stands in for a territory's, such as France
    /// for Martinique; `nil` where the index is the country's own.
    var governingCountryName: String? {
        guard let safetyData,
              safetyData.countryCode.uppercased() != self.city.country.code.uppercased()
        else { return nil }
        return safetyData.countryName
    }

    /// Where the score comes from, naming the governing country for a territory.
    var sourceLabel: String {
        guard let governingCountryName else { return String(localized: "Global Peace Index 2026") }
        return String(localized: "Global Peace Index 2026 · \(governingCountryName)")
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
