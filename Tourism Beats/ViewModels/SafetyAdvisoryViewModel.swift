import SwiftUICore

@MainActor
class SafetyAdvisoryViewModel: ObservableObject {
    @Published var safetyData: SafetyModel?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let city: CityModel
    private let safetyService: SafetyServiceProtocol

    init(
        city: CityModel,
        safetyService: SafetyServiceProtocol = SafetyService()
    ) {
        self.city = city
        self.safetyService = safetyService
        fetchSafetyData()
    }

    func fetchSafetyData() {
        isLoading = true
        errorMessage = nil

        let countryCode = city.country.code
        print("Fetching safety data for country code: \(countryCode)")

        Task {
            do {
                self.safetyData = try await safetyService.fetchSafetyData(
                    for: countryCode
                )
            } catch {
                self.errorMessage = "Could not load Global Peace Index data."
            }
            self.isLoading = false
        }
    }

    // Map 1.0–5.0 → LOW/MED/HIGH
    var riskLevelText: String? {
        guard let score = safetyData?.score else { return nil }
        switch score {
        case ..<1.7:
            return "LOW"
        case 1.7..<2.7:
            return "MED"
        case 2.7...:
            return "HIGH"
        default:
            return "Unknown"
        }
    }

    var riskLevelColor: Color? {
        guard let score = safetyData?.score else { return nil }
        switch score {
        case ..<1.7:
            return .green
        case 1.7..<2.7:
            return .yellow
        case 2.7...:
            return .red
        default:
            return .gray
        }
    }

    var riskLevelScoreText: String? {
        guard let score = safetyData?.score else { return nil }
        return String(format: "%.1f / 5", score)
    }
}
