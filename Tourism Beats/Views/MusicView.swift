import MusicKit
import SwiftUI

struct MusicView: View {
    @StateObject private var viewModel: MusicViewModel
    let fallbackView: FallbackMusicView

    @State private var backgroundGradient: MeshGradient

    init(city: CityModel, fallbackView: FallbackMusicView) {
        _viewModel = StateObject(wrappedValue: MusicViewModel(city: city))
        self.fallbackView = fallbackView

        _backgroundGradient = State(
            initialValue: GradientProvider.gradients.randomElement()!
        )
    }

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            // ─── Content ────────────────────────────────────────────────
            VStack {
                if viewModel.isMusicFeatureAvailable {
                    // Artwork (conditionally tappable)
                    Group {
                        if viewModel.songID != nil {
                            Button {
                                Task { await viewModel.togglePlayback() }
                            } label: {
                                artworkView
                                    .overlay(playPauseOverlay)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 20)
                        } else {
                            artworkView
                                .padding(.top, 20)
                        }
                    }

                    // Playback‐specific error (region lock, etc)
                    if let msg = viewModel.playbackErrorMessage {
                        Text(msg)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }

                    // ─── Song title ─────────────────────────────────────
                    Text(viewModel.songTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal)
                        .frame(minHeight: 30)

                    // ─── Artist name ────────────────────────────────────
                    Text(viewModel.artistName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .padding(.horizontal)

                } else {
                    // No Music permission
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

                Spacer(minLength: 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.requestAccessAndLoadTopSong() }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 50)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var artworkView: some View {
        if let url = viewModel.songImage {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: 300, maxHeight: 300)
                        .aspectRatio(1, contentMode: .fit)

                case let .success(image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(20)
                        .shadow(radius: 10)

                case .failure:
                    Image("placeholder_artwork")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(20)
                        .shadow(radius: 10)

                @unknown default:
                    Image("placeholder_artwork")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 300)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }
            }
        } else {
            Image("placeholder_artwork")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 300, maxHeight: 300)
                .cornerRadius(20)
                .shadow(radius: 10)
        }
    }

    @ViewBuilder
    private var playPauseOverlay: some View {
        if viewModel.isPlaying || viewModel.songID != nil {
            Image(
                systemName: viewModel.isPlaying
                    ? "pause.circle.fill"
                    : "play.circle.fill"
            )
            .resizable()
            .frame(width: 60, height: 60)
            .foregroundStyle(
                .white.opacity(0.9),
                .black.opacity(0.3)
            )
            .shadow(radius: 4)
            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
        }
    }
}
