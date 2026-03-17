import SwiftUI

// MARK: - TourismFloatingSettingsButton

struct TourismFloatingSettingsButton: View {
    let isSelected: Bool
    let diameter: CGFloat
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            withAnimation(self.reduceMotion ? .none : AnimationTokens.snappy) {
                self.action()
            }
        } label: {
            Label("Settings", systemImage: AppTab.settings.systemImage)
                .labelStyle(.iconOnly)
                .font(.title3)
                .foregroundStyle(
                    self.isSelected
                        ? AppColors.onImagePrimary
                        : AppColors.label
                )
                .frame(width: self.diameter, height: self.diameter)
                .background(
                    Circle()
                        .fill(self.buttonBackgroundFill)
                )
                .overlay {
                    Circle()
                        .strokeBorder(
                            AppColors.glassBorder(for: self.colorScheme),
                            lineWidth: 0.75
                        )
                }
                .shadow(
                    color: AppColors.glassShadow(for: self.colorScheme),
                    radius: 18,
                    y: 10
                )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Settings")
        .accessibilityValue(self.isSelected ? "Selected" : "")
        .accessibilityHint("Opens settings and feedback")
        .accessibilityInputLabels(["Settings", "Open Settings"])
    }

    private var buttonBackgroundFill: AnyShapeStyle {
        if self.isSelected {
            return AnyShapeStyle(AppGradients.hero(for: self.colorScheme))
        }

        return self.reduceTransparency
            ? AnyShapeStyle(AppColors.surfaceSecondary.opacity(0.98))
            : AnyShapeStyle(.ultraThinMaterial)
    }
}
