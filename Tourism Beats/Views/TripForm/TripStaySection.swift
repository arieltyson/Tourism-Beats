import SwiftUI

// MARK: - TripStaySection

/// The trip's optional hotel, which suggestions start near.
struct TripStaySection: View {
    let stay: TripStay?
    let cityName: String
    let onChoose: () -> Void
    let onRemove: () -> Void

    var body: some View {
        Section {
            HStack(spacing: SpacingTokens.small) {
                Button(action: self.onChoose) {
                    TripStayFieldLabel(stay: self.stay)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .accessibilityLabel(self.stay.map { "Hotel, \($0.name)" } ?? "Hotel, optional")
                .accessibilityHint("Searches hotels in \(self.cityName)")

                if self.stay != nil {
                    Button("Remove Hotel", systemImage: "xmark.circle.fill", action: self.onRemove)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.tertiary)
                }
            }
            // Each button keeps its own tap target inside the row.
            .buttonStyle(.borderless)
        } footer: {
            Text("Suggestions start near your hotel, or span the city without one.")
        }
    }
}
