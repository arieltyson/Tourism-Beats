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
                    PipelineImage(url: artworkURL) { phase in
                        switch phase {
                        case .empty:
                            MusicArtworkLoadingView()
                        case let .success(image):
                            FilledImage(image: image)
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
            .clipShape(.rect(cornerRadius: 28, style: .continuous))
            // The glass casts the shadow, not the artwork, so drawing it
            // needs no offscreen pass.
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: AppColors.glassShadow(for: self.colorScheme),
                        radius: 18,
                        y: 10
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        AppColors.glassBorder(for: self.colorScheme),
                        lineWidth: 1
                    )
            }
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
                DelayedProgressView()
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
