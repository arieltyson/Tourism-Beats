// MusicView.swift
// Tourism Beats
//
// Displays the #1 song for a city with Apple Music playback
// controls and Spotify deep-linking, styled with Liquid Glass.

import MusicKit
import SwiftUI

// MARK: - MusicView

struct MusicView: View {
    @StateObject private var viewModel: MusicViewModel
    let fallbackView: FallbackMusicView

    init(city: CityModel, fallbackView: FallbackMusicView) {
        _viewModel = StateObject(wrappedValue: MusicViewModel(city: city))
        self.fallbackView = fallbackView
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: SpacingTokens.medium) {
                MusicArtworkCard(artworkURL: self.viewModel.songImage)
                    .frame(maxWidth: 320)
                    .padding(.horizontal, SpacingTokens.xLarge)
                    .padding(.top, SpacingTokens.large)

                MusicSongHeader(
                    title: self.viewModel.songTitle,
                    artist: self.viewModel.artistName
                )

                VStack(spacing: SpacingTokens.small) {
                    GlassMusicCard(
                        artworkURL: self.viewModel.songImage,
                        songTitle: self.viewModel.songTitle,
                        artistName: self.viewModel.artistName,
                        isPlaying: self.viewModel.isPlaying,
                        onPlayPause: {
                            Task { await self.viewModel.handleAppleMusicAction() }
                        },
                        onSkipForward: {
                            Task { await self.viewModel.skipForward() }
                        },
                        onSkipBackward: {
                            self.viewModel.skipBackward()
                        }
                    )

                    GlassSpotifyCard(
                        artworkURL: self.viewModel.songImage,
                        songTitle: self.viewModel.songTitle,
                        artistName: self.viewModel.artistName,
                        isSearching: self.viewModel.isSpotifySearching,
                        onOpen: {
                            Task { await self.viewModel.handleSpotifyAction() }
                        }
                    )
                }
                .padding(.horizontal, SpacingTokens.medium)

                MusicFeedbackBanner(message: self.viewModel.userFeedbackMessage)
            }
            .padding(.bottom, SpacingTokens.medium)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .safeAreaPadding(.bottom, SpacingTokens.medium)
        .navigationBarBackButtonHidden(true)
        .task { await self.viewModel.requestAccessAndLoadTopSong() }
    }
}

// MARK: - MusicSongHeader

private struct MusicSongHeader: View {
    let title: String
    let artist: String

    var body: some View {
        VStack(spacing: SpacingTokens.xxSmall) {
            Text(self.title)
                .font(TypographyTokens.songTitle).bold()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(self.artist)
                .font(TypographyTokens.artistName)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, SpacingTokens.medium)
    }
}

// MARK: - MusicFeedbackBanner

private struct MusicFeedbackBanner: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingTokens.medium)
                .transition(.opacity)
        }
    }
}
