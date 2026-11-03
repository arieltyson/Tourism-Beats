import SwiftUI

// MARK: - SettingsActionRow

struct SettingsActionRow: View {
    let title: String
    let systemImage: String
    let tint: Color
    var accessorySystemImage: String?
    var accessibilityHint: String?
    var accessibilityInputLabels: [String] = []
    let action: () -> Void

    init(
        title: String,
        systemImage: String,
        tint: Color,
        accessorySystemImage: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityInputLabels: [String] = [],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.accessorySystemImage = accessorySystemImage
        self.accessibilityHint = accessibilityHint
        self.accessibilityInputLabels = accessibilityInputLabels
        self.action = action
    }

    var body: some View {
        Button(action: self.action) {
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
