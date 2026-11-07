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
    @State private var viewModel: MusicViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let fallbackView: FallbackMusicView

    init(city: CityModel, fallbackView: FallbackMusicView) {
        self.city = city
        _viewModel = State(initialValue: MusicViewModel(city: city))
        self.fallbackView = fallbackView
    }

    var body: some View {
        // This page sits inside the vertical city pager. A page that scrolls
        // itself catches the swipe meant for the next page, so this page
        // fits the screen whenever it can, and the artwork gives up height
        // first. Only text too large to fit even then falls back to scrolling.
        ViewThatFits(in: .vertical) {
            Self.Content(city: self.city, viewModel: self.viewModel, fitsPage: true)

            ScrollView(.vertical) {
                Self.Content(city: self.city, viewModel: self.viewModel, fitsPage: false)
            }
            .cityPageScrolling()
        }
        .animation(self.reduceMotion ? nil : AnimationTokens.standard, value: self.viewModel.availability)
        .task { await self.viewModel.requestAccessAndLoadTopSong() }
    }
}

// MARK: MusicView.Content

extension MusicView {
    /// The page's content, laid out to fit the page or to scroll.
    private struct Content: View {
        let city: CityModel
        let viewModel: MusicViewModel

        /// Whether the artwork shrinks so the page fits without scrolling.
        let fitsPage: Bool

        var body: some View {
            VStack(spacing: SpacingTokens.medium) {
                MusicView.HeroCard(city: self.city)
                    .padding(.horizontal, SpacingTokens.medium)
                    .padding(.top, SpacingTokens.small)

                MusicPageArtwork(artworkURL: self.viewModel.songImage, fitsPage: self.fitsPage)

                MusicSongHeader(
                    title: self.viewModel.songTitle,
                    artist: self.viewModel.artistName
                )

                if self.viewModel.availability == .failed {
                    Button("Try Again", systemImage: "arrow.clockwise") {
                        Task { await self.viewModel.retry() }
                    }
                    .buttonStyle(.glass)
                    .transition(.opacity)
                }

                if self.viewModel.availability.showsPlayers {
                    MusicPlayerCards(viewModel: self.viewModel)
                }

                MusicFeedbackBanner(message: self.viewModel.userFeedbackMessage)
            }
            .padding(.bottom, SpacingTokens.medium)
            .frame(maxWidth: .infinity)
        }
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

                    Text(self.city.displayName)
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

// MARK: - MusicPageArtwork

/// The album artwork, which absorbs the page's spare height.
///
/// When the page fits, the artwork asks for only its minimum size, so the page
/// counts as fitting with the artwork at its smallest. It then grows into the
/// space left by the text and cards, up to its largest size, centered in that
/// space. When the page scrolls, the artwork keeps its full width instead.
private struct MusicPageArtwork: View {
    let artworkURL: URL?
    let fitsPage: Bool

    var body: some View {
        MusicArtworkCard(artworkURL: self.artworkURL)
            .frame(maxWidth: MusicPageTokens.artworkMaximumSide)
            .frame(
                minHeight: self.fitsPage ? MusicPageTokens.artworkMinimumSide : nil,
                idealHeight: self.fitsPage ? MusicPageTokens.artworkMinimumSide : nil,
                maxHeight: self.fitsPage ? .infinity : nil
            )
            .padding(.horizontal, SpacingTokens.xLarge)
    }
}

// MARK: - MusicPlayerCards

/// The Apple Music and Spotify cards, shown as placeholders while loading.
private struct MusicPlayerCards: View {
    let viewModel: MusicViewModel

    var body: some View {
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
        // The Apple Music card's tap area stretches to fill its card, so the
        // cards keep their natural height and the artwork takes the spare room.
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, SpacingTokens.medium)
        // Loading is said once, by the header above.
        .redacted(reason: self.viewModel.availability.showsSongDetails ? [] : .placeholder)
        .disabled(!self.viewModel.availability.showsSongDetails)
        .accessibilityHidden(!self.viewModel.availability.showsSongDetails)
        .transition(.opacity)
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
