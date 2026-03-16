import SwiftUI

// MARK: - WalkabilityViewModel

@MainActor
class WalkabilityViewModel: ObservableObject {
    @Published var walkability: WalkabilityModel?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let city: CityModel
    private let service: WalkabilityProtocol

    init(
        city: CityModel,
        service: WalkabilityProtocol = WalkabilityService()
    ) {
        self.city = city
        self.service = service
        self.fetchWalkability()
    }

    func fetchWalkability() {
        self.isLoading = true
        self.errorMessage = nil

        Task { @MainActor in
            do {
                self.walkability = try await self.service.fetchWalkability(
                    city: self.city.name,
                    countryCode: self.city.country.code
                )
            } catch {
                self.errorMessage = "Walkability data unavailable."
            }
            self.isLoading = false
        }
    }

    // MARK: - Score Colors

    func walkScoreColor(_ score: Int) -> Color {
        switch score {
        case 90...:
            .green
        case 70 ..< 90:
            AppColors.safe
        case 50 ..< 70:
            .yellow
        case 25 ..< 50:
            .orange
        default:
            .red
        }
    }

    func transitScoreColor(_ score: Int) -> Color {
        switch score {
        case 90...:
            .green
        case 70 ..< 90:
            AppColors.safe
        case 50 ..< 70:
            .yellow
        case 25 ..< 50:
            .orange
        default:
            .red
        }
    }
}
