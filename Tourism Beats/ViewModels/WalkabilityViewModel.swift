import SwiftUI

// MARK: - WalkabilityViewModel

@MainActor
@Observable
final class WalkabilityViewModel {
    private(set) var walkability: WalkabilityModel?
    private(set) var isLoading = true
    private(set) var errorMessage: String?

    @ObservationIgnored let city: CityModel
    @ObservationIgnored private let service: WalkabilityProtocol

    init(
        city: CityModel,
        service: WalkabilityProtocol = WalkabilityService()
    ) {
        self.city = city
        self.service = service
    }

    /// Loads the scores once, when the view appears; creating the model
    /// does no work, so rebuilding the view never starts another request.
    func load() async {
        guard self.walkability == nil else { return }
        self.isLoading = true
        self.errorMessage = nil
        do {
            self.walkability = try await self.service.fetchWalkability(
                city: self.city.name,
                administrativeArea: self.city.administrativeArea,
                countryCode: self.city.country.code
            )
        } catch is CancellationError {
            // The page went away mid-load; the next appearance tries again.
        } catch {
            self.errorMessage = "Walkability data unavailable."
        }
        self.isLoading = false
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
