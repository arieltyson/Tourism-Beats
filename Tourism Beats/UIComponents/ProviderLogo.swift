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

    /// The provider's logo as a resizable image view.
    @ViewBuilder
    var view: some View {
        switch self {
        case .spotify:
            if let uiImage = UIImage(named: "spotify_logo") {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "link")
                    .resizable()
                    .scaledToFit()
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
}
