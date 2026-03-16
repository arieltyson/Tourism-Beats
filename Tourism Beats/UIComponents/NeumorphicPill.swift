import SwiftUI

// MARK: - PillRightKind

enum PillRightKind {
    case link, play, pause, loading
}

// MARK: - NeumorphicPill

struct NeumorphicPill: View {
    let logo: ProviderLogo
    let title: String
    let rightKind: PillRightKind
    let dimmed: Bool
    let action: () -> Void

    private let height: CGFloat = 56
    private let corner: CGFloat = 18

    // MARK: - Adaptive Colors

    private var adaptiveAccent: Color {
        Color.primary.opacity(0.8)
    }

    private var adaptiveGray: Color {
        Color.secondary.opacity(0.6)
    }

    init(
        logo: ProviderLogo,
        title: String,
        rightKind: PillRightKind,
        dimmed: Bool = false,
        action: @escaping () -> Void
    ) {
        self.logo = logo
        self.title = title
        self.rightKind = rightKind
        self.dimmed = dimmed
        self.action = action
    }

    var body: some View {
        Button(action: self.action) {
            HStack(spacing: 12) {
                self.logo.view
                    .frame(width: 22, height: 22)
                    .opacity(self.dimmed ? 0.45 : 1.0)
                    .foregroundStyle(self.adaptiveAccent)

                Text(self.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .opacity(self.dimmed ? 0.6 : 1.0)

                Spacer(minLength: 8)

                self.rightIcon
                    .frame(width: 20, height: 20)
                    .foregroundStyle(self.dimmed ? self.adaptiveGray : self.adaptiveAccent)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity, minHeight: self.height)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(self.title))
            .accessibilityHint(Text(self.accessibilityHint))
            .opacity(self.dimmed ? 0.9 : 1.0)
            // Ensure the whole rounded shape is tappable
            .contentShape(
                RoundedRectangle(cornerRadius: self.corner, style: .continuous)
            )
        }
        .buttonStyle(NeumorphicButtonStyle(cornerRadius: self.corner))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var rightIcon: some View {
        switch self.rightKind {
        case .link:
            Image(systemName: "arrow.up.right.square")
                .symbolRenderingMode(.hierarchical)
        case .play:
            Image(systemName: "play.fill")
        case .pause:
            Image(systemName: "pause.fill")
        case .loading:
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(
                    CircularProgressViewStyle(tint: self.adaptiveAccent)
                )
        }
    }

    private var accessibilityHint: String {
        switch self.rightKind {
        case .link: "Opens in Spotify"
        case .play: "Plays the song with Apple Music"
        case .pause: "Pauses playback"
        case .loading: "Searching for song"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        NeumorphicPill(
            logo: .appleMusic,
            title: "Apple Music",
            rightKind: .play
        ) {}
        NeumorphicPill(logo: .spotify, title: "Spotify", rightKind: .link) {}
        NeumorphicPill(
            logo: .spotify,
            title: "Searching...",
            rightKind: .loading
        ) {}
        NeumorphicPill(
            logo: .appleMusic,
            title: "Disabled Option",
            rightKind: .pause,
            dimmed: true
        ) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        NeumorphicPill(
            logo: .appleMusic,
            title: "Apple Music",
            rightKind: .play
        ) {}
        NeumorphicPill(logo: .spotify, title: "Spotify", rightKind: .link) {}
        NeumorphicPill(
            logo: .spotify,
            title: "Searching...",
            rightKind: .loading
        ) {}
        NeumorphicPill(
            logo: .appleMusic,
            title: "Disabled Option",
            rightKind: .pause,
            dimmed: true
        ) {}
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
