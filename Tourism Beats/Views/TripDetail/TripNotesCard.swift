import SwiftUI

// MARK: - TripNotesCard

struct TripNotesCard: View {
    let notes: String

    var body: some View {
        GlassCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: SpacingTokens.xSmall) {
                Label("Planning Notes", systemImage: "note.text")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .foregroundStyle(.primary)

                Text(self.notes)
                    .font(TypographyTokens.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
