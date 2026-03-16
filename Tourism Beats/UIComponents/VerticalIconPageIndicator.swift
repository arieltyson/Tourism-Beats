import SwiftUI

// MARK: - PageDescriptor

/// Describes a page in the vertical pager with its icon and label.
struct PageDescriptor: Identifiable {
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

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 4) {
            ForEach(self.pages) { page in
                IconPageButton(
                    page: page,
                    isActive: self.activeIndex == page.id,
                    action: { self.onSelect(page.id) }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            AppColors.glassBorder(for: self.scheme),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: AppColors.glassShadow(for: self.scheme),
            radius: 8,
            y: 4
        )
        .animation(.easeInOut(duration: 0.2), value: self.activeIndex)
    }
}

// MARK: - IconPageButton

/// A single icon button within the page indicator strip.
private struct IconPageButton: View {
    let page: PageDescriptor
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(self.page.label, systemImage: self.page.icon, action: self.action)
            .labelStyle(.iconOnly)
            .font(.system(size: 16, weight: self.isActive ? .semibold : .regular))
            .foregroundStyle(self.isActive ? .white : .white.opacity(0.45))
            .scaleEffect(self.isActive ? 1.0 : 0.8)
            .frame(width: 44, height: 44)
            .background {
                if self.isActive {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .transition(.opacity)
                }
            }
            .contentShape(.circle)
            .accessibilityLabel(self.page.label)
            .accessibilityAddTraits(self.isActive ? .isSelected : [])
    }
}
