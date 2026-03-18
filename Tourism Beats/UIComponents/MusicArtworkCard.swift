// MusicArtworkCard.swift
// Tourism Beats
//
// Displays album art inside a stable square card with glass styling
// so artwork never stretches or overflows its intended visual frame.

import SwiftUI

// MARK: - MusicArtworkCard

/// Displays album artwork in a 1:1 aspect ratio glass-styled card.
struct MusicArtworkCard: View {
    let artworkURL: URL?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let artworkURL {
                    AsyncImage(url: artworkURL, transaction: .init(animation: .smooth)) { phase in
                        switch phase {
                        case .empty:
                            MusicArtworkLoadingView()
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            MusicArtworkPlaceholderView()
                        @unknown default:
                            MusicArtworkPlaceholderView()
                        }
                    }
                } else {
                    MusicArtworkPlaceholderView()
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        AppColors.glassBorder(for: self.colorScheme),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: AppColors.glassShadow(for: self.colorScheme),
                radius: 18,
                y: 10
            )
            .contentShape(.rect(cornerRadius: 28, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - MusicArtworkLoadingView

private struct MusicArtworkLoadingView: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                ProgressView()
                    .tint(.white)
            }
    }
}

// MARK: - MusicArtworkPlaceholderView

private struct MusicArtworkPlaceholderView: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay {
                Image(systemName: "music.note")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.4))
            }
    }
}
