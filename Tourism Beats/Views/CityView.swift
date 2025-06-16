import SwiftUI

struct CityView: View {
    let city: CityModel

    var body: some View {
        ZStack {
            GradientProvider.gradients.randomElement()?
                .ignoresSafeArea()

            VStack {
                Text("\(city.name), \(city.country.name)  \(city.country.flag)")
                    .font(.title2).bold().italic()
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .allowsTightening(true)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                VStack {
                    Image(city.imageName)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(15)
                        .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.5))
                        .shadow(radius: 5)
                )
                .padding()

                Spacer()

                HStack {
                    TimeView(city: city)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(0.85)
                    WeatherView(city: city)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(0.85)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 50)
        }
    }
}
