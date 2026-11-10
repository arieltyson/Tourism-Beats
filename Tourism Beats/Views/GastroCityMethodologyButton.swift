import SwiftUI

// MARK: - GastroCityMethodologyButton

/// Tells how the gastro cities were ranked, out of the way until asked.
struct GastroCityMethodologyButton: View {
    @State private var isPresented = false

    var body: some View {
        Button("How Cities Are Ranked", systemImage: "info.circle") {
            self.isPresented = true
        }
        .labelStyle(.iconOnly)
        .font(TypographyTokens.body)
        .foregroundStyle(.secondary)
        .frame(minWidth: SpacingTokens.minimumTapTarget, minHeight: SpacingTokens.minimumTapTarget)
        .contentShape(.rect)
        .popover(isPresented: self.$isPresented) {
            Text(GastroCityRanking.methodology)
                .font(TypographyTokens.cardLabel)
                .fixedSize(horizontal: false, vertical: true)
                .padding(SpacingTokens.medium)
                .frame(idealWidth: FoodJournalTokens.gastroCardMinimumWidth)
                .presentationCompactAdaptation(.popover)
        }
    }
}
