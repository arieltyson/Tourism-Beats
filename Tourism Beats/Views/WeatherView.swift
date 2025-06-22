import CoreLocation
import SwiftUI

struct WeatherView: View {
    @StateObject private var viewModel: WeatherViewModel

    init(city: CityModel) {
        _viewModel = StateObject(
            wrappedValue: WeatherViewModel(coordinate: city.coordinate)
        )
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .progressViewStyle(.circular)
            } else if let error = viewModel.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.yellow)
                Text(error)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 5)
            } else if let info = viewModel.weatherInfo {
                Text(info.condition)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 10)
                Image(systemName: info.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                    .padding(.vertical, 10)

                VStack(spacing: 4) {
                    Text(info.temperatureCelsius)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    Text(info.temperatureFahrenheit)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 10)

            } else {
                Text("---")
                    .foregroundColor(.white)
            }
        }
        .frame(width: 175, height: 250)
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
                .shadow(radius: 5)
        )
        .padding()
        .animation(.easeInOut, value: viewModel.isLoading)
        .animation(.easeInOut, value: viewModel.weatherInfo?.condition)
    }
}
