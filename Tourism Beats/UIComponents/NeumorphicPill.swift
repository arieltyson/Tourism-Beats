import SwiftUI

// MARK: - Provider Logo

enum ProviderLogo {
    case spotify, appleMusic

    @ViewBuilder
    var view: some View {
        switch self {
        case .spotify:
            if let ui = UIImage(named: "spotify_logo") {
                Image(uiImage: ui).resizable().scaledToFit()
            } else {
                Image(systemName: "link").resizable().scaledToFit()
            }
        case .appleMusic:
            if let ui = UIImage(named: "apple_music_logo") {
                Image(uiImage: ui).resizable().scaledToFit()
            } else {
                Image(systemName: "apple.logo").resizable().scaledToFit()
            }
        }
    }
}

// MARK: - Pill Right Kind

enum PillRightKind {
    case link, play, pause, loading
}

// MARK: - Neumorphic Pill (tappable)

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
        Button(action: action) {
            HStack(spacing: 12) {
                logo.view
                    .frame(width: 22, height: 22)
                    .opacity(dimmed ? 0.45 : 1.0)
                    .foregroundStyle(adaptiveAccent)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .opacity(dimmed ? 0.6 : 1.0)

                Spacer(minLength: 8)

                rightIcon
                    .frame(width: 20, height: 20)
                    .foregroundStyle(dimmed ? adaptiveGray : adaptiveAccent)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(title))
            .accessibilityHint(Text(accessibilityHint))
            .opacity(dimmed ? 0.9 : 1.0)
            // Ensure the whole rounded shape is tappable
            .contentShape(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
            )
        }
        .buttonStyle(NeumorphicButtonStyle(cornerRadius: corner))
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var rightIcon: some View {
        switch rightKind {
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
                    CircularProgressViewStyle(tint: adaptiveAccent)
                )
        }
    }

    private var accessibilityHint: String {
        switch rightKind {
        case .link: return "Opens in Spotify"
        case .play: return "Plays the song with Apple Music"
        case .pause: return "Pauses playback"
        case .loading: return "Searching for song"
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
