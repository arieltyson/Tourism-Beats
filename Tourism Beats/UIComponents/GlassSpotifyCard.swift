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

    var body: some View {
        GlassCard(cornerRadius: 20) {
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Spotify")
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
                                    .tint(.white)
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
                    .foregroundStyle(.white.opacity(0.5))
            }
    }
}

// MARK: - GlassSpotifyCardInfo

private struct GlassSpotifyCardInfo: View {
    let songTitle: String
    let artistName: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            ProviderLogo.spotify.view
                .frame(width: 16, height: 16)

            Text(self.songTitle)
                .font(TypographyTokens.cardLabel.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(self.artistName)
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
        }
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
                .tint(.white)
                .frame(width: 32, height: 32)
        } else {
            Button("Open in Spotify", systemImage: "arrow.up.right", action: self.onOpen)
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .accessibilityHint("Opens this song in Spotify")
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
