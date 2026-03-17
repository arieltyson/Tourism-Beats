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
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 16, style: .continuous)
        )
    }
}

// MARK: - AccessibilityTimeCard

private struct AccessibilityTimeCard: View {
    let formattedTime: String

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
            Text("Local Time")
                .font(TypographyTokens.footnote)
                .foregroundStyle(.white.opacity(0.78))

            Text(self.formattedTime)
                .font(TypographyTokens.heroTitle.monospacedDigit())
                .bold()
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SpacingTokens.small)
        .background(
            .ultraThinMaterial,
            in: .rect(cornerRadius: 16, style: .continuous)
        )
    }
}
