import SwiftUI

// MARK: - RestaurantFormRatingSection

/// An optional score out of ten.
struct RestaurantFormRatingSection: View {
    @Binding var hasScore: Bool
    @Binding var scoreValue: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Section("Rating") {
            Toggle(
                "Rate this restaurant",
                isOn: self.$hasScore.animation(
                    self.reduceMotion ? .none : AnimationTokens.standard
                )
            )
            .tint(AppColors.coral)

            if self.hasScore {
                VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                    HStack {
                        Text("Score")
                            .font(TypographyTokens.body)

                        Spacer()

                        Text("\(self.scoreValue, format: .number)/10")
                            .font(TypographyTokens.songTitle.monospacedDigit())
                            .bold()
                            .foregroundStyle(AppColors.gold)
                    }

                    HStack(spacing: SpacingTokens.xxSmall) {
                        ForEach(1 ... 10, id: \.self) { index in
                            Button {
                                withAnimation(
                                    self.reduceMotion ? .none : AnimationTokens.press
                                ) {
                                    self.scoreValue = index
                                }
                            } label: {
                                Circle()
                                    .fill(
                                        index <= self.scoreValue
                                            ? AnyShapeStyle(AppColors.gold)
                                            : AnyShapeStyle(.quaternary)
                                    )
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(index, format: .number)")
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Score: \(self.scoreValue) out of 10")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment:
                            self.scoreValue = min(self.scoreValue + 1, 10)
                        case .decrement:
                            self.scoreValue = max(self.scoreValue - 1, 0)
                        @unknown default:
                            break
                        }
                    }
                }
            }
        }
    }
}
