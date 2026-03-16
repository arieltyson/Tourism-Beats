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
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                MusicArtworkCard(artworkURL: self.viewModel.songImage)
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)

                Text(self.viewModel.songTitle)
                    .font(.title3).bold()
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal)

                Text(self.viewModel.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal)

                VStack(spacing: 14) {
                    NeumorphicPill(
                        logo: .appleMusic,
                        title: "Apple Music",
                        rightKind: self.viewModel.isPlaying
                            ? .pause : .play,
                        dimmed: false
                    ) {
                        Task {
                            await self.viewModel.handleAppleMusicAction()
                        }
                    }

                    NeumorphicPill(
                        logo: .spotify,
                        title: "Spotify",
                        rightKind: self.viewModel.isSpotifySearching
                            ? .loading : .link,
                        dimmed: false
                    ) {
                        Task { await self.viewModel.handleSpotifyAction() }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, 20)
        .navigationBarBackButtonHidden(true)
        .task { await self.viewModel.requestAccessAndLoadTopSong() } // metadata only
    }
}
