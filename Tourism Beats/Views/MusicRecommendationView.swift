import MusicKit
import SwiftUI

struct MusicRecommendationView: View {
    @ObservedObject var viewModel: MusicRecommendationViewModel
    var fallbackView: FallbackMusicCardView

    var body: some View {
        VStack {
            if viewModel.isMusicFeatureAvailable {
                VStack {
                    Button(action: {
                        Task {
                            await viewModel.togglePlayback()
                        }
                    }) {
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

                            // Play/Pause icon overlay
                            // Shows only when song metadata has been loaded
                            if !viewModel.songTitle.isEmpty
                                && !viewModel.songTitle.starts(with: "Loading")
                                && viewModel.songTitle
                                    != "Music Access Required"
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
                                )  // iOS 15+ style
                                .shadow(radius: 4)
                                .transition(
                                    .opacity.animation(
                                        .easeInOut(duration: 0.2)
                                    )
                                )
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Text(viewModel.songTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 5)
                        .frame(minHeight: 40)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text(viewModel.artistName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 2)
                        .frame(minHeight: 20)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 50)

            } else {
                // Fallback UI if music access is denied or unavailable
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
