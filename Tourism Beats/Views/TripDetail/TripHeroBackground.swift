import SwiftUI

// MARK: - TripHeroBackground

struct TripHeroBackground: View {
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
                            AppColors.info.opacity(0.94),
                            AppColors.violet.opacity(0.88),
                            AppColors.magenta.opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 88))
                            .foregroundStyle(AppColors.onImageTertiary.opacity(0.30))
                    }
                }
            }
    }
}
