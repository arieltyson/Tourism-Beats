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
        PageDescriptor(id: 2, icon: "shield", label: "Advisories")
    ]
}

// MARK: - VerticalIconPageIndicator

/// Control Center–style vertical icon strip for page navigation.
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
            .snappy(duration: 0.28, extraBounce: 0.04),
            reduced: .easeInOut(duration: 0.18),
            value: self.activeIndex
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("City detail sections")
        .accessibilityValue(self.currentPageLabel)
        .accessibilityHint("Select City, Music, or Advisories")
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
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 6) {
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

    var body: some View {
        VStack(spacing: 6) {
            ForEach(self.pages) { page in
                LegacyIconPageButton(
                    page: page,
                    isActive: self.activeIndex == page.id,
                    action: { self.onSelect(page.id) },
                    selectionNamespace: self.selectionNamespace
                )
            }
        }
    }
}

// MARK: - ModernIconPageButton

/// A single icon button within the page indicator strip.
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
                .font(.footnote.bold())
                .fontWeight(.semibold)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(self.isActive ? AppColors.onImagePrimary : AppColors.onImageSecondary)
                .frame(width: 28, height: 28)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .opacity(self.isActive ? 1 : 0.5)
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

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: self.action) {
            ZStack {
                if self.isActive {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 32, height: 40)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    AppColors.glassBorder(for: self.scheme),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(
                            color: AppColors.glassShadow(for: self.scheme),
                            radius: 6,
                            y: 2
                        )
                        .matchedGeometryEffect(
                            id: "page-indicator-selection",
                            in: self.selectionNamespace
                        )
                }

                Label(self.page.label, systemImage: self.page.icon)
                    .labelStyle(.iconOnly)
                    .font(.footnote.bold())
                    .fontWeight(.semibold)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        self.isActive ? AppColors.onImagePrimary : AppColors.onImageSecondary
                    )
                    .frame(width: 32, height: 40)
                    .contentShape(.rect)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(self.isActive ? 1 : 0.88)
        .opacity(self.isActive ? 1 : 0.5)
        .accessibilityLabel(self.page.label)
        .accessibilityValue(self.isActive ? "Selected" : "Not selected")
        .accessibilityHint("Shows \(self.page.label)")
        .accessibilityAddTraits(self.isActive ? .isSelected : [])
        .accessibilityInputLabels([self.page.label, "Show \(self.page.label)"])
    }
}
