import MusicKit
import SwiftUI

struct MusicView: View {
    @StateObject private var viewModel: MusicViewModel
    let fallbackView: FallbackMusicView

    init(city: CityModel, fallbackView: FallbackMusicView) {
        _viewModel = StateObject(wrappedValue: MusicViewModel(city: city))
        self.fallbackView = fallbackView
    }

    var body: some View {
        GeometryReader { geo in
            // Foreground content only; background is in CityContainerView
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    let maxArt = min(geo.size.width * 0.7, 360)
                    artworkView(maxSide: maxArt)
                        .padding(.top, 24)

                    Text(viewModel.songTitle)
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal)

                    Text(viewModel.artistName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .padding(.horizontal)

                    VStack(spacing: 14) {
                        NeumorphicPill(
                            logo: .appleMusic,
                            title: "Apple Music",
                            rightKind: viewModel.isPlaying ? .pause : .play,
                            dimmed: false
                        ) {
                            Task { await viewModel.handleAppleMusicAction() }
                        }

                        NeumorphicPill(
                            logo: .spotify,
                            title: "Spotify",
                            rightKind: viewModel.isSpotifySearching
                                ? .loading : .link,
                            dimmed: false
                        ) {
                            Task { await viewModel.handleSpotifyAction() }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer(minLength: 0)
                }
                // Keep content above home indicator/tab icons
                .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.requestAccessAndLoadTopSong() }  // metadata only
    }

    // MARK: - Subviews
    @ViewBuilder
    private func artworkView(maxSide: CGFloat) -> some View {
        if let url = viewModel.songImage {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: maxSide, height: maxSide)
                        .aspectRatio(1, contentMode: .fit)
                case let .success(image):
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: maxSide, height: maxSide)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                case .failure:
                    Image("placeholder_artwork")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: maxSide, height: maxSide)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                @unknown default:
                    Image("placeholder_artwork")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: maxSide, height: maxSide)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }
            }
        } else {
            Image("placeholder_artwork")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: maxSide, height: maxSide)
                .cornerRadius(20)
                .shadow(radius: 10)
        }
    }
}
