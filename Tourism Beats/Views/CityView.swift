import SwiftUI

struct CityView: View {
    let city: CityModel

    var body: some View {
        // Foreground content only (background provided by container)
        VStack(spacing: 0) {
            VStack {
                Text("\(self.city.name),")
                Text("\(self.city.country.name) \(self.city.country.flag)")
            }
            .font(.title2).bold().italic()
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            CachedCityImage(url: self.city.imageURL)
                .aspectRatio(3 / 2, contentMode: .fit)
                .frame(maxWidth: 460)
                .frame(maxWidth: .infinity)
                .clipShape(.rect(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.24), radius: 18, y: 10)
                .padding(.horizontal, 20)
                .layoutPriority(1)

            Spacer(minLength: 20)

            HStack {
                TimeView(city: self.city).frame(maxWidth: .infinity)
                WeatherView(city: self.city).frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}
