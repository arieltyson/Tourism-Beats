// GlassSpotifyCard.swift
// Tourism Beats
//
// Spotify provider card with artwork, song info, and external
// link button rendered inside a translucent glass surface.

import SwiftUI

// MARK: - GlassSpotifyCard

/// A glass-styled card for Spotify showing artwork and song metadata.
///
/// The whole card is one button that opens the track in the Spotify app or
/// on the web; the Spotify mark on the trailing edge signals where it goes.
struct GlassSpotifyCard: View {
    let artworkURL: URL?
    let songTitle: String
    let artistName: String
    let isSearching: Bool
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: self.onOpen) {
            GlassCard(cornerRadius: 20) {
                if self.dynamicTypeSize.prefersMusicCardVerticalLayout {
                    VStack(alignment: .leading, spacing: SpacingTokens.small) {
                        HStack(spacing: SpacingTokens.small) {
                            GlassSpotifyCardArtwork(url: self.artworkURL)

                            GlassSpotifyCardInfo(
                                songTitle: self.songTitle,
                                artistName: self.artistName
                            )
                        }

                        GlassSpotifyCardAccessory(isSearching: self.isSearching)
                    }
                } else {
                    HStack(alignment: .top, spacing: SpacingTokens.small) {
                        GlassSpotifyCardArtwork(url: self.artworkURL)

                        GlassSpotifyCardInfo(
                            songTitle: self.songTitle,
                            artistName: self.artistName
                        )
                        .layoutPriority(1)

                        Spacer(minLength: SpacingTokens.xxSmall)

                        GlassSpotifyCardAccessory(isSearching: self.isSearching)
                            .fixedSize()
                    }
                }
            }
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.cardPress)
        .disabled(self.isSearching)
        .accessibilityLabel("Open \(self.songTitle) by \(self.artistName) in Spotify")
        .accessibilityValue(self.isSearching ? "Searching Spotify" : "")
        .accessibilityHint("Opens Spotify")
        .accessibilityInputLabels(["Open in Spotify", "Spotify", "Open Spotify"])
    }
}

// MARK: - GlassSpotifyCardArtwork

private struct GlassSpotifyCardArtwork: View {
    let url: URL?

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url, transaction: .init(animation: .smooth)) { phase in
                    switch phase {
                    case let .success(image):
                        FilledImage(image: image)
                    case .failure:
                        GlassSpotifyCardArtworkPlaceholder()
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
                GlassSpotifyCardArtworkPlaceholder()
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(.rect(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }
}

// MARK: - GlassSpotifyCardArtworkPlaceholder

private struct GlassSpotifyCardArtworkPlaceholder: View {
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

// MARK: - GlassSpotifyCardInfo

private struct GlassSpotifyCardInfo: View {
    let songTitle: String
    let artistName: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            ProviderLogo.spotify.view
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

// MARK: - GlassSpotifyCardAccessory

/// The Spotify mark, or a spinner while the track is being looked up.
private struct GlassSpotifyCardAccessory: View {
    let isSearching: Bool

    var body: some View {
        Group {
            if self.isSearching {
                ProgressView()
                    .controlSize(.small)
                    .tint(.primary)
            } else {
                ProviderLogo.spotify.actionIcon
            }
        }
        .frame(minWidth: 32, minHeight: 32)
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        LinearGradient(
            colors: [.green.opacity(0.8), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: SpacingTokens.medium) {
            GlassSpotifyCard(
                artworkURL: nil,
                songTitle: "Bohemian Rhapsody",
                artistName: "Queen",
                isSearching: false,
                onOpen: {}
            )

            GlassSpotifyCard(
                artworkURL: nil,
                songTitle: "Searching...",
                artistName: "—",
                isSearching: true,
                onOpen: {}
            )
        }
        .padding()
    }
}
