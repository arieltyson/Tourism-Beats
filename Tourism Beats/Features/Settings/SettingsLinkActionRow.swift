import SwiftUI

// MARK: - SettingsLinkActionRow

struct SettingsLinkActionRow: View {
    let title: String
    let systemImage: String
    let tint: Color
    let destination: URL
    var accessorySystemImage: String?
    var accessibilityHint: String?
    var accessibilityInputLabels: [String] = []

    var body: some View {
        Link(destination: self.destination) {
            SettingsRowContent(
                title: self.title,
                systemImage: self.systemImage,
                tint: self.tint,
                accessorySystemImage: self.accessorySystemImage
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint(self.accessibilityHint ?? "")
        .accessibilityInputLabels(self.accessibilityInputLabels)
    }
}
