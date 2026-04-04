// MusicView.swift
// Tourism Beats
//
// Displays the #1 song for a city with Apple Music playback
// controls and Spotify deep-linking, styled with Liquid Glass.

import MusicKit
import SwiftUI

// MARK: - MusicView

struct MusicView: View {
    let city: CityModel
    @StateObject private var viewModel: MusicViewModel
    let fallbackView: FallbackMusicView

    init(city: CityModel, fallbackView: FallbackMusicView) {
        self.city = city
        _viewModel = StateObject(wrappedValue: MusicViewModel(city: city))
        self.fallbackView = fallbackView
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: SpacingTokens.medium) {
                Self.HeroCard(city: self.city)
                    .padding(.horizontal, SpacingTokens.medium)
                    .padding(.top, SpacingTokens.small)

                MusicArtworkCard(artworkURL: self.viewModel.songImage)
                    .frame(maxWidth: 320)
                    .padding(.horizontal, SpacingTokens.xLarge)

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
                        onRestart: {
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
        .task { await self.viewModel.requestAccessAndLoadTopSong() }
    }
}

// MARK: MusicView.HeroCard

extension MusicView {
    private struct HeroCard: View {
        let city: CityModel

        @Environment(\.colorScheme) private var scheme

        var body: some View {
            HStack(alignment: .center, spacing: SpacingTokens.small) {
                ZStack {
                    Circle()
                        .fill(AppColors.magenta.opacity(0.24))

                    Image(systemName: "music.note")
                        .font(.headline)
                        .foregroundStyle(AppColors.magenta)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                    Text("Top Songs")
                        .font(TypographyTokens.sectionHeader)
                        .bold()
                        .foregroundStyle(AppColors.label)

                    Text("\(self.city.name), \(self.city.country.name)")
                        .font(TypographyTokens.cardLabel)
                        .foregroundStyle(AppColors.secondaryLabel)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(SpacingTokens.medium)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                AppColors.glassBorder(for: self.scheme),
                                lineWidth: 1
                            )
                    }
                    .shadow(
                        color: AppColors.glassShadow(for: self.scheme),
                        radius: 16,
                        y: 10
                    )
            }
        }
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
                .foregroundStyle(AppColors.onImagePrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.30), radius: 10, y: 4)

            Text(self.artist)
                .font(TypographyTokens.artistName)
                .foregroundStyle(AppColors.onImageSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.24), radius: 8, y: 3)
        }
        .padding(.horizontal, SpacingTokens.medium)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - MusicFeedbackBanner

private struct MusicFeedbackBanner: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(TypographyTokens.footnote)
                .foregroundStyle(AppColors.onImageSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingTokens.medium)
                .transition(.opacity)
                .shadow(color: .black.opacity(0.20), radius: 6, y: 2)
        }
    }
}
