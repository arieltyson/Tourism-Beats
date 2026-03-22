import SwiftUI

// MARK: - PageDescriptor

/// Describes a page in the vertical pager with its icon and label.
struct PageDescriptor: Identifiable, Hashable, Sendable {
    let id: Int
    let icon: String
    let label: String

    /// Default pages for the city detail pager.
    static let defaults: [PageDescriptor] = [
        PageDescriptor(id: 0, icon: "map", label: "City"),
        PageDescriptor(id: 1, icon: "music.note", label: "Music"),
        PageDescriptor(id: 2, icon: "shield", label: "Advisories"),
        PageDescriptor(id: 3, icon: "figure.walk", label: "Activities"),
        PageDescriptor(id: 4, icon: "fork.knife", label: "Restaurants")
    ]
}

// MARK: - VerticalIconPageIndicator

/// Control Center–style vertical icon strip for page navigation.
///
/// Each icon meets the 44pt minimum tap target per Apple HIG.
/// The active page is highlighted with an animated circle indicator
/// using `matchedGeometryEffect` for smooth transitions.
struct VerticalIconPageIndicator: View {
    let activeIndex: Int
    var pages: [PageDescriptor] = PageDescriptor.defaults
    let onSelect: (Int) -> Void

    @Namespace private var selectionNamespace

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                ModernVerticalIconPageIndicator(
                    activeIndex: self.activeIndex,
                    pages: self.pages,
                    onSelect: self.onSelect,
                    selectionNamespace: self.selectionNamespace
                )
            } else {
                LegacyVerticalIconPageIndicator(
                    activeIndex: self.activeIndex,
                    pages: self.pages,
                    onSelect: self.onSelect,
                    selectionNamespace: self.selectionNamespace
                )
            }
        }
        .motionSensitiveAnimation(
            AnimationTokens.snappy,
            reduced: .easeInOut(duration: AnimationTokens.reducedMotionDuration),
            value: self.activeIndex
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("City detail sections")
        .accessibilityValue(self.currentPageLabel)
        .accessibilityHint(self.accessibilityHint)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                self.selectPage(min(self.activeIndex + 1, self.pages.count - 1))
            case .decrement:
                self.selectPage(max(self.activeIndex - 1, 0))
            @unknown default:
                break
            }
        }
    }

    private var currentPageLabel: String {
        self.pages.first(where: { $0.id == self.activeIndex })?.label ?? "Unknown"
    }

    private var accessibilityHint: String {
        "Select \(self.pages.map(\.label).joined(separator: ", "))"
    }

    private func selectPage(_ index: Int) {
        guard index != self.activeIndex else { return }
        self.onSelect(index)
    }
}

// MARK: - ModernVerticalIconPageIndicator

@available(iOS 26.0, *)
private struct ModernVerticalIconPageIndicator: View {
    let activeIndex: Int
    let pages: [PageDescriptor]
    let onSelect: (Int) -> Void
    let selectionNamespace: Namespace.ID

    var body: some View {
        GlassEffectContainer(spacing: PageIndicatorTokens.containerSpacing) {
            VStack(spacing: PageIndicatorTokens.buttonSpacing) {
                ForEach(self.pages) { page in
                    ModernIconPageButton(
                        page: page,
                        isActive: self.activeIndex == page.id,
                        action: { self.onSelect(page.id) },
                        selectionNamespace: self.selectionNamespace
                    )
                }
            }
        }
    }
}

// MARK: - LegacyVerticalIconPageIndicator

