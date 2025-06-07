import MusicKit
import SwiftUI

struct MusicRecommendationView: View {
    @ObservedObject var viewModel: MusicRecommendationViewModel
    var fallbackView: FallbackMusicCardView

    var body: some View {
        VStack {
            if viewModel.isMusicFeatureAvailable {
                // Placeholder for Music Info to stabilize initial layout
                VStack {
                    if let songImage = viewModel.songImage {
                        AsyncImage(url: songImage) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .cornerRadius(20)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 300, height: 300)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 300, height: 300)
                            .cornerRadius(20)
                            .overlay(ProgressView())
                    }
                    Text(
                        viewModel.songTitle.isEmpty
                            ? "Loading Song..." : viewModel.songTitle
                    )
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 5)
                    .frame(minHeight: 40)

                    Text(
                        viewModel.artistName.isEmpty
                            ? " " : viewModel.artistName
                    )
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.top, 2)
                    .frame(minHeight: 20)
                }
                .padding(.top, 50)

            } else {
                // Fallback UI if music access is denied
                fallbackView
            }

            Spacer()

            SafetyAdvisoryView(
                viewModel: SafetyAdvisoryViewModel(city: viewModel.city)
            )
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            VisaAdvisoryView(
                viewModel: VisaAdvisoryViewModel(
                    passportCode: "TT",  // Default to greatest country in the world
                    destinationCode: viewModel.city.country.code
                )
            )
            .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .customNavigationTitle("Apple Music Local 🌆")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.7),
                    Color.indigo.opacity(0.7),
                    Color.blue,
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            Task {
                await viewModel.requestAccessAndLoadTopSong()
            }
        }
    }
}
