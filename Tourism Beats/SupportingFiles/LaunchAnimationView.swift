import SwiftUI

/// A brief branded moment shown while the app initializes.
///
/// Displays the Tourism Beats globe mark and app name with a subtle
/// ring animation, then dissolves to reveal the content underneath.
/// The sequence completes in under one second — long enough to feel
/// intentional, short enough to respect the user's time.
struct LaunchAnimationView: View {
    @ScaledMetric(relativeTo: .largeTitle) private var brandMarkSize: CGFloat = 96
    @ScaledMetric(relativeTo: .body) private var ringLineWidth: CGFloat = 5

    @State private var ringScale: CGFloat = 0.7
    @State private var ringOpacity: Double = 0
    @State private var iconOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Called when the animation completes and the view is ready to dismiss.
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            // Gradient background aligned with the app's night-mode shell.
            AppGradients.launch
                .ignoresSafeArea()

            VStack(spacing: SpacingTokens.large) {
                ZStack {
                    // Animated progress ring.
                    Circle()
                        .stroke(
                            AppGradients.launchRing,
                            style: StrokeStyle(
                                lineWidth: self.ringLineWidth,
                                lineCap: .round
                            )
                        )
                        .frame(
                            width: self.brandMarkSize,
                            height: self.brandMarkSize
                        )
                        .scaleEffect(self.ringScale)
                        .opacity(self.ringOpacity)

                    // Globe icon.
                    Image(systemName: "globe.europe.africa")
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppColors.onImagePrimary)
                        .opacity(self.iconOpacity)
                }

                VStack(spacing: SpacingTokens.xSmall) {
                    Text("Tourism Beats")
                        .font(TypographyTokens.heroTitle.weight(.bold))
                        .foregroundStyle(AppColors.onImagePrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .opacity(self.titleOpacity)

                    Text("an immersive tourist experience")
                        .font(TypographyTokens.body)
                        .foregroundStyle(AppColors.onImageSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(self.subtitleOpacity)
                }
            }
        }
        .task {
            if self.reduceMotion {
                self.ringScale = 1.0
                self.ringOpacity = 1.0
                self.iconOpacity = 1.0
                self.titleOpacity = 1.0
                self.subtitleOpacity = 1.0
                try? await Task.sleep(for: .milliseconds(400))
                self.onFinished()
                return
            }

            // Staggered entrance.
            withAnimation(.easeOut(duration: 0.3)) {
                self.ringScale = 1.0
                self.ringOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(100))

            withAnimation(.easeOut(duration: 0.25)) {
                self.iconOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(100))

            withAnimation(.easeOut(duration: 0.25)) {
                self.titleOpacity = 1.0
            }

            try? await Task.sleep(for: .milliseconds(80))

            withAnimation(.easeOut(duration: 0.2)) {
                self.subtitleOpacity = 1.0
            }

            // Hold so the brand registers.
            try? await Task.sleep(for: .milliseconds(350))

            self.onFinished()
        }
        .accessibilityHidden(true)
    }
}
