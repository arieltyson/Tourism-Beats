import SwiftUI

struct CityView: View {
    let city: CityModel

    var body: some View {
        ZStack {
            if #available(iOS 18.0, *) {
                GradientProvider.gradients.randomElement()?
                    .ignoresSafeArea()
            } else {
                UIKitGradientBackgroundWrapper()
                    .ignoresSafeArea()
            }

            VStack(spacing: 30) {
                Text("\(city.name), \(city.country.name)  \(city.country.flag)")
                    .font(.largeTitle).bold().italic()
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .allowsTightening(true)
                    .padding(.horizontal, 20)
                    .padding(.top, 50)

                VStack(alignment: .leading, spacing: 20) {
                    Image(city.imageName)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(15)
                        .padding()
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(radius: 15)
                .padding(.horizontal)

                Spacer()

                HStack {
                    TimeView(city: city)
                        .frame(maxWidth: .infinity)
                    WeatherView(city: city)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}
