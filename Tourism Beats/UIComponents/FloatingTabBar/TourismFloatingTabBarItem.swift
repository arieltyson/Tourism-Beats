import SwiftUI

// MARK: - TourismFloatingTabBarItem

struct TourismFloatingTabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let selectionNamespace: Namespace.ID
    let itemHeight: CGFloat
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            withAnimation(self.reduceMotion ? .none : AnimationTokens.snappy) {
                self.action()
            }
        } label: {
            ZStack {
                if self.isSelected {
                    Capsule()
                        .fill(AppColors.surfaceSecondary.opacity(0.92))
                        .matchedGeometryEffect(
                            id: "tourism-floating-primary-selection",
                            in: self.selectionNamespace
                        )
                }

                ViewThatFits {
                    self.labeledContent
                    self.iconOnlyContent
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: self.itemHeight, maxHeight: self.itemHeight)
                .padding(.horizontal, SpacingTokens.small)
                .padding(.vertical, SpacingTokens.xxSmall)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.tab.title)
        .accessibilityValue(self.isSelected ? "Selected" : "")
        .accessibilityHint("Switches to the \(self.tab.title) tab")
        .accessibilityInputLabels([self.tab.title, "Open \(self.tab.title)"])
    }

    private var labeledContent: some View {
        VStack(spacing: self.dynamicTypeSize.isAccessibilitySize ? 2 : 4) {
            Image(systemName: self.tab.systemImage)
                .font(.body)

            Text(self.tab.title)
                .font(TypographyTokens.footnote)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundStyle(self.isSelected ? AppColors.label : AppColors.secondaryLabel)
    }

    private var iconOnlyContent: some View {
        Image(systemName: self.tab.systemImage)
            .font(.title3)
            .foregroundStyle(self.isSelected ? AppColors.label : AppColors.secondaryLabel)
            .frame(maxWidth: .infinity, minHeight: self.itemHeight, maxHeight: self.itemHeight)
    }
}
