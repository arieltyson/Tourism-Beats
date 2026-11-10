import SwiftUI

// MARK: - WorldCuisineRankingSection

/// The world's five best-rated cuisines, chosen from the journal's filters
/// to whet the appetite.
struct WorldCuisineRankingSection: View {
    let cuisines: [WorldCuisine]
    let source: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var hasAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.small) {
            VStack(alignment: .leading, spacing: SpacingTokens.xxSmall) {
                Text("World’s Best Cuisines")
                    .font(TypographyTokens.sectionHeader)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                Text(self.source)
                    .font(TypographyTokens.caption)
                    .foregroundStyle(.secondary)
            }

            if let leader = self.cuisines.first {
                WorldCuisineCard(cuisine: leader, isLeading: true)
                    .staggeredReveal(index: 0, isRevealed: self.hasAppeared)
            }

            LazyVGrid(columns: self.columns, spacing: SpacingTokens.small) {
                ForEach(self.cuisines.dropFirst().enumerated(), id: \.element.id) { offset, cuisine in
                    WorldCuisineCard(cuisine: cuisine)
                        .staggeredReveal(index: offset + 1, isRevealed: self.hasAppeared)
                }
            }
        }
        .onAppear { self.hasAppeared = true }
    }

    /// One column at accessibility sizes, so names and dishes have room.
    private var columns: [GridItem] {
        let count = self.dynamicTypeSize.isAccessibilitySize ? 1 : FoodJournalTokens.cuisineColumns
        return Array(repeating: GridItem(.flexible(), spacing: SpacingTokens.small), count: count)
    }
}
