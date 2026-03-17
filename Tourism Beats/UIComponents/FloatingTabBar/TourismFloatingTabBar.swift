import SwiftUI

// MARK: - TourismFloatingTabBar

struct TourismFloatingTabBar: View {
    @Binding var selectedTab: AppTab

    @Namespace private var selectionNamespace
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @ScaledMetric(relativeTo: .body) private var itemHeight = 56

    var body: some View {
        GlassEffectContainer(spacing: SpacingTokens.small) {
            HStack(alignment: .bottom, spacing: SpacingTokens.small) {
                self.primaryTabGroup

                TourismFloatingSettingsButton(
                    isSelected: self.selectedTab == .settings,
                    diameter: self.primaryGroupHeight,
                    action: {
                        self.selectedTab = .settings
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, SpacingTokens.medium)
            .padding(.top, SpacingTokens.xSmall)
            .padding(.bottom, SpacingTokens.small)
        }
    }

    @ViewBuilder
    private var primaryTabGroup: some View {
        let content = HStack(spacing: SpacingTokens.xSmall) {
            ForEach(AppTab.primaryTabs, id: \.self) { tab in
                TourismFloatingTabBarItem(
                    tab: tab,
                    isSelected: self.selectedTab == tab,
                    selectionNamespace: self.selectionNamespace,
                    itemHeight: self.itemHeight,
                    action: {
                        self.selectedTab = tab
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SpacingTokens.xSmall)
        .frame(height: self.primaryGroupHeight)

        if self.reduceTransparency {
            content
                .background(AppColors.surfaceSecondary.opacity(0.98), in: Capsule())
                .overlay {
                    Capsule()
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
        } else {
            content
                .glassEffect(in: Capsule())
        }
    }

    private var primaryGroupHeight: CGFloat {
        self.itemHeight
            + (SpacingTokens.xxSmall * 2)
            + (SpacingTokens.xSmall * 2)
    }
}
