// GlassMusicCard.swift
// Tourism Beats
//
// Apple Music provider card with artwork, song info, and inline
// playback controls rendered inside a translucent glass surface.

import SwiftUI

// MARK: - GlassMusicCard

/// A glass-styled card for Apple Music showing artwork, song metadata,
/// and playback controls.
///
/// Tapping anywhere on the card plays or pauses. Restart stays a separate
/// control so it can't be triggered by a tap meant for playback.
struct GlassMusicCard: View {
    let artworkURL: URL?
    let songTitle: String
    let artistName: String
    let isPlaying: Bool
    let onPlayPause: () -> Void
    let onRestart: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GlassCard(cornerRadius: 20, contentPadding: 0) {
            if self.dynamicTypeSize.prefersMusicCardVerticalLayout {
                VStack(alignment: .leading, spacing: 0) {
                    GlassMusicCardPlaybackSurface(
                        artworkURL: self.artworkURL,
                        songTitle: self.songTitle,
                        artistName: self.artistName,
                        isPlaying: self.isPlaying,
                        onPlayPause: self.onPlayPause
                    )

                    GlassMusicCardControls(
                        isPlaying: self.isPlaying,
                        onRestart: self.onRestart,
                        onPlayPause: self.onPlayPause
                    )
                    .padding([.horizontal, .bottom], SpacingTokens.xSmall)
                }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    GlassMusicCardPlaybackSurface(
                        artworkURL: self.artworkURL,
                        songTitle: self.songTitle,
                        artistName: self.artistName,
                        isPlaying: self.isPlaying,
                        onPlayPause: self.onPlayPause
                    )
                    .layoutPriority(1)

                    GlassMusicCardControls(
                        isPlaying: self.isPlaying,
                        onRestart: self.onRestart,
                        onPlayPause: self.onPlayPause
                    )
                    .fixedSize()
                    .padding([.top, .trailing], SpacingTokens.xxSmall)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Apple Music")
    }
}

// MARK: - GlassMusicCardPlaybackSurface

/// The artwork and song details, filling the card as one play/pause button.
private struct GlassMusicCardPlaybackSurface: View {
    let artworkURL: URL?
    let songTitle: String
    let artistName: String
    let isPlaying: Bool
    let onPlayPause: () -> Void

    var body: some View {
        Button(action: self.onPlayPause) {
            HStack(alignment: .top, spacing: SpacingTokens.small) {
                GlassMusicCardArtwork(url: self.artworkURL)

                GlassMusicCardInfo(
                    songTitle: self.songTitle,
                    artistName: self.artistName
                )
            }
            .padding(SpacingTokens.small)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(self.songTitle) by \(self.artistName)")
        .accessibilityValue(self.isPlaying ? "Playing" : "Paused")
        .accessibilityHint(self.isPlaying ? "Pauses playback" : "Plays the song in Apple Music")
        .accessibilityInputLabels([self.songTitle, "Apple Music"])
    }
}

// MARK: - GlassMusicCardArtwork

private struct GlassMusicCardArtwork: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url, transaction: .init(animation: .smooth)) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        GlassMusicCardArtworkPlaceholder()
                    default:
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.primary)
                            }
                    }
                }
            } else {
                GlassMusicCardArtworkPlaceholder()
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }
}

// MARK: - GlassMusicCardArtworkPlaceholder

private struct GlassMusicCardArtworkPlaceholder: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - GlassMusicCardInfo

private struct GlassMusicCardInfo: View {
    let songTitle: String
    let artistName: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            ProviderLogo.appleMusic.view
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)

            Text(self.songTitle)
                .font(TypographyTokens.cardLabel.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(self.artistName)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - GlassMusicCardControls

private struct GlassMusicCardControls: View {
    let isPlaying: Bool
    let onRestart: () -> Void
    let onPlayPause: () -> Void

    @ScaledMetric(relativeTo: .title3) private var minimumTapTarget = SpacingTokens.minimumTapTarget

    var body: some View {
        HStack(spacing: 0) {
            Button("Restart", systemImage: "backward.end.fill", action: self.onRestart)
                .font(.callout)
                .frame(minWidth: self.minimumTapTarget, minHeight: self.minimumTapTarget)
                .contentShape(.rect)
                .accessibilityHint("Restarts the current song")
                .accessibilityInputLabels(["Restart Song", "Restart"])

            Button(
                self.isPlaying ? "Pause" : "Play",
                systemImage: self.isPlaying ? "pause.fill" : "play.fill",
                action: self.onPlayPause
            )
            .font(.title3)
            .contentTransition(.symbolEffect(.replace))
            .frame(minWidth: self.minimumTapTarget, minHeight: self.minimumTapTarget)
            .contentShape(.rect)
            .accessibilityHint(self.isPlaying ? "Pauses playback" : "Plays the song")
            .accessibilityInputLabels(
                self.isPlaying ? ["Pause", "Pause Song"] : ["Play", "Play Song"]
            )
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.indigo, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: SpacingTokens.medium) {
            GlassMusicCard(
                artworkURL: nil,
                songTitle: "Bohemian Rhapsody",
                artistName: "Queen",
                isPlaying: false,
                onPlayPause: {},
                onRestart: {}
            )

            GlassMusicCard(
                artworkURL: nil,
                songTitle: "A Very Long Song Title That Might Truncate",
                artistName: "Artist With A Long Name",
                isPlaying: true,
                onPlayPause: {},
                onRestart: {}
            )
        }
        .padding()
    }
}
