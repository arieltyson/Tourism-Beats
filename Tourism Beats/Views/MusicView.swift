import MusicKit
import SwiftUI

struct MusicView: View {
    @StateObject private var viewModel: MusicViewModel
    let fallbackView: FallbackMusicView

    init(city: CityModel, fallbackView: FallbackMusicView) {
        _viewModel = StateObject(
            wrappedValue: MusicViewModel(city: city)
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

                if let msg = viewModel.playbackErrorMessage {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }

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

            SafetyView(
                viewModel: SafetyViewModel(city: viewModel.city)
            )
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            VisaView(
                viewModel: VisaViewModel(
                    passportCode: "TT",
                    destinationCode: viewModel.city.country.code
                )
            )
            .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .customNavigationTitle(
            "\(viewModel.city.name + " " + viewModel.city.country.flag)"
        )
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
