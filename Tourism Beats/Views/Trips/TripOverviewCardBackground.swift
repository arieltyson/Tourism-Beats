import SwiftUI

// MARK: - TripOverviewCardBackground

struct TripOverviewCardBackground: View {
    let cityModel: CityModel?

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                if let cityModel {
                    CachedCityImage(url: cityModel.imageURL, fallbackCoordinate: cityModel.coordinate)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [
                            AppColors.info.opacity(0.92),
                            AppColors.violet.opacity(0.86),
                            AppColors.coral.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(.white.opacity(0.22))
                    }
                }
            }
    }
}
