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
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)

            VStack {
                CachedCityImage(url: self.city.imageURL)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 15))
                    .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.5))
                    .shadow(radius: 5)
            )
            .padding(.horizontal)
            .frame(maxHeight: .infinity)
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
