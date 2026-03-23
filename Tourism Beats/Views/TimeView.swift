import SwiftUI

// MARK: - TimeView

struct TimeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var viewModel: TimeViewModel

    init(city: CityModel) {
        _viewModel = StateObject(
            wrappedValue: TimeViewModel(timeZone: city.timeZone)
        )
    }

    var body: some View {
        TimelineView(.periodic(from: Date.now, by: 1)) { context in
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
        VStack(spacing: 8) {
            ClockView(
                date: self.date,
                timeZone: self.timeZone
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 120, maxHeight: 120)
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Text(self.formattedTime)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.label)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
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
        }
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.scheme),
                    lineWidth: 0.8
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.scheme),
            radius: 12,
            y: 6
        )
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
        }
        .clipShape(.rect(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    AppColors.glassBorder(for: self.scheme),
                    lineWidth: 0.8
                )
        }
        .shadow(
            color: AppColors.glassShadow(for: self.scheme),
            radius: 12,
            y: 6
        )
    }
}
