// GlassSpotifyCard.swift
// Tourism Beats
//
// Spotify provider card with artwork, song info, and external
// link button rendered inside a translucent glass surface.

import SwiftUI

// MARK: - GlassSpotifyCard

/// A glass-styled card for Spotify showing artwork, song metadata,
/// and a button to open the track in the Spotify app or web.
struct GlassSpotifyCard: View {
    let artworkURL: URL?
    let songTitle: String
    let artistName: String
    let isSearching: Bool
    let onOpen: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GlassCard(cornerRadius: 20) {
            if self.dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: SpacingTokens.small) {
                    HStack(spacing: SpacingTokens.small) {
                        GlassSpotifyCardArtwork(url: self.artworkURL)

                        GlassSpotifyCardInfo(
                            songTitle: self.songTitle,
                            artistName: self.artistName
                        )
                    }

                    GlassSpotifyCardAction(
                        isSearching: self.isSearching,
                        onOpen: self.onOpen
                    )
                }
            } else {
                HStack(spacing: SpacingTokens.small) {
                    GlassSpotifyCardArtwork(url: self.artworkURL)

                    GlassSpotifyCardInfo(
                        songTitle: self.songTitle,
                        artistName: self.artistName
                    )

                    Spacer(minLength: SpacingTokens.xxSmall)

                    GlassSpotifyCardAction(
                        isSearching: self.isSearching,
                        onOpen: self.onOpen
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Spotify. \(self.songTitle) by \(self.artistName)")
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
                        image
                            .resizable()
                            .scaledToFill()
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
                .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .fixedSize(horizontal: false, vertical: self.dynamicTypeSize.isAccessibilitySize)

            Text(self.artistName)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(self.dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                .fixedSize(horizontal: false, vertical: self.dynamicTypeSize.isAccessibilitySize)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - GlassSpotifyCardAction

private struct GlassSpotifyCardAction: View {
    let isSearching: Bool
    let onOpen: () -> Void

    var body: some View {
        if self.isSearching {
            ProgressView()
                .controlSize(.small)
                .tint(.primary)
                .frame(width: 32, height: 32)
        } else {
            Button(action: self.onOpen) {
                Label {
                    Text("Open in Spotify")
                } icon: {
                    ProviderLogo.spotify.actionIcon
                }
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens this song in Spotify")
            .accessibilityInputLabels(["Open in Spotify", "Open Spotify"])
        }
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
