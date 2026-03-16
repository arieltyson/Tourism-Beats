// GlassCard.swift
// Tourism Beats
//
// A translucent card surface using system materials.
// Adapts to Reduce Transparency for accessibility compliance.

import SwiftUI

/// A translucent card surface inspired by iOS 26's Liquid Glass aesthetic.
///
/// Uses `.ultraThinMaterial` for the glass effect, with an automatic
/// fallback to a solid surface when Reduce Transparency is enabled.
/// Applies the app's consistent `glassBorder` and `glassShadow` tokens.
///
/// ```swift
/// GlassCard {
///     Text("Now Playing")
/// }
/// ```
struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let cornerRadius: CGFloat
    @ViewBuilder let content: Content

    init(
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        self.content
            .padding(SpacingTokens.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                self.cardBackground,
                in: .rect(cornerRadius: self.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
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
    }

    private var cardBackground: some ShapeStyle {
        self.reduceTransparency
            ? AnyShapeStyle(AppColors.surfaceSecondary)
            : AnyShapeStyle(.ultraThinMaterial)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: SpacingTokens.medium) {
            GlassCard {
                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    Text("Now Playing")
                        .font(TypographyTokens.sectionHeader)
                    Text("Song Title — Artist")
                        .font(TypographyTokens.caption)
                }
            }

            GlassCard(cornerRadius: 16) {
                Text("Compact card")
                    .font(TypographyTokens.body)
            }
        }
        .foregroundStyle(.white)
        .padding()
    }
}
