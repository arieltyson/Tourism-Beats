// ProviderLogo.swift
// Tourism Beats
//
// Music provider logos for Apple Music and Spotify.
// Falls back to SF Symbols when asset images are unavailable.

import SwiftUI

/// Identifies a music streaming provider and renders its logo.
enum ProviderLogo {
    case spotify
    case appleMusic

    /// The provider's logo as a small resizable image (for info labels).
    @ViewBuilder
    var view: some View {
        switch self {
        case .spotify:
            if let uiImage = UIImage(named: "spotify_music_logo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(ProviderLogo.spotifyGreen)
            }
        case .appleMusic:
            if let uiImage = UIImage(named: "apple_music_logo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "apple.logo")
                    .resizable()
                    .scaledToFit()
            }
        }
    }

    /// A larger action-sized icon for interactive buttons.
    @ViewBuilder
    var actionIcon: some View {
        switch self {
        case .spotify:
            if let uiImage = UIImage(named: "spotify_music_logo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(ProviderLogo.spotifyGreen)
            }
        case .appleMusic:
            if let uiImage = UIImage(named: "apple_music_logo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "apple.logo")
                    .font(.title2)
            }
        }
    }

    /// Spotify's brand green for fallback SF Symbol tinting.
    static let spotifyGreen = Color(red: 0.12, green: 0.84, blue: 0.38)
}
