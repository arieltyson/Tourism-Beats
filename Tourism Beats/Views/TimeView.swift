import SwiftUI

// MARK: - TimeView

struct TimeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: TimeViewModel
    /// The second hand moves only while the clock can be seen.
    @State private var isOnScreen = true

    init(city: CityModel) {
        _viewModel = State(initialValue: TimeViewModel(timeZone: city.timeZone))
    }

    var body: some View {
        TimelineView(OnScreenTicks(isPaused: !self.isOnScreen || self.scenePhase != .active)) { context in
            let formattedTime = self.viewModel.formattedTime(for: context.date)

            Group {
                if self.dynamicTypeSize.isAccessibilitySize {
                    AccessibilityTimeCard(formattedTime: formattedTime)
                } else {
                    StandardTimeCard(
                        formattedTime: formattedTime,
                        date: context.date,
                        timeZone: self.viewModel.timeZone
                    )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Local time")
            .accessibilityValue(formattedTime)
        }
        .onScrollVisibilityChange { isVisible in
            self.isOnScreen = isVisible
        }
    }
}

// MARK: - StandardTimeCard

private struct StandardTimeCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let formattedTime: String
    let date: Date
    let timeZone: TimeZone

    var body: some View {
        VStack(spacing: SpacingTokens.xSmall) {
            ClockView(
                date: self.date,
                timeZone: self.timeZone
            )
            .frame(maxWidth: ClockFaceTokens.cardMaximumSide, maxHeight: ClockFaceTokens.cardMaximumSide)
            .padding([.horizontal, .top], SpacingTokens.small)

            Text(self.formattedTime)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.label)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, SpacingTokens.xSmall)
                .padding(.bottom, SpacingTokens.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    self.reduceTransparency
                        ? AnyShapeStyle(AppColors.surfaceSecondary)
                        : AnyShapeStyle(.ultraThinMaterial)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(self.reduceTransparency ? 0.06 : 0.10),
                                    AppColors.info.opacity(self.reduceTransparency ? 0.06 : 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                // Cast by the glass, not the whole card: the card redraws every
                // second, and a whole-card shadow redrew an offscreen copy with it.
                .shadow(
                    color: AppColors.glassShadow(for: self.scheme),
                    radius: 12,
                    y: 6
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.scheme),
                    lineWidth: 0.8
                )
        }
    }
}

// MARK: - AccessibilityTimeCard

private struct AccessibilityTimeCard: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let formattedTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text("Local Time")
                .font(TypographyTokens.footnote)
                .foregroundStyle(AppColors.secondaryLabel)

            Text(self.formattedTime)
                .font(TypographyTokens.heroTitle.monospacedDigit())
                .bold()
                .foregroundStyle(AppColors.label)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SpacingTokens.small)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    self.reduceTransparency
                        ? AnyShapeStyle(AppColors.surfaceSecondary)
                        : AnyShapeStyle(.ultraThinMaterial)
                )
                .shadow(
                    color: AppColors.glassShadow(for: self.scheme),
                    radius: 12,
                    y: 6
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.scheme),
                    lineWidth: 0.8
                )
        }
    }
}
