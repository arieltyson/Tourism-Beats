import CoreLocation
import SwiftUI
@preconcurrency import WeatherKit

struct WeatherView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.locale) private var locale
    @StateObject private var viewModel: WeatherViewModel

    @State private var attribution: WeatherAttribution?

    private var prefersMetric: Bool {
        locale.prefersCelsius
    }

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
                        .fontWeight(prefersMetric ? .semibold : .regular)
                        .opacity(prefersMetric ? 1.0 : 0.6)

                    Text(info.temperatureFahrenheit)
                        .font(.body)
                        .fontWeight(prefersMetric ? .regular : .semibold)
                        .opacity(prefersMetric ? 0.6 : 1.0)
                }
                .foregroundColor(.white)

                Spacer()

                // MARK: - WeatherKit Attribution
                if let attribution = attribution {
                    HStack(spacing: 8) {
                        AsyncImage(url: logoURL(for: colorScheme)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 10)
                                .font(.caption)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(height: 10)
                                .font(.caption)
                        }

                        Link("Legal", destination: attribution.legalPageURL)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 12)
                }
            } else {
                Text("---")
                    .foregroundColor(.white)
            }
        }
        .frame(minWidth: 140, minHeight: 200)
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
                .shadow(radius: 5)
        )
        .padding()
        .task {
            await fetchAttribution()
        }
        .animation(.easeInOut, value: viewModel.isLoading)
        .animation(.easeInOut, value: viewModel.weatherInfo?.condition)
    }

    // MARK: - Helper Functions
    private func fetchAttribution() async {
        do {
            self.attribution = try await WeatherService.shared.attribution
        } catch {
            print(
                "Failed to fetch WeatherKit attribution: \(error.localizedDescription)"
            )
        }
    }

    private func logoURL(for colorScheme: ColorScheme) -> URL? {
        guard let attribution = attribution else { return nil }

        return colorScheme == .dark
            ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }
}
