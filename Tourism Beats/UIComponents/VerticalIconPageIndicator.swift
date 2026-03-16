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
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 10) {
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
        VStack(spacing: 10) {
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
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(self.isActive ? .white : .white.opacity(0.5))
                .frame(width: 44, height: 44)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .scaleEffect(self.isActive ? 1.15 : 0.92)
        .opacity(self.isActive ? 1 : 0.7)
        .accessibilityLabel(self.page.label)
        .accessibilityValue(self.isActive ? "Selected" : "Not selected")
        .accessibilityHint("Shows \(self.page.label)")
        .accessibilityAddTraits(self.isActive ? .isSelected : [])
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
                        .frame(width: 54, height: 64)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(
                                    AppColors.glassBorder(for: self.scheme),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: AppColors.glassShadow(for: self.scheme),
                            radius: 10,
                            y: 4
                        )
                        .matchedGeometryEffect(
                            id: "page-indicator-selection",
                            in: self.selectionNamespace
                        )
                }

                Label(self.page.label, systemImage: self.page.icon)
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(self.isActive ? .white : .white.opacity(0.72))
                    .frame(width: 54, height: 64)
                    .contentShape(.capsule)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(self.isActive ? 1 : 0.92)
        .accessibilityLabel(self.page.label)
        .accessibilityValue(self.isActive ? "Selected" : "Not selected")
        .accessibilityHint("Shows \(self.page.label)")
        .accessibilityAddTraits(self.isActive ? .isSelected : [])
    }
}
