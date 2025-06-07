import MusicKit
import SwiftUI

struct MusicRecommendationView: View {
    @StateObject private var viewModel: MusicRecommendationViewModel
    let fallbackView: FallbackMusicCardView

    init(city: CityModel, fallbackView: FallbackMusicCardView) {
        _viewModel = StateObject(
            wrappedValue: MusicRecommendationViewModel(city: city)
        )
        self.fallbackView = fallbackView
    }

    var body: some View {
        VStack {
            if viewModel.isMusicFeatureAvailable {
                // artwork + play/pause button
                Button {
                    Task { await viewModel.togglePlayback() }
                } label: {
                    ZStack {
                        AsyncImage(url: viewModel.songImage) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 300)
                                .cornerRadius(20)
                                .shadow(radius: 10)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 300, height: 300)
                                .cornerRadius(20)
                                .overlay(ProgressView())
                        }

                        // play/pause overlay
                        if !viewModel.songTitle.hasPrefix("Loading")
                            && viewModel.songTitle != "Music Access Required"
                        {
                            Image(
                                systemName: viewModel.isPlaying
                                    ? "pause.circle.fill"
                                    : "play.circle.fill"
                            )
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundStyle(
                                .white.opacity(0.9),
                                .black.opacity(0.3)
                            )
                            .shadow(radius: 4)
                            .transition(
                                .opacity.animation(.easeInOut(duration: 0.2))
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 50)

                // song title & artist
                Text(viewModel.songTitle)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(minHeight: 40)

                Text(viewModel.artistName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(minHeight: 20)

            } else {
                // permission denied
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
                    passportCode: "TT",
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
                colors: [
                    Color.blue.opacity(0.7),
                    Color.indigo.opacity(0.7),
                    Color.blue,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .task {
            await viewModel.requestAccessAndLoadTopSong()
        }
    }
}
