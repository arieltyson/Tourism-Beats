import SwiftUI

struct CityView: View {
    let city: CityModel

    var body: some View {
        ZStack {
            GradientProvider.gradients.randomElement()?
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack {
                    Text("\(city.name),")
                    Text("\(city.country.name) \(city.country.flag)")
                }
                .font(.title2).bold().italic()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)

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
                .padding(.horizontal)
                .frame(maxHeight: .infinity)
                .layoutPriority(1)

                Spacer(minLength: 20)

                HStack {
                    TimeView(city: city)
                        .frame(maxWidth: .infinity)
                    WeatherView(city: city)
                        .frame(maxWidth: .infinity)
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
