import SwiftUI

// MARK: - WalkabilityView

struct WalkabilityView: View {
    @StateObject var viewModel: WalkabilityViewModel

    var body: some View {
        Group {
            if self.viewModel.isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.white)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if let error = self.viewModel.errorMessage {
                WalkabilityErrorContent(message: error)
            } else if let data = self.viewModel.walkability {
                WalkabilityLoadedContent(
                    data: data,
                    walkColor: self.viewModel.walkScoreColor(data.walkScore),
                    transitColor: self.viewModel.transitScoreColor(
                        data.transitScore
                    )
                )
            } else {
                Text("No walkability data available.")
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - WalkabilityLoadedContent

private struct WalkabilityLoadedContent: View {
    let data: WalkabilityModel
    let walkColor: Color
    let transitColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            // Two side-by-side score tiles
            HStack(spacing: SpacingTokens.small) {
                ScoreTile(
                    icon: "figure.walk",
                    label: "Walking",
                    score: self.data.walkScore,
                    description: self.data.walkDescription,
                    detail: self.data.walkDetail,
                    color: self.walkColor
                )

                ScoreTile(
                    icon: "bus.fill",
                    label: "Transit",
                    score: self.data.transitScore,
                    description: self.data.transitDescription,
                    detail: self.data.transitDetail,
                    color: self.transitColor
                )
            }
        }
    }
}

// MARK: - ScoreTile

private struct ScoreTile: View {
    let icon: String
    let label: String
    let score: Int
    let description: String
    let detail: String
    let color: Color

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
            // Header row
            HStack(spacing: SpacingTokens.xxSmall) {
                Image(systemName: self.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(self.color)

                Text(self.label)
                    .font(TypographyTokens.cardLabel.weight(.semibold))
                    .foregroundStyle(self.color)
            }

            // Large score number
            Text(self.score, format: .number)
                .font(.system(.title, design: .rounded))
                .bold()
                .foregroundStyle(.primary)
                .contentTransition(.numericText())

            // Description
            Text(self.description)
                .font(TypographyTokens.cardLabel.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // Detail text
            Text(self.detail)
                .font(TypographyTokens.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SpacingTokens.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            self.tileBackground,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.scheme),
                    lineWidth: 0.5
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(self.label) score: \(self.score). \(self.description). \(self.detail)"
        )
    }

    private var tileBackground: some ShapeStyle {
        self.reduceTransparency
            ? AnyShapeStyle(AppColors.surfaceSecondary)
            : AnyShapeStyle(.ultraThinMaterial)
    }
}

// MARK: - WalkabilityErrorContent

private struct WalkabilityErrorContent: View {
    let message: String

    var body: some View {
        Label {
            Text(self.message)
                .font(TypographyTokens.caption)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .foregroundStyle(.secondary)
    }
}
