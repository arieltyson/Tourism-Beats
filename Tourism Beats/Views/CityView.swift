import SwiftUI

// MARK: - CityView

struct CityView: View {
    let city: CityModel

    var body: some View {
        // Foreground content only (background provided by container)
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            CityHeaderView(city: self.city)

            Color.clear
                .aspectRatio(3 / 2, contentMode: .fit)
                .overlay {
                    CachedCityImage(url: self.city.imageURL)
                }
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TimeView(city: self.city)
                    WeatherView(city: self.city)
                }
                .fixedSize(horizontal: false, vertical: true)

                CityFunFactCard(city: self.city)
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - CityHeaderView

private struct CityHeaderView: View {
    let city: CityModel

    var body: some View {
        VStack {
            Text("\(self.city.name),")
            Text("\(self.city.country.name) \(self.city.country.flag)")
        }
        .font(.title2).bold().italic()
        .foregroundStyle(AppColors.onImagePrimary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.30), radius: 8, y: 3)
        .accessibilityAddTraits(.isHeader)
    }
}