private struct LegacyVerticalIconPageIndicator: View {
    let activeIndex: Int
    let pages: [PageDescriptor]
    let onSelect: (Int) -> Void
    let selectionNamespace: Namespace.ID

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: PageIndicatorTokens.buttonSpacing) {
            ForEach(self.pages) { page in
                LegacyIconPageButton(
                    page: page,
                    isActive: self.activeIndex == page.id,
                    action: { self.onSelect(page.id) },
                    selectionNamespace: self.selectionNamespace
                )
            }
        }
        .padding(.vertical, PageIndicatorTokens.containerSpacing)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            AppColors.glassBorder(for: self.scheme),
                            lineWidth: PageIndicatorTokens.legacyBorderWidth
                        )
                )
                .shadow(
                    color: AppColors.glassShadow(for: self.scheme),
                    radius: PageIndicatorTokens.legacyShadowRadius,
                    y: PageIndicatorTokens.legacyShadowY
                )
        }
    }
}

// MARK: - ModernIconPageButton

/// A single icon button within the page indicator strip.
///
/// Uses a `matchedGeometryEffect` circle highlight to smoothly
/// animate between active pages, inspired by Control Center.
@available(iOS 26.0, *)
private struct ModernIconPageButton: View {
    let page: PageDescriptor
    let isActive: Bool
    let action: () -> Void
    let selectionNamespace: Namespace.ID

    var body: some View {
        Button(action: self.action) {
            Label(self.page.label, systemImage: self.page.icon)
                .labelStyle(.iconOnly)
                .font(.system(size: 13, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    self.isActive ? AppColors.onImagePrimary : AppColors.onImageSecondary
                )
                .frame(
                    width: PageIndicatorTokens.modernButtonWidth,
                    height: PageIndicatorTokens.modernButtonHeight
                )
                .contentShape(.rect)
                .background {
                    if self.isActive {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(
                                width: PageIndicatorTokens.modernHighlightSize,
                                height: PageIndicatorTokens.modernHighlightSize
                            )
                            .matchedGeometryEffect(
                                id: "page-indicator-highlight",
                                in: self.selectionNamespace
                            )
                    }
                }
        }
        .buttonStyle(.plain)
        .opacity(
            self.isActive
                ? PageIndicatorTokens.activeOpacity
                : PageIndicatorTokens.inactiveOpacity
        )
        .accessibilityLabel(self.page.label)
        .accessibilityValue(self.isActive ? "Selected" : "Not selected")
        .accessibilityHint("Shows \(self.page.label)")
        .accessibilityAddTraits(self.isActive ? .isSelected : [])
        .accessibilityInputLabels([self.page.label, "Show \(self.page.label)"])
    }
}

// MARK: - LegacyIconPageButton

private struct LegacyIconPageButton: View {
    let page: PageDescriptor
    let isActive: Bool
    let action: () -> Void
    let selectionNamespace: Namespace.ID

    var body: some View {
        Button(action: self.action) {
            Label(self.page.label, systemImage: self.page.icon)
                .labelStyle(.iconOnly)
                .font(.system(size: 13, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(
                    self.isActive ? AppColors.onImagePrimary : AppColors.onImageSecondary
                )
                .frame(
                    width: PageIndicatorTokens.legacyCapsuleWidth,
                    height: PageIndicatorTokens.legacyCapsuleHeight
                )
                .contentShape(.rect)
                .background {
                    if self.isActive {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(
                                width: PageIndicatorTokens.modernHighlightSize,
                                height: PageIndicatorTokens.modernHighlightSize
                            )
                            .matchedGeometryEffect(
                                id: "page-indicator-highlight",
                                in: self.selectionNamespace
                            )
                    }
                }
        }
        .buttonStyle(.plain)
        .scaleEffect(
            self.isActive ? 1 : PageIndicatorTokens.inactiveScale
        )
        .opacity(
            self.isActive
                ? PageIndicatorTokens.activeOpacity
                : PageIndicatorTokens.inactiveOpacity
        )
        .accessibilityLabel(self.page.label)
        .accessibilityValue(self.isActive ? "Selected" : "Not selected")
        .accessibilityHint("Shows \(self.page.label)")
        .accessibilityAddTraits(self.isActive ? .isSelected : [])
        .accessibilityInputLabels([self.page.label, "Show \(self.page.label)"])
    }
}
