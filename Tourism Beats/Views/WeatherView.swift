import CoreLocation
import SwiftUI
@preconcurrency import WeatherKit

struct WeatherView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    @StateObject private var viewModel: WeatherViewModel

    @State private var attribution: WeatherAttribution?

    private var prefersMetric: Bool {
        self.locale.prefersCelsius
    }

    init(city: CityModel) {
        _viewModel = StateObject(
            wrappedValue: WeatherViewModel(coordinate: city.coordinate)
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            if self.viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .progressViewStyle(.circular)

            } else if let error = self.viewModel.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.yellow)
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)

            } else if let info = self.viewModel.weatherInfo {
                Text(info.condition)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                    .minimumScaleFactor(self.dynamicTypeSize.isAccessibilitySize ? 1 : 0.5)
                    .multilineTextAlignment(.center)
                    .fixedSize(
                        horizontal: false,
                        vertical: self.dynamicTypeSize.isAccessibilitySize
                    )

                Image(systemName: info.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.white)

                VStack(spacing: 2) {
                    Text(info.temperatureCelsius)
                        .font(.subheadline)
                        .fontWeight(self.prefersMetric ? .semibold : .regular)
                        .opacity(self.prefersMetric ? 1.0 : 0.6)

                    Text(info.temperatureFahrenheit)
                        .font(.caption)
                        .fontWeight(self.prefersMetric ? .regular : .semibold)
                        .opacity(self.prefersMetric ? 0.6 : 1.0)
                }
                .foregroundStyle(.white)

                // MARK: - WeatherKit Attribution

                if let attribution {
                    HStack(spacing: 4) {
                        AsyncImage(url: self.logoURL(for: self.colorScheme)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 8)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(height: 8)
                        }

                        Link("Legal", destination: attribution.legalPageURL)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.top, 2)
                }
            } else {
                Text("---")
                    .foregroundStyle(.white)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 16, style: .continuous)
        )
        .task {
            await self.fetchAttribution()
        }
        .motionSensitiveAnimation(
            .easeInOut,
            reduced: .none,
            value: self.viewModel.isLoading
        )
        .motionSensitiveAnimation(
            .easeInOut,
            reduced: .none,
            value: self.viewModel.weatherInfo?.condition
        )
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
        guard let attribution else { return nil }

        return colorScheme == .dark
            ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL
    }
}
