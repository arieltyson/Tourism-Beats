// FallbackMusicView.swift
// Tourism Beats
//
// Displayed when Apple Music access is unavailable.
// Prompts the user to enable access in Settings.

import SwiftUI

struct FallbackMusicView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: SpacingTokens.medium) {
            Image(systemName: "music.note.house")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.6))

            Text("Apple Music Unavailable")
                .font(TypographyTokens.sectionHeader)
                .foregroundStyle(.white)

            Text(
                "Enable Apple Music access to view top tracks for your selected city."
            )
            .font(TypographyTokens.artistName)
            .foregroundStyle(.white.opacity(0.8))
            .multilineTextAlignment(.center)

            Button("Open Settings", systemImage: "gear") {
                if let settingsURL = URL(
                    string: UIApplication.openSettingsURLString
                ) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.info)
            .padding(.top, SpacingTokens.xSmall)
        }
        .padding(SpacingTokens.large)
        .frame(maxWidth: .infinity)
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.colorScheme),
                    lineWidth: 0.5
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.colorScheme),
            radius: 12,
            y: 6
        )
        .padding(SpacingTokens.medium)
    }
}
